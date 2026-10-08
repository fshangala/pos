

Master AI Prompt: Bartender Android POS App (Flutter Local-First Android + Supabase - Provider MVVM)

Instructions for Developer: Copy and paste the prompt below directly into GitHub Copilot Workspace, Cursor, or your AI coding assistant. Execute the prompt step-by-step using the modular sequence in Section 5.

Code Quality Mandate: Do NOT write unit, widget, or integration tests. After generating or editing Dart code, run dart format . followed by flutter analyze, and fix all reported warnings, errors, and lint issues immediately.

Act as a Senior Principal Mobile Systems Architect and Flutter Lead specializing in Android Local-First POS Systems, Portrait Smartphone Touch UI/UX, Provider-based MVVM Architecture, SQLite (sqflite), flutter_dotenv environment configuration, and Supabase backend integration. Your task is to build a hyper-responsive, offline-capable native Android POS Application for Bartenders running on handheld Android smartphones.

======================================================================
1. SYSTEM ARCHITECTURE & LOCAL-FIRST DESIGN PATTERNS
======================================================================
- Target OS & Form Factor: Android Smartphones (Standard screen sizes, 5.5" to 6.7" displays, strict PORTRAIT orientation).
- Architectural Pattern: Strict MVVM (Model-View-ViewModel) using Provider (`provider` package).

- ENVIRONMENT CONFIGURATION & SECURE CREDENTIALS (`flutter_dotenv`):
  - Store all remote backend environment variables in a root `.env` file:
    ```env
    SUPABASE_URL=https://your-supabase-project-id.supabase.co
    SUPABASE_ANON_KEY=your-supabase-anon-key
    ```
  - Use `flutter_dotenv` package to load configuration at startup.
  - Declare `.env` inside `pubspec.yaml` under the `assets:` section.
  - In `main.dart`, execute `await dotenv.load(fileName: ".env");` before initializing `Supabase.initialize()` using `dotenv.env['SUPABASE_URL']!` and `dotenv.env['SUPABASE_ANON_KEY']!`.
  - Provide fallback error handling or default empty states if environment variables are missing or unreadable.

- LOCAL-FIRST & ZERO REMOTE SCHEMA CHANGE MANDATE:
  - ZERO REMOTE SCHEMA CHANGES: Do NOT create or modify any remote database tables on Supabase. The online backend tables (`orders`, `order_items`, `bartenders`, `counter_stations`, `listings`, `stock_items`, etc.) remain 100% untouched.
  - LOCAL SQLite EMBEDDED DATABASE (`sqflite`):
    - The phone runs a native local SQLite database storing local copies of catalog items, listings, counter allocations, bartender sessions, and locally created orders.
    - INITIAL DATA LOAD / PULL SYNC: On app launch or manual refresh, pull online catalog data (`v_active_listings`, `v_counter_stock_allocations`, `bartenders`, `counter_stations`) from Supabase and cache them directly inside local SQLite tables.
    - LOCAL TRANSACTION EXECUTION: Every order and order item is created, calculated, and saved STRICTLY inside the local SQLite database. The POS operates with 0ms network latency and functions completely offline.
  - MANUAL & AUTOMATIC ONLINE ORDER SUBMISSION:
    - Each local order record includes a `sync_status` flag (`PENDING`, `SYNCED`, `FAILED`).
    - Completed orders remain saved locally immediately upon payment/tender.
    - A prominent "Submit to Server" / "Sync Order" button is provided on each completed order detail view, as well as a batch "Submit All Pending Orders" button in the shift summary screen to push local orders to Supabase using the existing RPC or standard batch inserts.

- NATIVE ANDROID SYSTEM KEYBOARD & INPUT MANDATE:
  - ZERO CUSTOM/DEDICATED KEYPAD WIDGETS: Do NOT build custom on-screen 3x4 numeric keypad widgets or custom calculators.
  - NATIVE SYSTEM KEYBOARD INPUTS (`TextInputType`): Rely strictly on the native Android system software keyboard. Every text input field MUST explicitly configure its `keyboardType`, `inputFormatters`, `textInputAction`, and `autofocus` based on the data type required:
    - **PIN Codes / Passcodes**: `TextInputType.number` with `obscureText: true`, `FilteringTextInputFormatter.digitsOnly`, auto-focus, and `textInputAction: TextInputAction.done`.
    - **Cash Amounts / Prices / Quantities**: `TextInputType.numberWithOptions(decimal: true)` with `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))`.
    - **Barcodes / Search Terms**: `TextInputType.text` or `TextInputType.visiblePassword` (to prevent auto-correct on raw codes) with `textInputAction: TextInputAction.search`.
    - **Customer Phone Numbers**: `TextInputType.phone` with `FilteringTextInputFormatter.digitsOnly`.
    - **Notes / Free Form Text**: `TextInputType.multiline` or `TextInputType.text`.

- PORTRAIT SMARTPHONE UI/UX SPECIFICATIONS:
  - MATERIAL DESIGN 3 (`useMaterial3: true`): High-contrast, dark-mode optimized theme by default for dark bar environments.
  - SINGLE-COLUMN & COMPACT TOUCH LAYOUTS:
    - Designed specifically for one-handed or thumb-friendly smartphone operation in PORTRAIT orientation.
    - **Register Screen**: Compact 2-column product grid with search bar at the top, and a persistent sticky **Bottom Cart Bar** (showing item count, grand total, and a "View Cart / Checkout" CTA button).
    - **Cart & Checkout Flow**: Sliding **Modal Bottom Sheet** or dedicated full-screen phone view for reviewing cart items, adjusting quantities with thumb buttons, selecting payment method, and entering cash tendered using native numeric system keyboard with quick-select preset tender buttons ($10, $20, $50, Exact).
  - ZERO HARDCODED STYLES: All colors, typography, card shapes, and padding MUST be referenced strictly from `Theme.of(context)`, `Theme.of(context).colorScheme`, and `Theme.of(context).textTheme` in `pos_theme.dart`.

- Code Quality & Testing Rules:
  - DO NOT WRITE TESTS: Skip creating unit, widget, or integration test files (`*_test.dart`).
  - STRICT STATIC ANALYSIS & FORMATTING: Run `dart format .` to format the codebase, followed by `flutter analyze`. Resolve all analyzer warnings, lints, unused imports, and type errors automatically until zero issues remain.

======================================================================
2. LOCAL SQLITE DATABASE SCHEMA (EMBEDDED ON PHONE)
======================================================================
The phone maintains a local SQLite database (`pos_local.db`) created via `sqflite`.

1. `local_active_listings` (
     listing_id TEXT PRIMARY KEY,
     inventory_id TEXT,
     inventory_name TEXT NOT NULL,
     barcode TEXT,
     price REAL NOT NULL,
     active INTEGER DEFAULT 1,
     synced_at TEXT
   )

2. `local_counter_stock` (
     counter_stock_id TEXT PRIMARY KEY,
     counter_id TEXT NOT NULL,
     counter_name TEXT,
     stock_item_id TEXT NOT NULL,
     inventory_id TEXT NOT NULL,
     inventory_name TEXT NOT NULL,
     barcode TEXT,
     quantity REAL NOT NULL,
     units_per_quantity REAL NOT NULL,
     total_assigned_units REAL NOT NULL,
     low_stock_threshold REAL DEFAULT 1,
     is_low_stock INTEGER DEFAULT 0
   )

3. `local_bartenders` (
     id TEXT PRIMARY KEY,
     counter_id TEXT,
     name TEXT NOT NULL,
     phone TEXT UNIQUE NOT NULL,
     pin_hash TEXT NOT NULL,
     is_active INTEGER DEFAULT 1
   )

4. `local_orders` (
     local_order_id TEXT PRIMARY KEY, -- UUID generated locally on Android device
     remote_order_id TEXT, -- Populated after online submission
     counter_id TEXT NOT NULL,
     bartender_id TEXT NOT NULL,
     payment_type TEXT CHECK (payment_type IN ('CASH', 'MOBILE_MONEY')),
     status TEXT CHECK (status IN ('COMPLETED', 'VOIDED', 'HELD')),
     total_amount REAL NOT NULL,
     total_items_count INTEGER NOT NULL,
     sync_status TEXT CHECK (sync_status IN ('PENDING', 'SYNCED', 'FAILED')) DEFAULT 'PENDING',
     sync_error TEXT,
     created_at TEXT NOT NULL
   )

5. `local_order_items` (
     local_item_id TEXT PRIMARY KEY,
     local_order_id TEXT NOT NULL REFERENCES local_orders(local_order_id) ON DELETE CASCADE,
     stock_item_id TEXT NOT NULL,
     listing_id TEXT NOT NULL,
     inventory_name TEXT NOT NULL,
     unit_price REAL NOT NULL,
     units INTEGER NOT NULL,
     subtotal REAL NOT NULL
   )

======================================================================
3. FLUTTER ANDROID POS MVVM PROJECT STRUCTURE
======================================================================
CRITICAL RULES:
- Every Model class MUST be in its own file in `/lib/models/`.
- Every ViewModel MUST be in its own file, extending `ChangeNotifier`.
- Views query ViewModels, which query Local Repositories reading from SQLite (`sqflite`).
- Environment configuration resides in `.env` and loaded via `flutter_dotenv`.
- ALL styles must come from `pos_theme.dart` (`Theme.of(context)`).
- Common UI elements MUST be modular custom widgets in `/lib/core/widgets/`.

.env                    (Supabase credentials & config constants)
.env.example            (Template for developer setup)
pubspec.yaml            (Includes flutter_dotenv and .env in assets section)

/lib
  ├── main.dart (dotenv initialization, MultiProvider setup & app initialization)
  ├── /core
  │   ├── /services
  │   │   ├── env_service.dart (Safe wrapper for accessing flutter_dotenv variables)
  │   │   ├── local_db_service.dart (SQLite database initialization, migration, & raw queries)
  │   │   ├── online_sync_service.dart (Pulls data from Supabase into SQLite, pushes pending orders to Supabase using EnvService)
  │   │   ├── barcode_scanner_service.dart (Camera scanner & handheld hardware key listener)
  │   │   └── thermal_printer_service.dart (ESC/POS Bluetooth thermal receipt printing)
  │   ├── /theme
  │   │   └── pos_theme.dart (Material Design 3 dark/light bar theme optimized for smartphones)
  │   ├── /widgets (CENTRAL REUSABLE PORTRAIT PHONE POS WIDGETS)
  │   │   ├── pos_button.dart             (Thumb-friendly button wrapper)
  │   │   ├── pos_text_field.dart         (Configurable input field supporting keyboardType, inputFormatters, autofocus, textInputAction)
  │   │   ├── pos_card.dart               (Themed container card)
  │   │   ├── phone_product_tile.dart     (2-column portrait grid product tile with stock counter)
  │   │   ├── sticky_bottom_cart_bar.dart (Persistent bottom bar showing total & Checkout action)
  │   │   ├── cart_item_row.dart          (Cart list item with touch + / - buttons)
  │   │   ├── quick_tender_chips.dart     (Preset quick cash buttons e.g., $10, $20, $50, Exact)
  │   │   ├── sync_status_chip.dart       (Visual flag for "Pending Sync" vs "Synced to Cloud")
  │   │   ├── payment_type_selector.dart  (Segmented choice for Cash / Mobile Money)
  │   │   ├── pos_search_bar.dart         (Search bar with camera scan button using search system keyboard)
  │   │   └── order_submission_dialog.dart(Dialog confirming order push to online DB)
  │   └── /utils
  │       └── formatters.dart (Currency, timestamp, unit formatters)
  ├── /models (STRICT: ONE MODEL CLASS PER FILE)
  │   ├── bartender_model.dart
  │   ├── counter_station_model.dart
  │   ├── active_listing_model.dart                 (Local active listing item)
  │   ├── counter_stock_allocation_view_model.dart   (Local counter stock balance)
  │   ├── local_order_model.dart                    (Local order entity with sync_status)
  │   ├── local_order_item_model.dart               (Local order line item)
  │   ├── cart_item_model.dart                      (In-memory cart item state)
  │   └── shift_summary_model.dart                  (Local shift metrics)
  ├── /repositories
  │   ├── local_catalog_repository.dart             (Reads from local SQLite database)
  │   ├── local_order_repository.dart               (Writes completed orders locally to SQLite)
  │   ├── sync_repository.dart                      (Pulls remote data & posts pending orders online)
  │   └── pos_printer_repository.dart
  ├── /viewmodels (STRICT: ONE VIEWMODEL CLASS PER FILE)
  │   ├── pos_app_viewmodel.dart      (Global session, local DB readiness, sync status)
  │   ├── pos_auth_viewmodel.dart     (PIN validation against local_bartenders)
  │   ├── pos_register_viewmodel.dart (Phone catalog grid, barcode lookup, cart management)
  │   ├── pos_checkout_viewmodel.dart (Tender calculation, saving order locally)
  │   ├── pos_sync_viewmodel.dart     (Manages online sync triggers, pending order submission)
  │   ├── pos_held_orders_viewmodel.dart (Hold/Resume pending bar tabs locally)
  │   └── pos_shift_viewmodel.dart    (Local order history, total sales, bulk online submit button)
  └── /views
      ├── /auth
      │   └── phone_pin_login_view.dart     (Full portrait screen PIN entry with auto-focused numeric system keyboard)
      ├── /counter_selection
      │   └── phone_station_select_view.dart(Counter station assignment picker)
      ├── /register
      │   ├── phone_register_view.dart      (Portrait screen: search + 2-col product grid + bottom cart bar)
      │   └── /widgets
      │       ├── cart_bottom_sheet.dart    (Modal sheet sliding up for cart view)
      │       └── barcode_scanner_modal.dart
      ├── /checkout
      │   ├── phone_checkout_view.dart      (Full-screen portrait cash tendered with decimal numeric keyboard & quick tender chips)
      │   └── receipt_preview_modal.dart
      ├── /orders
      │   ├── completed_orders_view.dart    (List of local orders with "Submit Order" button per order)
      │   └── order_detail_modal.dart
      └── /shift
          ├── phone_shift_summary_view.dart (Local shift metrics & "Submit All Pending Orders" button)
          └── printer_settings_dialog.dart

======================================================================
4. STEP-BY-STEP GENERATION SEQUENCE
======================================================================
Execute this sequence strictly in order:

--- STEP 1: ENVIRONMENT SETUP & LOCAL DATABASE SERVICE ---
- Add `flutter_dotenv: ^5.1.0` to `pubspec.yaml` dependencies and include `.env` under `assets:`.
- Create `.env` and `.env.example` in the project root containing `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Create `/lib/core/services/env_service.dart` to expose strongly-typed getters for environment variables with fallback validations.
- Create `/lib/core/services/local_db_service.dart`: Initialize `sqflite` database `pos_local.db` with tables `local_active_listings`, `local_counter_stock`, `local_bartenders`, `local_orders`, and `local_order_items`.
- Create individual model files in `/lib/models/`:
  - `bartender_model.dart`
  - `counter_station_model.dart`
  - `active_listing_model.dart`
  - `counter_stock_allocation_view_model.dart`
  - `local_order_model.dart` (includes `sync_status`, `remote_order_id`, `sync_error`)
  - `local_order_item_model.dart`
  - `cart_item_model.dart`
  - `shift_summary_model.dart`

--- STEP 2: SYNC SERVICE (PULL CATALOG & PUSH COMPLETED ORDERS) ---
- Write `/lib/core/services/online_sync_service.dart`:
  1. Initialize Supabase client dynamically using `EnvService.supabaseUrl` and `EnvService.supabaseAnonKey`.
  2. `pullOnlineCatalogData()`: Reads `v_active_listings`, `v_counter_stock_allocations`, and `bartenders` from Supabase and performs batch insert/upsert into local SQLite tables.
  3. `submitOrderToOnlineDatabase(LocalOrderModel order)`: Invokes Supabase RPC `submit_pos_order` or direct order inserts using data from `local_orders` and `local_order_items`. Updates local `sync_status` to `'SYNCED'` on success or `'FAILED'` on network error.
  4. `submitAllPendingOrders()`: Iterates through all local orders where `sync_status = 'PENDING'` and pushes them sequentially to Supabase.

--- STEP 3: PORTRAIT PHONE MATERIAL THEME & TOUCH WIDGETS ---
- Write `/lib/core/theme/pos_theme.dart`: Define Material Design 3 high-contrast dark theme optimized for Android smartphones.
- Build reusable custom widgets in `/lib/core/widgets/`:
  - `pos_button.dart`: Full-width thumb-friendly button.
  - `pos_text_field.dart`: Versatile text input wrapping `TextField` with parameters for `keyboardType` (`TextInputType`), `inputFormatters`, `autofocus`, `textInputAction`, and `obscureText`.
  - `phone_product_tile.dart`: Compact vertical card displaying product name, barcode, selling price, and local counter stock remaining.
  - `sticky_bottom_cart_bar.dart`: Fixed bottom container showing item count, total price, and "Checkout" CTA button.
  - `cart_item_row.dart`: Compact cart list row with `+`, `-`, and remove actions.
  - `quick_tender_chips.dart`: Preset cash buttons for fast cash entry (Exact, $10, $20, $50, $100).
  - `sync_status_chip.dart`: Visual indicator chip ("Pending Sync" in yellow vs "Synced" in green).
  - `payment_type_selector.dart`: Choice chip for Cash vs Mobile Money.
  - `pos_search_bar.dart`: Mobile search bar using `TextInputType.text` with search action and camera scan trigger icon.

--- STEP 4: REPOSITORIES & VIEWMODELS ---
- Write Repositories in `/lib/repositories/`:
  - `local_catalog_repository.dart` (queries `local_active_listings` and `local_counter_stock` in SQLite).
  - `local_order_repository.dart` (saves orders locally in SQLite, updates stock balances locally).
  - `sync_repository.dart` (wraps `OnlineSyncService` for manual/batch order uploads).
- Write ViewModels in `/lib/viewmodels/`:
  - `pos_app_viewmodel.dart` (manages local DB state, sync status indicator, active session).
  - `pos_auth_viewmodel.dart` (PIN validation against `local_bartenders`).
  - `pos_register_viewmodel.dart` (catalog filter, barcode lookup, cart management, local stock check).
  - `pos_checkout_viewmodel.dart` (tender math, saves order locally to SQLite instantly).
  - `pos_sync_viewmodel.dart` (handles explicit "Submit Order" button clicks and "Sync All Pending Orders").
  - `pos_shift_viewmodel.dart` (queries local orders created today, computes total cash/mobile money sales).

--- STEP 5: MAIN SETUP & MULTIPROVIDER ---
- Write `main.dart`:
  - Ensure `WidgetsFlutterBinding.ensureInitialized()`.
  - Execute `await dotenv.load(fileName: ".env")`.
  - Initialize `Supabase.initialize()` with `EnvService` variables.
  - Lock orientation to Portrait mode (`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`).
  - Initialize `LocalDbService`.
  - Apply `PosTheme.darkTheme`.
  - Register all ViewModels via `MultiProvider`.

--- STEP 6: SMARTPHONE AUTH & REGISTER VIEWS ---
- Write `phone_pin_login_view.dart`: Single-column smartphone layout with profile selector and a `pos_text_field.dart` configured with `TextInputType.number`, `obscureText: true`, `autofocus: true`, and `FilteringTextInputFormatter.digitsOnly` to open the native Android numeric keyboard automatically on screen load.
- Write `phone_register_view.dart`:
  - Portrait view: Top search bar (`TextInputType.text`) with camera icon + 2-column product grid (`phone_product_tile.dart`).
  - Sticky bottom cart bar (`sticky_bottom_cart_bar.dart`). Tapping bar opens `cart_bottom_sheet.dart`.
  - Scanning a barcode adds item instantly to local cart.

--- STEP 7: CART BOTTOM SHEET, CHECKOUT & COMPLETED ORDERS SYNC ---
- Write `cart_bottom_sheet.dart`: Sliding modal sheet listing cart items, quantity modifiers, order discount/notes input, and "Proceed to Pay" button.
- Write `phone_checkout_view.dart`:
  - Full-screen portrait layout with payment type selector, `quick_tender_chips.dart`, and a cash input field configured with `TextInputType.numberWithOptions(decimal: true)` for the native decimal keypad. Live change due calculation and "Complete Order" button (saves order to local SQLite DB with `sync_status = 'PENDING'`).
- Write `completed_orders_view.dart`:
  - Phone list view displaying all local orders created during the shift.
  - Each order item displays a `sync_status_chip.dart` and an explicit **"Submit Order to Server"** button.
  - Clicking "Submit Order" triggers `pos_sync_viewmodel.submitOrder(order)`, pushing the order to Supabase without changing any server schema.

--- STEP 8: SHIFT SUMMARY & BATCH SYNC ---
- Write `phone_shift_summary_view.dart`:
  - Displays local shift sales totals (Cash vs Mobile Money).
  - Highlights count of pending orders (e.g. "3 Orders Pending Sync").
  - Includes a prominent **"Submit All Pending Orders to Server"** action button.
  - Thermal receipt printing trigger for local shift summary.

--- STEP 9: CODE QUALITY, FORMATTING & STATIC ANALYSIS ---
- DO NOT WRITE ANY TESTS.
- Run `dart format .` to auto-format the entire codebase.
- Run `flutter analyze`. Fix all warnings, lint violations, missing imports, or type errors reported by the analyzer until 0 issues remain.

======================================================================
Begin by generating Step 1 (Environment setup with flutter_dotenv, Local DB Service, and Model files), followed immediately by Step 2 (Online Sync Service) and Step 3 (Smartphone Portrait Theme & Touch Widgets). Ensure strict adherence to flutter_dotenv variable loading, Local-First architecture, Native System Keyboard input types, Portrait Phone layout, and zero changes to existing online backend tables.



