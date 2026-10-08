import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../models/bartender_model.dart';
import '../models/counter_station_model.dart';
import '../repositories/local_auth_repository.dart';
import '../repositories/local_catalog_repository.dart';

class PosAuthViewModel extends ChangeNotifier {
  PosAuthViewModel({
    required LocalAuthRepository repository,
    required LocalCatalogRepository catalogRepository,
    Logger? logger,
  }) : _repository = repository,
       _catalogRepository = catalogRepository,
       _logger = logger ?? Logger();

  final LocalAuthRepository _repository;
  final LocalCatalogRepository _catalogRepository;
  final Logger _logger;

  List<BartenderModel> bartenders = [];
  List<CounterStationModel> stations = [];
  BartenderModel? bartender;
  CounterStationModel? station;
  bool isLoadingProfiles = false;
  bool isAuthenticating = false;
  String? errorMessage;

  bool get isAuthenticated => bartender != null && station != null;

  Future<void> loadProfiles() async {
    isLoadingProfiles = true;
    errorMessage = null;
    notifyListeners();
    try {
      bartenders = await _catalogRepository.getActiveBartenders();
      stations = await _catalogRepository.getStations();
      if (bartenders.isEmpty) {
        errorMessage = 'No active bartender profiles are available.';
      } else if (stations.isEmpty) {
        errorMessage = 'No active counter stations are available.';
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load local sign-in profiles',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Could not load saved bartender and counter details.';
    } finally {
      isLoadingProfiles = false;
      notifyListeners();
    }
  }

  Future<bool> authenticate({
    required String bartenderId,
    required String pin,
  }) async {
    isAuthenticating = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.authenticate(
        bartenderId: bartenderId,
        pin: pin,
      );
      if (result == null) {
        errorMessage = 'PIN is incorrect.';
        return false;
      }
      bartender = result;
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to verify bartender PIN locally',
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

  void selectStation(CounterStationModel selectedStation) {
    station = selectedStation;
    notifyListeners();
  }

  void signOut() {
    bartender = null;
    station = null;
    errorMessage = null;
    notifyListeners();
  }
}
