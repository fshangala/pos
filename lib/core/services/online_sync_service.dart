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
      final allocations = stockRows
          .map(
            (row) => CounterStockAllocationModel.fromCounterStockView(
              row,
              counterName: station.name,
            ),
          )
          .toList(growable: false);
      final listingsByInventory = <String, Map<String, Object?>>{};
      for (final row in stockRows) {
        if (row['listing_id'] == null || row['price'] == null) continue;
        final listing = ActiveListingModel.fromCounterStockView(row);
        listingsByInventory[listing.inventoryId] = listing.toMap();
      }

      final db = await _localDb.database;
      await db.transaction((transaction) async {
        await transaction.delete(
          'local_counter_stock',
          where: 'counter_id = ?',
          whereArgs: [counterId],
        );

        final inventoryIds = allocations
            .map((item) => item.inventoryId)
            .toSet();
        for (final inventoryId in inventoryIds) {
          await transaction.delete(
            'local_active_listings',
            where: 'inventory_id = ?',
            whereArgs: [inventoryId],
          );
        }
        for (final allocation in allocations) {
          await transaction.insert(
            'local_counter_stock',
            allocation.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final listing in listingsByInventory.values) {
          await transaction.insert(
            'local_active_listings',
            listing,
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
