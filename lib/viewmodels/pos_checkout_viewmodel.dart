import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../models/local_order_model.dart';
import '../repositories/local_order_repository.dart';
import 'pos_register_viewmodel.dart';

class PosCheckoutViewModel extends ChangeNotifier {
  PosCheckoutViewModel({
    required LocalOrderRepository orderRepository,
    required PosRegisterViewModel registerViewModel,
    Logger? logger,
  }) : _orderRepository = orderRepository,
       _registerViewModel = registerViewModel,
       _logger = logger ?? Logger();

  final LocalOrderRepository _orderRepository;
  final PosRegisterViewModel _registerViewModel;
  final Logger _logger;

  String paymentType = 'CASH';
  double tenderedAmount = 0;
  bool isSaving = false;
  String? errorMessage;

  double get total => _registerViewModel.total;
  double get changeDue => (tenderedAmount - total).clamp(0, double.infinity);
  bool get canComplete =>
      !isSaving &&
      !_registerViewModel.isCartEmpty &&
      (paymentType == 'MOBILE_MONEY' || tenderedAmount >= total);

  void setPaymentType(String value) {
    paymentType = value;
    if (value == 'MOBILE_MONEY') tenderedAmount = 0;
    errorMessage = null;
    notifyListeners();
  }

  void setTenderedAmount(String value) {
    tenderedAmount = double.tryParse(value) ?? 0;
    notifyListeners();
  }

  void selectTenderPreset(double amount) {
    tenderedAmount = amount;
    notifyListeners();
  }

  void reset() {
    paymentType = 'CASH';
    tenderedAmount = 0;
    errorMessage = null;
    notifyListeners();
  }

  Future<LocalOrderModel?> completeOrder({
    required String counterId,
    required String bartenderId,
  }) async {
    if (!canComplete) return null;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final order = await _orderRepository.createCompletedOrder(
        counterId: counterId,
        bartenderId: bartenderId,
        paymentType: paymentType,
        items: _registerViewModel.cart,
        discountAmount: _registerViewModel.discountAmount,
        notes: _registerViewModel.notes,
      );
      _registerViewModel.clearCart();
      tenderedAmount = 0;
      return order;
    } catch (error, stackTrace) {
      _logger.e(
        'Checkout failed to save order to the local database',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Order was not saved. Check available stock and retry.';
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
