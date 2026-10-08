import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  LocalDbService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  late final Future<Database> database = _openDatabase();

  Future<bool> get hasCompletedInitialSync async =>
      await getMetadata('initial_catalog_sync_complete') == 'true';

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final rows = await db.query(
      'local_app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert('local_app_metadata', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Database> _openDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      return await openDatabase(
        path.join(dbPath, 'pos_local.db'),
        version: 3,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to open local POS database',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_counter_stations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE local_active_listings (
        listing_id TEXT PRIMARY KEY,
        inventory_id TEXT NOT NULL,
        inventory_name TEXT NOT NULL,
        barcode TEXT,
        price REAL NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        synced_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE local_counter_stock (
        counter_stock_id TEXT PRIMARY KEY,
        counter_id TEXT NOT NULL,
        counter_name TEXT NOT NULL,
        stock_item_id TEXT NOT NULL,
        inventory_id TEXT NOT NULL,
        inventory_name TEXT NOT NULL,
        barcode TEXT,
        remote_remaining_units REAL NOT NULL,
        units_per_quantity REAL NOT NULL,
        total_assigned_units REAL NOT NULL,
        local_units_sold REAL NOT NULL DEFAULT 0,
        low_stock_threshold REAL NOT NULL DEFAULT 1,
        is_low_stock INTEGER NOT NULL DEFAULT 0,
        synced_at TEXT NOT NULL,
        UNIQUE(counter_id, stock_item_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE local_bartenders (
        id TEXT PRIMARY KEY,
        counter_id TEXT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        pin_hash TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE local_orders (
        local_order_id TEXT PRIMARY KEY,
        remote_order_id TEXT,
        counter_id TEXT NOT NULL,
        bartender_id TEXT NOT NULL,
        payment_type TEXT NOT NULL CHECK (payment_type IN ('CASH', 'MOBILE_MONEY')),
        status TEXT NOT NULL CHECK (status IN ('COMPLETED', 'VOIDED', 'HELD')),
        total_amount REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0,
        notes TEXT,
        total_items_count INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING'
          CHECK (sync_status IN ('PENDING', 'SYNCED', 'FAILED')),
        sync_error TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE local_order_items (
        local_item_id TEXT PRIMARY KEY,
        local_order_id TEXT NOT NULL,
        inventory_id TEXT NOT NULL,
        stock_item_id TEXT NOT NULL,
        listing_id TEXT NOT NULL,
        inventory_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        units INTEGER NOT NULL CHECK (units > 0),
        subtotal REAL NOT NULL,
        FOREIGN KEY (local_order_id) REFERENCES local_orders(local_order_id)
          ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE local_app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX local_orders_created_at_idx ON local_orders(created_at)',
    );
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE local_orders ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE local_orders ADD COLUMN notes TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE local_order_items ADD COLUMN inventory_id TEXT',
      );
      await db.execute('''
        UPDATE local_order_items
        SET inventory_id = (
          SELECT inventory_id
          FROM local_counter_stock
          WHERE local_counter_stock.stock_item_id = local_order_items.stock_item_id
          LIMIT 1
        )
      ''');
    }
  }
}
