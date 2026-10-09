import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../models/bartender_model.dart';
import '../models/counter_station_model.dart';
import '../repositories/local_auth_repository.dart';
import '../repositories/local_catalog_repository.dart';
import '../repositories/sync_repository.dart';

class PosAuthViewModel extends ChangeNotifier {
  PosAuthViewModel({
    required LocalAuthRepository repository,
    required LocalCatalogRepository catalogRepository,
    required SyncRepository? syncRepository,
    Logger? logger,
  }) : _repository = repository,
       _catalogRepository = catalogRepository,
       _syncRepository = syncRepository,
       _logger = logger ?? Logger();

  final LocalAuthRepository _repository;
  final LocalCatalogRepository _catalogRepository;
  final SyncRepository? _syncRepository;
  final Logger _logger;

  List<BartenderModel> bartenders = [];
  BartenderModel? bartender;
  CounterStationModel? station;
  bool isLoadingProfiles = false;
  bool isAuthenticating = false;
  bool isRefreshingCounterData = false;
  String? errorMessage;
  String? counterDataMessage;

  bool get isAuthenticated => bartender != null && station != null;

  Future<void> loadProfiles() async {
    isLoadingProfiles = true;
    errorMessage = null;
    notifyListeners();
    try {
      bartenders = await _catalogRepository.getActiveBartenders();
      if (bartenders.isEmpty) {
        errorMessage = 'No active bartender profiles are available.';
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load local sign-in profiles',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Could not load saved bartender details.';
    } finally {
      isLoadingProfiles = false;
      notifyListeners();
    }
  }

  Future<bool> authenticate({
    required String phone,
    required String pin,
  }) async {
    isAuthenticating = true;
    errorMessage = null;
    counterDataMessage = null;
    notifyListeners();
    try {
      final result = await _repository.authenticate(phone: phone, pin: pin);
      if (result == null) {
        errorMessage = 'Phone number or PIN is incorrect.';
        return false;
      }
      final counterId = result.counterId;
      if (counterId == null || counterId.isEmpty) {
        errorMessage = 'This bartender does not have an assigned counter.';
        return false;
      }

      var usingCachedData = false;
      try {
        final syncRepository = _syncRepository;
        if (syncRepository == null) {
          throw StateError('Counter data service is unavailable.');
        }
        await syncRepository.pullCounterData(counterId);
      } catch (error, stackTrace) {
        _logger.e(
          'Unable to refresh the bartender assigned counter',
          error: error,
          stackTrace: stackTrace,
        );
        if (!await _catalogRepository.hasCounterCatalog(counterId)) {
          errorMessage =
              'Could not load this counter and no saved counter data is available. '
              'Reconnect and try again.';
          return false;
        }
        usingCachedData = true;
      }

      final assignedStation = await _catalogRepository.getStation(counterId);
      if (assignedStation == null) {
        errorMessage =
            'The assigned counter is not available in the saved data.';
        return false;
      }

      bartender = result;
      station = assignedStation;
      counterDataMessage = usingCachedData
          ? 'Could not refresh. Using this counter’s saved data.'
          : 'Counter data is up to date.';
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to verify bartender sign-in locally',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Unable to sign in. Try again.';
      return false;
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> refreshAssignedCounterData() async {
    final currentBartender = bartender;
    final currentStation = station;
    if (currentBartender == null || currentStation == null) return false;

    isRefreshingCounterData = true;
    errorMessage = null;
    notifyListeners();
    try {
      final syncRepository = _syncRepository;
      if (syncRepository == null) {
        throw StateError('Counter data service is unavailable.');
      }
      await syncRepository.pullCounterData(currentStation.id);
      counterDataMessage = 'Counter data is up to date.';
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'Assigned counter refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (await _catalogRepository.hasCounterCatalog(currentStation.id)) {
        counterDataMessage =
            'Could not refresh. Using this counter’s saved data.';
      } else {
        counterDataMessage =
            'Unable to load counter data. Reconnect and retry.';
      }
      return false;
    } finally {
      isRefreshingCounterData = false;
      notifyListeners();
    }
  }

  void signOut() {
    bartender = null;
    station = null;
    errorMessage = null;
    counterDataMessage = null;
    notifyListeners();
  }
}
