import 'dart:math' as math;

import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/services/local_db_service.dart';
import '../models/cart_item_model.dart';
import '../models/held_order_draft_model.dart';
import '../models/local_order_item_model.dart';
import '../models/local_order_model.dart';
import '../models/shift_summary_model.dart';

class InsufficientLocalStockException implements Exception {
  const InsufficientLocalStockException(this.productName);

  final String productName;

  @override
  String toString() => 'Not enough local stock for $productName.';
}

class LocalOrderRepository {
  LocalOrderRepository({
    required LocalDbService localDb,
    Uuid? uuid,
    Logger? logger,
  }) : _localDb = localDb,
       _uuid = uuid ?? const Uuid(),
       _logger = logger ?? Logger();

  final LocalDbService _localDb;
  final Uuid _uuid;
  final Logger _logger;

  Future<LocalOrderModel> createCompletedOrder({
    required String counterId,
    required String bartenderId,
    required String paymentType,
    required List<CartItemModel> items,
    String? notes,
  }) async {
    try {
      if (items.isEmpty) throw ArgumentError('Cannot save an empty order.');
      final orderId = _uuid.v4();
      final createdAt = DateTime.now().toUtc().toIso8601String();
      final totalAmount = items.fold<double>(
        0,
        (total, item) => total + item.subtotal,
      );
      final itemCount = items.fold<int>(0, (total, item) => total + item.units);
      final order = LocalOrderModel(
        localOrderId: orderId,
        counterId: counterId,
        bartenderId: bartenderId,
        paymentType: paymentType,
        status: 'COMPLETED',
        totalAmount: (totalAmount * 100).roundToDouble() / 100,
        notes: notes,
        totalItemsCount: itemCount,
        syncStatus: 'PENDING',
        createdAt: createdAt,
      );
      final db = await _localDb.database;

      await db.transaction((transaction) async {
        await transaction.insert('local_orders', order.toMap());
        for (final item in items) {
          await _saveItemAcrossStockBatches(
            transaction: transaction,
            orderId: orderId,
            counterId: counterId,
            item: item,
          );
        }
      });
      return order;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to persist completed order locally',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<LocalOrderModel> createHeldOrder({
    required String counterId,
    required String bartenderId,
    required List<CartItemModel> items,
    String? notes,
  }) async {
    try {
      if (items.isEmpty) throw ArgumentError('Cannot hold an empty order.');
      final subtotal = items.fold<double>(
        0,
        (total, item) => total + item.subtotal,
      );
      final order = LocalOrderModel(
        localOrderId: _uuid.v4(),
        counterId: counterId,
        bartenderId: bartenderId,
        paymentType: 'CASH',
        status: 'HELD',
        totalAmount: (subtotal * 100).roundToDouble() / 100,
        notes: notes,
        totalItemsCount: items.fold<int>(
          0,
          (total, item) => total + item.units,
        ),
        syncStatus: 'PENDING',
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      final db = await _localDb.database;
      await db.transaction((transaction) async {
        await transaction.insert('local_orders', order.toMap());
        for (final item in items) {
          await _saveItemAcrossStockBatches(
            transaction: transaction,
            orderId: order.localOrderId,
            counterId: counterId,
            item: item,
          );
        }
      });
      return order;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to hold order in local database',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _saveItemAcrossStockBatches({
    required Transaction transaction,
    required String orderId,
    required String counterId,
    required CartItemModel item,
  }) async {
    final batches = await transaction.rawQuery(
      '''
      SELECT id AS counter_stock_id, stock_item_id,
             MAX(quantity * units_per_quantity - units_sold, 0) AS available
      FROM local_v_counter_stock
      WHERE counter_id = ? AND inventory_id = ?
      ORDER BY available DESC
      ''',
      [counterId, item.inventoryId],
    );
    final available = batches.fold<double>(
      0,
      (total, batch) => total + (batch['available'] as num).toDouble(),
    );
    if (available < item.units) {
      throw InsufficientLocalStockException(item.inventoryName);
    }

    var remainingUnits = item.units;
    for (final batch in batches) {
      if (remainingUnits == 0) break;
      final stockAvailable = (batch['available'] as num).toDouble();
      final unitsToTake = math.min(remainingUnits, stockAvailable.floor());
      if (unitsToTake <= 0) continue;
      final unitPrice = item.unitPrice;
      final line = LocalOrderItemModel(
        localItemId: _uuid.v4(),
        localOrderId: orderId,
        inventoryId: item.inventoryId,
        stockItemId: batch['stock_item_id'] as String,
        listingId: item.listingId,
        inventoryName: item.inventoryName,
        unitPrice: unitPrice,
        units: unitsToTake,
        subtotal: (unitPrice * unitsToTake * 100).roundToDouble() / 100,
      );
      await transaction.insert('local_order_items', line.toMap());
      remainingUnits -= unitsToTake;
    }
    if (remainingUnits > 0) {
      throw InsufficientLocalStockException(item.inventoryName);
    }
  }

  Future<List<LocalOrderModel>> getHeldOrders() async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_orders',
        where: 'status = ?',
        whereArgs: ['HELD'],
        orderBy: 'created_at DESC',
      );
      return rows.map(LocalOrderModel.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load held local orders',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<HeldOrderDraftModel?> resumeHeldOrder(String orderId) async {
    try {
      final db = await _localDb.database;
      return await db.transaction((transaction) async {
        final orderRows = await transaction.query(
          'local_orders',
          where: 'local_order_id = ? AND status = ?',
          whereArgs: [orderId, 'HELD'],
          limit: 1,
        );
        if (orderRows.isEmpty) return null;
        final order = LocalOrderModel.fromMap(orderRows.single);
        final itemRows = await transaction.rawQuery(
          '''
             SELECT oi.listing_id, oi.inventory_name, oi.unit_price,
               oi.units, oi.inventory_id
          FROM local_order_items AS oi
          WHERE oi.local_order_id = ?
          ''',
          [orderId],
        );
        final stockRows = await transaction.rawQuery(
          '''
          SELECT inventory_id,
                 SUM(MAX(
                   quantity * units_per_quantity - units_sold,
                   0
                 ))
                   AS available_units
          FROM local_v_counter_stock
          WHERE counter_id = ?
          GROUP BY inventory_id
          ''',
          [order.counterId],
        );
        final stockByProduct = {
          for (final row in stockRows)
            row['inventory_id']! as String: (row['available_units']! as num)
                .toDouble(),
        };
        final products = <String, CartItemModel>{};
        final requiredByProduct = <String, int>{};
        for (final row in itemRows) {
          final inventoryId = row['inventory_id'] as String?;
          if (inventoryId == null) {
            throw StateError('Held order item is missing its inventory link.');
          }
          final units = row['units']! as int;
          requiredByProduct.update(
            inventoryId,
            (current) => current + units,
            ifAbsent: () => units,
          );
          final previous = products[inventoryId];
          products[inventoryId] = CartItemModel(
            listingId: row['listing_id']! as String,
            inventoryId: inventoryId,
            inventoryName: row['inventory_name']! as String,
            unitPrice: (row['unit_price']! as num).toDouble(),
            availableUnits: stockByProduct[inventoryId] ?? 0,
            units: (previous?.units ?? 0) + units,
          );
        }
        for (final entry in requiredByProduct.entries) {
          if ((stockByProduct[entry.key] ?? 0) < entry.value) {
            throw InsufficientLocalStockException(
              products[entry.key]!.inventoryName,
            );
          }
        }
        await transaction.delete(
          'local_orders',
          where: 'local_order_id = ?',
          whereArgs: [orderId],
        );
        return HeldOrderDraftModel(
          order: order,
          items: products.values.toList(growable: false),
        );
      });
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to resume held local order',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<LocalOrderModel>> getOrdersForToday() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toUtc();
      final end = start.add(const Duration(days: 1));
      final db = await _localDb.database;
      final rows = await db.query(
        'local_orders',
        where: 'created_at >= ? AND created_at < ? AND status = ?',
        whereArgs: [
          start.toIso8601String(),
          end.toIso8601String(),
          'COMPLETED',
        ],
        orderBy: 'created_at DESC',
      );
      return rows.map(LocalOrderModel.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load today’s local orders',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<LocalOrderModel?> getOrder(String orderId) async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_orders',
        where: 'local_order_id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      return rows.isEmpty ? null : LocalOrderModel.fromMap(rows.single);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load local order for submission',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<LocalOrderModel>> getOrdersAwaitingSubmission() async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_orders',
        where: 'status = ? AND sync_status IN (?, ?)',
        whereArgs: ['COMPLETED', 'PENDING', 'FAILED'],
        orderBy: 'created_at ASC',
      );
      return rows.map(LocalOrderModel.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load completed orders awaiting submission',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateSubmissionStatus({
    required String orderId,
    required String status,
    String? errorMessage,
    String? remoteOrderId,
  }) async {
    if (!const {'PENDING', 'SYNCED', 'FAILED'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Invalid sync status.');
    }
    try {
      final values = <String, Object?>{
        'sync_status': status,
        'sync_error': errorMessage,
      };
      if (remoteOrderId != null) values['remote_order_id'] = remoteOrderId;
      final db = await _localDb.database;
      final updated = await db.update(
        'local_orders',
        values,
        where: 'local_order_id = ? AND status = ?',
        whereArgs: [orderId, 'COMPLETED'],
      );
      if (updated != 1) {
        throw StateError('Completed local order was not found.');
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to update submission status for local order $orderId',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<LocalOrderItemModel>> getOrderItems(String orderId) async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_order_items',
        where: 'local_order_id = ?',
        whereArgs: [orderId],
        orderBy: 'rowid',
      );
      return rows
          .map(
            (row) => LocalOrderItemModel(
              localItemId: row['local_item_id']! as String,
              localOrderId: row['local_order_id']! as String,
              inventoryId: row['inventory_id'] as String? ?? '',
              stockItemId: row['stock_item_id']! as String,
              listingId: row['listing_id']! as String,
              inventoryName: row['inventory_name']! as String,
              unitPrice: (row['unit_price']! as num).toDouble(),
              units: row['units']! as int,
              subtotal: (row['subtotal']! as num).toDouble(),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load local order items',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ShiftSummaryModel> getTodaySummary() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toUtc();
      final end = start.add(const Duration(days: 1));
      final db = await _localDb.database;
      final rows = await db.rawQuery(
        '''
        SELECT
          COALESCE(SUM(CASE WHEN status = 'COMPLETED'
            AND payment_type = 'CASH'
            THEN total_amount ELSE 0 END), 0) AS cash_total,
          COALESCE(SUM(CASE WHEN status = 'COMPLETED'
            AND payment_type = 'MOBILE_MONEY'
            THEN total_amount ELSE 0 END), 0) AS mobile_money_total,
          SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END)
            AS completed_orders,
          SUM(CASE WHEN status = 'COMPLETED'
            AND sync_status IN ('PENDING', 'FAILED') THEN 1 ELSE 0 END)
            AS pending_orders
        FROM local_orders
        WHERE created_at >= ? AND created_at < ?
        ''',
        [start.toIso8601String(), end.toIso8601String()],
      );
      final row = rows.single;
      return ShiftSummaryModel(
        cashTotal: (row['cash_total'] as num).toDouble(),
        mobileMoneyTotal: (row['mobile_money_total'] as num).toDouble(),
        completedOrders: (row['completed_orders'] as num?)?.toInt() ?? 0,
        pendingOrders: (row['pending_orders'] as num?)?.toInt() ?? 0,
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to calculate local shift summary',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
