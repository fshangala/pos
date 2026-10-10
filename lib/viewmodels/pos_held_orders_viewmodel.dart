import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../models/local_order_model.dart';
import '../repositories/local_order_repository.dart';
import 'pos_register_viewmodel.dart';

class PosHeldOrdersViewModel extends ChangeNotifier {
  PosHeldOrdersViewModel({
    required LocalOrderRepository repository,
    required PosRegisterViewModel registerViewModel,
    Logger? logger,
  }) : _repository = repository,
       _registerViewModel = registerViewModel,
       _logger = logger ?? Logger();

  final LocalOrderRepository _repository;
  final PosRegisterViewModel _registerViewModel;
  final Logger _logger;

  List<LocalOrderModel> orders = [];
  bool isLoading = false;
  String? errorMessage;

  Future<bool> holdCurrentOrder({
    required String counterId,
    required String bartenderId,
  }) async {
    if (_registerViewModel.isCartEmpty) return false;
    try {
      await _repository.createHeldOrder(
        counterId: counterId,
        bartenderId: bartenderId,
        items: _registerViewModel.cart,
        notes: _registerViewModel.notes,
      );
      _registerViewModel.clearCart();
      errorMessage = null;
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to hold current order locally',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Could not save this held order on the device.';
      return false;
    }
  }

  Future<void> loadHeldOrders() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      orders = await _repository.getHeldOrders();
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load held orders',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Could not load held orders from this device.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resumeOrder(String orderId) async {
    if (!_registerViewModel.isCartEmpty) {
      errorMessage = 'Finish or hold the current cart before resuming another.';
      notifyListeners();
      return false;
    }
    try {
      final draft = await _repository.resumeHeldOrder(orderId);
      if (draft == null) {
        errorMessage = 'This held order is no longer available.';
        return false;
      }
      _registerViewModel.restoreCart(
        items: draft.items,
        notes: draft.order.notes,
      );
      orders.removeWhere((order) => order.localOrderId == orderId);
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to resume held order in register',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = error is InsufficientLocalStockException
          ? error.toString()
          : 'Could not resume this held order.';
      notifyListeners();
      return false;
    }
  }
}
