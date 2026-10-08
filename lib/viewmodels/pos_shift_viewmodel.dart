import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../models/local_order_model.dart';
import '../models/local_order_item_model.dart';
import '../models/shift_summary_model.dart';
import '../repositories/local_order_repository.dart';

class PosShiftViewModel extends ChangeNotifier {
  PosShiftViewModel({required LocalOrderRepository repository, Logger? logger})
    : _repository = repository,
      _logger = logger ?? Logger();

  final LocalOrderRepository _repository;
  final Logger _logger;

  List<LocalOrderModel> orders = [];
  ShiftSummaryModel? summary;
  bool isLoading = false;
  String? errorMessage;

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      orders = await _repository.getOrdersForToday();
      summary = await _repository.getTodaySummary();
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to refresh local shift information',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Could not load local order history.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<LocalOrderItemModel>> loadOrderItems(String orderId) async {
    try {
      return await _repository.getOrderItems(orderId);
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to load details for local order',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
