import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bartender_model.dart';
import '../../models/counter_station_model.dart';
import '../../models/counter_stock_allocation_model.dart';
import '../../models/local_order_item_model.dart';
import '../../models/local_order_model.dart';
import 'local_db_service.dart';

class OnlineSyncService {
  OnlineSyncService({
    required SupabaseClient client,
    required LocalDbService localDb,
    Logger? logger,
  }) : _client = client,
       _localDb = localDb,
       _logger = logger ?? Logger();

  final SupabaseClient _client;
  final LocalDbService _localDb;
  final Logger _logger;

  Future<void> submitCompletedOrder({
    required LocalOrderModel order,
    required List<LocalOrderItemModel> items,
  }) async {
    try {
      if (order.status != 'COMPLETED') {
        throw ArgumentError('Only completed orders can be submitted.');
      }
      if (items.isEmpty) {
        throw ArgumentError('A completed order must contain items.');
      }

      final orderId = order.localOrderId;
      final orderData = {
        'id': orderId,
        'counter_id': order.counterId,
        'bartender_id': order.bartenderId,
        'payment_type': order.paymentType,
        'status': order.status,
        'created_at': order.createdAt,
      };
      final existingOrder = await _client
          .from('orders')
          .select('id,counter_id,bartender_id,payment_type,status,created_at')
          .eq('id', orderId)
          .maybeSingle();

      if (existingOrder == null) {
        await _client.from('orders').insert(orderData);
      } else if (!_matchesRemoteOrder(existingOrder, orderData)) {
        throw StateError('The remote order ID already has different data.');
      }

      final remoteItems = await _client
          .from('order_items')
          .select('id,order_id,stock_item_id,listing_id,units')
          .eq('order_id', orderId);
      final remoteItemsById = {
        for (final row in remoteItems) row['id'] as String: row,
      };
      final itemsToInsert = <Map<String, Object?>>[];

      for (final item in items) {
        final itemData = {
          'id': item.localItemId,
          'order_id': orderId,
          'stock_item_id': item.stockItemId,
          'listing_id': item.listingId,
          'units': item.units,
        };
        final existingItem = remoteItemsById[item.localItemId];
        if (existingItem == null) {
          itemsToInsert.add(itemData);
        } else if (!_matchesRemoteItem(existingItem, itemData)) {
          throw StateError(
            'The remote order item ID already has different data.',
          );
        }
      }

      if (itemsToInsert.isNotEmpty) {
        await _client.from('order_items').insert(itemsToInsert);
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Completed order submission failed for local order ${order.localOrderId}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool _matchesRemoteOrder(
    Map<String, dynamic> remote,
    Map<String, Object?> expected,
  ) {
    final remoteCreatedAt = DateTime.tryParse(remote['created_at'] as String);
    final expectedCreatedAt = DateTime.parse(expected['created_at']! as String);
    return remote['id'] == expected['id'] &&
        remote['counter_id'] == expected['counter_id'] &&
        remote['bartender_id'] == expected['bartender_id'] &&
        remote['payment_type'] == expected['payment_type'] &&
        remote['status'] == expected['status'] &&
        remoteCreatedAt?.toUtc() == expectedCreatedAt.toUtc();
  }

  bool _matchesRemoteItem(
    Map<String, dynamic> remote,
    Map<String, Object?> expected,
  ) {
    return remote['id'] == expected['id'] &&
        remote['order_id'] == expected['order_id'] &&
        remote['stock_item_id'] == expected['stock_item_id'] &&
        remote['listing_id'] == expected['listing_id'] &&
        remote['units'] == expected['units'];
  }

  Future<void> pullBartenders() async {
    try {
      final remoteBartenders = await _client
          .from('bartenders')
          .select('id,counter_id,name,phone,pin_hash,is_active')
          .eq('is_active', true);
      final bartenders = remoteBartenders
          .map(BartenderModel.fromMap)
          .toList(growable: false);

      final db = await _localDb.database;
      await db.transaction((transaction) async {
        await transaction.update('local_bartenders', {'is_active': 0});
        for (final bartender in bartenders) {
          await transaction.insert(
            'local_bartenders',
            bartender.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (error, stackTrace) {
      _logger.e(
        'Bartender profile sync failed while downloading or caching remote data',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> pullCounterData(String counterId) async {
    try {
      final results = await Future.wait([
        _client.from('v_counter_stock').select().eq('counter_id', counterId),
        _client
            .from('counter_stations')
            .select('id,name,location,is_active')
            .eq('id', counterId)
            .eq('is_active', true)
            .limit(1),
      ]);
      final stockRows = results[0];
      final stationRows = results[1];
      if (stationRows.isEmpty) {
        throw StateError('The bartender assigned counter is unavailable.');
      }
      final station = CounterStationModel.fromMap(stationRows.single);
      final stockEntries = stockRows
          .map(
            (row) => CounterStockAllocationModel.fromCounterStockView(
              row,
              counterName: station.name,
            ),
          )
          .toList(growable: false);

      final db = await _localDb.database;
      await db.transaction((transaction) async {
        await transaction.delete(
          'local_counter_stock_cache',
          where: 'counter_id = ?',
          whereArgs: [counterId],
        );
        for (final stock in stockEntries) {
          await transaction.insert(
            'local_counter_stock_cache',
            stock.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await transaction.insert(
          'local_counter_stations',
          station.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await transaction.insert('local_app_metadata', {
          'key': 'counter_catalog_synced:$counterId',
          'value': 'true',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
    } catch (error, stackTrace) {
      _logger.e(
        'Assigned counter sync failed while downloading or caching remote data',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
