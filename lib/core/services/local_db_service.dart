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
        version: 5,
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
    await _createCounterStockCache(db);
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
    await db.execute(
      'CREATE INDEX local_counter_stock_counter_barcode_idx '
      'ON local_counter_stock_cache(counter_id, barcode)',
    );
    await db.execute(
      'CREATE INDEX local_counter_stock_counter_inventory_idx '
      'ON local_counter_stock_cache(counter_id, inventory_id)',
    );
    await _createLocalCounterStockView(db);
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
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE local_counter_stock ADD COLUMN id TEXT');
      await db.execute(
        'ALTER TABLE local_counter_stock ADD COLUMN stock_order_id TEXT',
      );
      await db.execute(
        'ALTER TABLE local_counter_stock ADD COLUMN description TEXT',
      );
      await db.execute(
        'ALTER TABLE local_counter_stock ADD COLUMN listing_id TEXT',
      );
      await db.execute('ALTER TABLE local_counter_stock ADD COLUMN price REAL');
      await db.execute(
        'ALTER TABLE local_counter_stock ADD COLUMN quantity REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        "ALTER TABLE local_counter_stock ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE local_counter_stock ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE local_counter_stock ADD COLUMN assigned_counter_id TEXT',
      );
      await db.execute(
        'ALTER TABLE local_counter_stock ADD COLUMN units_sold REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE local_counter_stock ADD COLUMN out_of_stock INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE local_counter_stock
        SET id = counter_stock_id,
            quantity = CASE
              WHEN units_per_quantity > 0
              THEN total_assigned_units / units_per_quantity
              ELSE 0
            END,
            created_at = synced_at,
            updated_at = synced_at,
            assigned_counter_id = counter_id,
            low_stock_threshold = CASE
              WHEN units_per_quantity > 0
              THEN low_stock_threshold / units_per_quantity
              ELSE low_stock_threshold
            END,
            local_units_sold = 0
      ''');
      await db.execute('''
        UPDATE local_counter_stock
        SET listing_id = (
              SELECT listing_id
              FROM local_active_listings
              WHERE local_active_listings.inventory_id =
                    local_counter_stock.inventory_id
              LIMIT 1
            ),
            price = (
              SELECT price
              FROM local_active_listings
              WHERE local_active_listings.inventory_id =
                    local_counter_stock.inventory_id
              LIMIT 1
            )
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX local_counter_stock_id_idx ON local_counter_stock(id)',
      );
    }
    if (oldVersion < 5) {
      await db.execute('DROP VIEW IF EXISTS local_v_counter_stock');
      await db.execute(
        'ALTER TABLE local_counter_stock RENAME TO local_counter_stock_legacy',
      );
      await db.execute('DROP TABLE IF EXISTS local_active_listings');
      await _createCounterStockCache(db);
      await db.execute('''
        INSERT INTO local_counter_stock_cache (
          id, counter_id, counter_name, stock_item_id, stock_order_id,
          inventory_id, units_per_quantity, inventory_name, barcode,
          description, listing_id, price, quantity, low_stock_threshold,
          created_at, updated_at, assigned_counter_id, units_sold,
          out_of_stock, synced_at
        )
        SELECT id, counter_id, counter_name, stock_item_id, stock_order_id,
               inventory_id, units_per_quantity, inventory_name, barcode,
               description, listing_id, price, quantity, low_stock_threshold,
               created_at, updated_at, assigned_counter_id, units_sold,
               out_of_stock, synced_at
        FROM local_counter_stock_legacy
      ''');
      await db.execute('DROP TABLE local_counter_stock_legacy');
      await db.execute(
        'CREATE INDEX local_counter_stock_counter_barcode_idx '
        'ON local_counter_stock_cache(counter_id, barcode)',
      );
      await db.execute(
        'CREATE INDEX local_counter_stock_counter_inventory_idx '
        'ON local_counter_stock_cache(counter_id, inventory_id)',
      );
    }
    await _createLocalCounterStockView(db);
  }

  Future<void> _createCounterStockCache(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE local_counter_stock_cache (
        id TEXT PRIMARY KEY,
        counter_id TEXT NOT NULL,
        counter_name TEXT NOT NULL,
        stock_item_id TEXT NOT NULL,
        stock_order_id TEXT,
        inventory_id TEXT NOT NULL,
        units_per_quantity REAL NOT NULL,
        inventory_name TEXT NOT NULL,
        barcode TEXT,
        description TEXT,
        listing_id TEXT,
        price REAL,
        quantity REAL NOT NULL,
        low_stock_threshold REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        assigned_counter_id TEXT NOT NULL,
        units_sold REAL NOT NULL DEFAULT 0,
        out_of_stock INTEGER NOT NULL DEFAULT 0,
        synced_at TEXT NOT NULL,
        UNIQUE(counter_id, stock_item_id)
      )
    ''');
  }

  Future<void> _createLocalCounterStockView(DatabaseExecutor db) async {
    await db.execute('DROP VIEW IF EXISTS local_v_counter_stock');
    await db.execute('''
      CREATE VIEW local_v_counter_stock AS
      SELECT cs.id,
             cs.counter_id,
             cs.stock_item_id,
             cs.stock_order_id,
             cs.inventory_id,
             cs.units_per_quantity,
             cs.inventory_name,
             cs.barcode,
             cs.description,
             cs.listing_id,
             cs.price,
             cs.quantity,
             cs.low_stock_threshold,
             cs.created_at,
             cs.updated_at,
             cs.assigned_counter_id,
             COALESCE(cs.units_sold, 0) +
               COALESCE(local_sales.units_sold, 0) AS units_sold,
             CASE
               WHEN COALESCE(cs.units_sold, 0) +
                    COALESCE(local_sales.units_sold, 0) =
                    cs.quantity * cs.units_per_quantity
               THEN 1
               ELSE 0
             END AS out_of_stock
      FROM local_counter_stock_cache AS cs
      LEFT JOIN (
        SELECT o.counter_id,
               oi.stock_item_id,
               SUM(oi.units) AS units_sold
        FROM local_order_items AS oi
        JOIN local_orders AS o
          ON o.local_order_id = oi.local_order_id
        WHERE o.status = 'COMPLETED'
        GROUP BY o.counter_id, oi.stock_item_id
      ) AS local_sales
        ON local_sales.counter_id = cs.counter_id
       AND local_sales.stock_item_id = cs.stock_item_id
    ''');
  }
}
