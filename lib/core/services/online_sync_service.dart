import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/active_listing_model.dart';
import '../../models/bartender_model.dart';
import '../../models/counter_station_model.dart';
import '../../models/counter_stock_allocation_model.dart';
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

  Future<void> pullOnlineCatalogData() async {
    try {
      final results = await Future.wait([
        _client.from('v_active_listings').select(),
        _client.from('v_counter_stock_allocations').select(),
        _client
            .from('counter_stations')
            .select('id,name,location,is_active')
            .eq('is_active', true),
        _client
            .from('bartenders')
            .select('id,counter_id,name,phone,pin_hash,is_active')
            .eq('is_active', true),
      ]);

      final listings = results[0]
          .map(ActiveListingModel.fromRemote)
          .toList(growable: false);
      final allocations = results[1]
          .map(CounterStockAllocationModel.fromRemote)
          .toList(growable: false);
      final stations = results[2]
          .map(CounterStationModel.fromMap)
          .toList(growable: false);
      final bartenders = results[3]
          .map(BartenderModel.fromMap)
          .toList(growable: false);

      final db = await _localDb.database;
      await db.transaction((transaction) async {
        final previousAllocations = await transaction.query(
          'local_counter_stock',
          columns: ['counter_id', 'stock_item_id', 'local_units_sold'],
        );
        final soldByAllocation = {
          for (final row in previousAllocations)
            '${row['counter_id']}:${row['stock_item_id']}':
                (row['local_units_sold']! as num).toDouble(),
        };

        await transaction.delete('local_counter_stations');
        await transaction.delete('local_active_listings');
        await transaction.delete('local_counter_stock');
        await transaction.delete('local_bartenders');

        for (final station in stations) {
          await transaction.insert(
            'local_counter_stations',
            station.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final listing in listings) {
          await transaction.insert(
            'local_active_listings',
            listing.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final allocation in allocations) {
          final allocationKey =
              '${allocation.counterId}:${allocation.stockItemId}';
          final localUnitsSold = soldByAllocation[allocationKey] ?? 0;
          final availableUnits =
              (allocation.remoteRemainingUnits - localUnitsSold)
                  .clamp(0, double.infinity)
                  .toDouble();
          await transaction.insert(
            'local_counter_stock',
            CounterStockAllocationModel(
              counterStockId: allocation.counterStockId,
              counterId: allocation.counterId,
              counterName: allocation.counterName,
              stockItemId: allocation.stockItemId,
              inventoryId: allocation.inventoryId,
              inventoryName: allocation.inventoryName,
              barcode: allocation.barcode,
              remoteRemainingUnits: allocation.remoteRemainingUnits,
              unitsPerQuantity: allocation.unitsPerQuantity,
              totalAssignedUnits: allocation.totalAssignedUnits,
              localUnitsSold: localUnitsSold,
              lowStockThreshold: allocation.lowStockThreshold,
              isLowStock: availableUnits <= allocation.lowStockThreshold,
              syncedAt: allocation.syncedAt,
            ).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final bartender in bartenders) {
          await transaction.insert(
            'local_bartenders',
            bartender.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await transaction.insert('local_app_metadata', {
          'key': 'initial_catalog_sync_complete',
          'value': 'true',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
    } catch (error, stackTrace) {
      _logger.e(
        'Catalog sync failed while downloading or caching remote data',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
