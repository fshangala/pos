import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../core/services/local_db_service.dart';
import '../models/bartender_model.dart';
import '../models/counter_station_model.dart';
import '../models/register_product_model.dart';

class LocalCatalogRepository {
  LocalCatalogRepository({required LocalDbService localDb, Logger? logger})
    : _localDb = localDb,
      _logger = logger ?? Logger();

  final LocalDbService _localDb;
  final Logger _logger;

  Future<List<RegisterProductModel>> getProducts(String counterId) async {
    try {
      final db = await _localDb.database;
      final rows = await db.rawQuery(
        '''
        SELECT l.inventory_id, l.listing_id, l.inventory_name,
               l.barcode, l.price,
               SUM(MAX(cs.remote_remaining_units - cs.local_units_sold, 0))
                 AS available_units
        FROM local_active_listings AS l
        JOIN local_counter_stock AS cs
          ON cs.inventory_id = l.inventory_id
         AND cs.counter_id = ?
        WHERE l.active = 1
        GROUP BY l.inventory_id, l.listing_id, l.inventory_name,
                 l.barcode, l.price
        ORDER BY l.inventory_name COLLATE NOCASE
        ''',
        [counterId],
      );
      return rows.map(RegisterProductModel.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load cached register catalog',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<CounterStationModel>> getStations() async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_counter_stations',
        orderBy: 'name COLLATE NOCASE',
      );
      return rows.map(CounterStationModel.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load cached counter stations',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<BartenderModel>> getActiveBartenders() async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_bartenders',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name COLLATE NOCASE',
      );
      return rows.map(BartenderModel.fromMap).toList(growable: false);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load cached bartender profiles',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<CounterStationModel?> getStation(String counterId) async {
    try {
      final db = await _localDb.database;
      final rows = await db.query(
        'local_counter_stations',
        where: 'id = ? AND is_active = ?',
        whereArgs: [counterId, 1],
        limit: 1,
      );
      return rows.isEmpty ? null : CounterStationModel.fromMap(rows.single);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load the bartender assigned counter',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> hasActiveBartenders() async {
    try {
      final db = await _localDb.database;
      final rows = await db.rawQuery(
        'SELECT EXISTS(SELECT 1 FROM local_bartenders WHERE is_active = 1) AS ready',
      );
      return Sqflite.firstIntValue(rows) == 1;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to check for cached bartender profiles',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> hasCounterCatalog(String counterId) async {
    try {
      final synced = await _localDb.getMetadata(
        'counter_catalog_synced:$counterId',
      );
      if (synced == 'true') return true;

      final db = await _localDb.database;
      final rows = await db.rawQuery(
        '''
        SELECT EXISTS(
          SELECT 1 FROM local_counter_stock WHERE counter_id = ?
        ) AS ready
        ''',
        [counterId],
      );
      if (Sqflite.firstIntValue(rows) == 1) return true;
      return await _localDb.hasCompletedInitialSync &&
          await getStation(counterId) != null;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to check for cached assigned-counter catalog',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> hasCatalog() async {
    try {
      final db = await _localDb.database;
      final result = await db.rawQuery(
        'SELECT EXISTS(SELECT 1 FROM local_active_listings) AS ready',
      );
      return Sqflite.firstIntValue(result) == 1;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to check local catalog readiness',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
