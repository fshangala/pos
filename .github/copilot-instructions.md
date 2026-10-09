# POS Project Instructions

## Product and Architecture

- Build a native Flutter POS for Android smartphones in strict portrait orientation, optimized for one-handed use on 5.5- to 6.7-inch screens.
- Use Provider with MVVM. Views depend on `ChangeNotifier` ViewModels; ViewModels depend on repositories; repositories access SQLite or remote services. Keep each model and each ViewModel in its own file.
- Keep local checkout authoritative and usable offline. Persist a completed order locally before any network action.
- Keep shared UI in `lib/core/widgets/`, app styling in `lib/core/theme/pos_theme.dart`, and style widgets through `Theme.of(context)` and its color scheme/text theme.
- Prefer focused changes and existing project conventions.

## Startup, Profiles, and Login

- Load Supabase settings from the root `.env` using `flutter_dotenv`; list the asset in `pubspec.yaml`. Maintain `.env.example` with placeholders, never real credentials.
- Validate configuration and handle missing/unreadable settings with a visible setup/error state instead of force-unwrapping missing values or crashing.
- Initialize Flutter bindings, environment configuration, Supabase when configured, portrait orientation, local SQLite, and providers in a deliberate startup sequence.
- On app startup, fetch active bartender profiles and insert/update them in the local `local_bartenders` table. Do not erase a usable local profile cache when the online fetch fails.
- If profile sync fails, offer retry and continuing with existing local data. Allow local continuation only when cached profiles are available; otherwise keep recovery explicit.
- Sign bartenders in using phone number and PIN, verified locally against the cached bcrypt hash. After login, use the bartender's assigned `counter_id`; do not ask them to choose a different counter.
- After sign-in, fetch that assigned counter's catalog and stock. If the fetch fails, proceed using the assigned counter's local cache when available and clearly communicate cached/offline mode. If no assigned-counter cache exists, show an explicit recoverable error.
- Keep an in-POS action for refreshing data scoped to the signed-in bartender's assigned counter.
- Treat the Supabase anon key as a public client key, not a secret. Never log it or other credentials.

## Local Data and Supabase

- Use app-private SQLite (`pos_local.db`) for catalog cache, counter stations, bartenders, local orders, and order items. SQLite requires no Android manifest permission.
- Perform order totals, tender calculations, order persistence, and local stock decrements locally and transactionally. Keep stable local UUIDs, sale-time unit prices/subtotals, total amount, item count, and `PENDING`/`SYNCED`/`FAILED` state in local records.
- Use `v_counter_stock` as the source for assigned counter stock and associated listing fields; always filter by the signed-in bartender's `counter_id`. Keep one downloaded `local_counter_stock_cache` and a `local_v_counter_stock` view that adds locally completed POS order units to remote `units_sold` and recalculates `out_of_stock`. Do not keep a separate local listings table.
- Treat downloaded stock rows as read-only source data: refresh them from Supabase, do not invent or locally modify stock assignments or persist derived local sales into the source cache. Local POS orders are the only locally authored business data.
- Use the local counter-stock view for product availability and barcode lookup. Barcode scans and product selection must not add out-of-stock items; cart quantity changes must not exceed locally available units.
- Do not create or modify remote tables, views, functions, policies, grants, or migrations. The current migrations do not authorize order writes and do not define an order-submission RPC. Keep order submission local-only and clearly indicate that server upload is unavailable until an authorized server-side write path is provided; do not attempt direct inserts/upserts into `orders` or `order_items`.
- The remote schema does not persist sale-time prices or order totals, and `v_order_summaries` derives totals from current listing prices. Treat local SQLite as the financial source of truth for receipts, order history, and shift summaries.
- The current anon-read migration grants reads across public tables, including `bartenders.pin_hash`, profiles, and order history. This is a project-accepted but security-sensitive exposure, not a safe default to expand. Do not add broader access, expose hashes in UI, or log PINs/hashes. Keep offline PIN verification local and handle hash verification without logging input or stored hash values.

## Android and Input

- Declare `android.permission.INTERNET` for Supabase connectivity and `android.permission.CAMERA` for camera barcode scanning. Request and handle camera access at runtime, including denial/unavailable states.
- Do not request SQL, broad storage, or Bluetooth permissions. Bluetooth thermal printing is deferred; do not implement printer support unless the user changes scope.
- Lock Flutter orientation to portrait and preserve keyboard resizing behavior.
- Use the native Android software keyboard; do not create a custom numeric keypad or calculator.
- Configure every text field with an appropriate `keyboardType`, `inputFormatters`, `textInputAction`, and `autofocus` value. Use digit-only obscured numeric input for PINs, digit-only integer input for unit counts, decimal numeric input with two-decimal filtering for amounts/prices, search-action text input for product/barcode search, phone input with digit filtering for phone numbers, and multiline/text input for notes.
- The register uses a compact two-column product grid, selectable filtered name search results, direct barcode lookup, and a persistent bottom cart bar. Checkout uses thumb-friendly controls and quick tender presets.

## Exceptions and Logging

- Use the Dart `logger` package for caught exceptions. Log useful operation context and the exception stack trace at service/repository boundaries; preserve error propagation or convert failures into explicit UI state rather than silently swallowing them.
- Never log credentials, anon keys, PIN input, PIN hashes, or sensitive customer data. Keep log messages free of raw records that may contain such values.

## Code Quality and Validation

- Do not create or run unit, widget, or integration tests unless the user explicitly changes this requirement.
- After Dart code changes, run `dart format .` followed by `flutter analyze`; fix reported analyzer issues before finishing.
- **Never build an APK as a validation step.** Do not run `flutter build apk` or another APK packaging/build command for validation. Only build an APK if the user explicitly asks for an APK deliverable.
- For documentation-only changes, validate the edited instructions without running Flutter build commands.
