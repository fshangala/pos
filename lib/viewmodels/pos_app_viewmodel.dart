import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../repositories/local_catalog_repository.dart';
import '../repositories/sync_repository.dart';

class PosAppViewModel extends ChangeNotifier {
  PosAppViewModel({
    required LocalCatalogRepository catalogRepository,
    required this.configurationError,
    required SyncRepository? syncRepository,
    Logger? logger,
  }) : _catalogRepository = catalogRepository,
       _syncRepository = syncRepository,
       _logger = logger ?? Logger();

  final LocalCatalogRepository _catalogRepository;
  final SyncRepository? _syncRepository;
  final Logger _logger;
  final String? configurationError;

  bool isInitializing = true;
  bool isSyncingProfiles = false;
  bool canProceedToLogin = false;
  bool canContinueWithLocalBartenders = false;
  String? setupError;
  String? refreshMessage;

  Future<void> initialize() async {
    try {
      await refreshBartenderProfiles();
    } catch (error, stackTrace) {
      _logger.e(
        'POS startup could not load bartender profiles',
        error: error,
        stackTrace: stackTrace,
      );
      setupError = 'Unable to prepare saved bartender profiles.';
      canContinueWithLocalBartenders = await _catalogRepository
          .hasActiveBartenders();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshBartenderProfiles() async {
    isSyncingProfiles = true;
    setupError = null;
    refreshMessage = null;
    notifyListeners();
    try {
      final syncRepository = _syncRepository;
      if (syncRepository == null) {
        throw StateError(
          configurationError ?? 'Supabase configuration is unavailable.',
        );
      }
      await syncRepository.pullBartenders();
      canProceedToLogin = true;
      canContinueWithLocalBartenders = false;
      refreshMessage = 'Bartender profiles are up to date.';
    } catch (error, stackTrace) {
      _logger.e(
        'Bartender profile refresh failed; checking local profiles',
        error: error,
        stackTrace: stackTrace,
      );
      canContinueWithLocalBartenders = await _catalogRepository
          .hasActiveBartenders();
      setupError = canContinueWithLocalBartenders
          ? 'Could not connect to refresh bartender profiles.'
          : 'Could not connect and no saved bartender profiles are available.';
      canProceedToLogin = false;
    } finally {
      isSyncingProfiles = false;
      notifyListeners();
    }
  }

  void continueWithLocalBartenders() {
    if (!canContinueWithLocalBartenders) return;
    canProceedToLogin = true;
    setupError = null;
    refreshMessage = 'Continuing with bartender profiles saved on this device.';
    notifyListeners();
  }
}
