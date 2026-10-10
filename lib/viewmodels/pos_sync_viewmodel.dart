import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../repositories/local_order_repository.dart';
import '../repositories/order_submission_repository.dart';

class PosSyncViewModel extends ChangeNotifier {
  PosSyncViewModel({
    required LocalOrderRepository localOrderRepository,
    required OrderSubmissionRepository submissionRepository,
    Logger? logger,
  }) : _localOrderRepository = localOrderRepository,
       _submissionRepository = submissionRepository,
       _logger = logger ?? Logger();

  final LocalOrderRepository _localOrderRepository;
  final OrderSubmissionRepository _submissionRepository;
  final Logger _logger;

  String message =
      'Orders are saved on this device first. Retry failed uploads from Orders.';
  bool isRetryingOrders = false;

  Future<void> retryPendingOrders() async {
    if (isRetryingOrders) return;
    isRetryingOrders = true;
    notifyListeners();
    try {
      final orders = await _localOrderRepository.getOrdersAwaitingSubmission();
      if (orders.isEmpty) {
        message = 'No completed orders are waiting to upload.';
        return;
      }

      var uploaded = 0;
      for (final order in orders) {
        if (await _submissionRepository.submitCompletedOrder(
          order.localOrderId,
        )) {
          uploaded++;
        }
      }
      final failed = orders.length - uploaded;
      message = failed == 0
          ? 'Uploaded $uploaded ${uploaded == 1 ? 'order' : 'orders'}.'
          : 'Uploaded $uploaded of ${orders.length} orders. '
                '$failed ${failed == 1 ? 'upload needs' : 'uploads need'} '
                'another retry.';
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to retry completed order uploads',
        error: error,
        stackTrace: stackTrace,
      );
      message = 'Could not check saved orders. Try again.';
    } finally {
      isRetryingOrders = false;
      notifyListeners();
    }
  }
}
