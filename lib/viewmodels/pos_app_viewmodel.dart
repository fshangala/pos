import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../core/services/local_db_service.dart';
import '../repositories/local_catalog_repository.dart';
import '../repositories/sync_repository.dart';

class PosAppViewModel extends ChangeNotifier {
  PosAppViewModel({
    required LocalDbService localDb,
    required LocalCatalogRepository catalogRepository,
    required SyncRepository? syncRepository,
    required this.configurationError,
    Logger? logger,
  }) : _localDb = localDb,
       _catalogRepository = catalogRepository,
       _syncRepository = syncRepository,
       _logger = logger ?? Logger();

  final LocalDbService _localDb;
  final LocalCatalogRepository _catalogRepository;
  final SyncRepository? _syncRepository;
  final Logger _logger;
  final String? configurationError;

  bool isInitializing = true;
  bool isSyncingCatalog = false;
  bool isCatalogReady = false;
  String? setupError;
  String? refreshMessage;

  bool get canUseCachedCatalog => isCatalogReady;

  Future<void> initialize() async {
    try {
      final previouslySynced = await _localDb.hasCompletedInitialSync;
      final hasCatalog = await _catalogRepository.hasCatalog();
      if (_syncRepository != null) {
        await refreshCatalog();
      } else if (!previouslySynced || !hasCatalog) {
        setupError =
            configurationError ??
            'Connect to the internet to complete initial catalog setup.';
      } else {
        refreshMessage = 'Using the catalog saved on this device.';
      }

      final initialSyncComplete = await _localDb.hasCompletedInitialSync;
      final catalogAvailable = await _catalogRepository.hasCatalog();
      isCatalogReady = initialSyncComplete && catalogAvailable;
      if (!isCatalogReady && setupError == null) {
        setupError = 'Initial catalog setup has not completed.';
      }
    } catch (error, stackTrace) {
      _logger.e(
        'POS startup could not prepare local catalog',
        error: error,
        stackTrace: stackTrace,
      );
      setupError = 'Unable to prepare the local POS database.';
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshCatalog() async {
    final syncRepository = _syncRepository;
    if (syncRepository == null) {
      refreshMessage =
          configurationError ?? 'Supabase configuration is missing.';
      notifyListeners();
      return;
    }

    isSyncingCatalog = true;
    setupError = null;
    notifyListeners();
    try {
      await syncRepository.pullCatalog();
      refreshMessage = 'Catalog is up to date.';
    } catch (error, stackTrace) {
      _logger.e(
        'Catalog refresh failed; checking for a usable local cache',
        error: error,
        stackTrace: stackTrace,
      );
      final previouslySynced = await _localDb.hasCompletedInitialSync;
      final hasCatalog = await _catalogRepository.hasCatalog();
      if (previouslySynced && hasCatalog) {
        refreshMessage = 'Could not refresh. Using the saved catalog.';
      } else {
        setupError =
            'Initial catalog setup failed. Check your connection and try again.';
      }
    } finally {
      isCatalogReady =
          await _localDb.hasCompletedInitialSync &&
          await _catalogRepository.hasCatalog();
      isSyncingCatalog = false;
      notifyListeners();
    }
  }
}
