# POS Project Instructions

Use [the bartender POS master prompt](../github_copilot_master_prompt_bartender_android_pos_app.md) as the detailed product and architecture specification. These repository-specific instructions record confirmed decisions and constraints that override conflicting parts of that prompt.

## Product and Architecture

- Build a native Flutter POS for Android smartphones in strict portrait orientation, optimized for one-handed use on 5.5- to 6.7-inch screens.
- Use Provider with MVVM. Views depend on `ChangeNotifier` ViewModels; ViewModels depend on repositories; repositories access SQLite or remote services. Keep each model and each ViewModel in its own file.
- Keep local checkout authoritative and usable offline after initial catalog setup. Persist a completed order locally before attempting any network action.
- Keep shared UI in `lib/core/widgets/`, app styling in `lib/core/theme/pos_theme.dart`, and all widgets styled through `Theme.of(context)` and its color scheme/text theme.
- Follow the master prompt's project structure and staged implementation sequence. Prefer focused changes and existing project conventions.

## Environment and Startup

- Load Supabase settings from the root `.env` using `flutter_dotenv`; list the asset in `pubspec.yaml`. Maintain `.env.example` with placeholders, never real credentials.
- Validate configuration and handle missing/unreadable settings with a visible setup/error state instead of force-unwrapping missing values or crashing.
- Initialize Flutter bindings, environment configuration, Supabase when configured, portrait orientation, local SQLite, and providers in a deliberate startup sequence.
- Require a successful initial online catalog sync before first POS use. After initial setup, use cached data for offline launches.
- Treat the Supabase anon key as a public client key, not a secret. Never log it or other credentials.

## Local Data and Supabase

- Use app-private SQLite (`pos_local.db`) for catalog cache, stations, bartenders, local orders, and order items. SQLite requires no Android manifest permission.
- Perform order totals, tender calculations, order persistence, and local stock decrements locally and transactionally. Keep stable local UUIDs, sale-time unit prices/subtotals, total amount, item count, and `PENDING`/`SYNCED`/`FAILED` state in local records.
- Use the existing catalog views `v_active_listings` and `v_counter_stock_allocations`, plus `bartenders` and `counter_stations`, for initial catalog sync. Do not assume undeclared views or functions.
- Do not let a catalog refresh restore stock already consumed by local orders since the last sync. Reconcile remote allocation data with local sales explicitly.
- Do not create or modify remote tables, views, functions, policies, grants, or migrations. The current migrations do not authorize order writes and do not define an order-submission RPC. Keep order submission local-only and clearly indicate that server upload is unavailable until an authorized server-side write path is provided; do not attempt direct inserts/upserts into `orders` or `order_items`.
- The remote schema does not persist sale-time prices or order totals, and `v_order_summaries` derives totals from current listing prices. Treat local SQLite as the financial source of truth for receipts, order history, and shift summaries.
- The current anon-read migration grants reads across public tables, including `bartenders.pin_hash`, profiles, and order history. This is a project-accepted but security-sensitive exposure, not a safe default to expand. Do not add broader access, expose hashes in UI, or log PINs/hashes. Keep offline PIN verification local and handle hash verification without logging input or stored hash values.

## Android and Input

- Declare `android.permission.INTERNET` for Supabase connectivity and `android.permission.CAMERA` for camera barcode scanning. Request and handle camera access at runtime, including denial/unavailable states.
- Do not request SQL, broad storage, or Bluetooth permissions. Bluetooth thermal printing is deferred; do not implement printer support unless the user changes scope.
- Lock Flutter orientation to portrait and preserve keyboard resizing behavior.
- Use the native Android software keyboard; do not create a custom numeric keypad or calculator.
- Configure every text field with an appropriate `keyboardType`, `inputFormatters`, `textInputAction`, and `autofocus` value. Use digit-only obscured numeric input for PINs; decimal numeric input with two-decimal filtering for amounts/prices/quantities; search-action text input for search/barcodes; phone input with digit filtering for phone numbers; and multiline/text input for notes.
- The register uses a compact two-column product grid, top search/scanner control, and persistent bottom cart bar. Checkout uses thumb-friendly controls and quick tender presets.

## Exceptions and Logging

- Use the Dart `logger` package for caught exceptions. Log useful operation context and the exception stack trace at service/repository boundaries; preserve error propagation or convert failures into explicit UI state rather than silently swallowing them.
- Never log credentials, anon keys, PIN input, PIN hashes, or sensitive customer data. Keep log messages free of raw records that may contain such values.

## Code Quality and Validation

- Do not create or run unit, widget, or integration tests unless the user explicitly changes this requirement.
- After Dart code changes, run `dart format .` followed by `flutter analyze`; fix reported analyzer issues before finishing.
- **Never build an APK as a validation step.** Do not run `flutter build apk` or another APK packaging/build command for validation. Only build an APK if the user explicitly asks for an APK deliverable.
- For documentation-only changes, validate the edited instructions without running Flutter build commands.