import 'package:logger/logger.dart';

import 'local_order_repository.dart';
import 'sync_repository.dart';

class OrderSubmissionRepository {
  OrderSubmissionRepository({
    required LocalOrderRepository localOrderRepository,
    required SyncRepository? syncRepository,
    Logger? logger,
  }) : _localOrderRepository = localOrderRepository,
       _syncRepository = syncRepository,
       _logger = logger ?? Logger();

  final LocalOrderRepository _localOrderRepository;
  final SyncRepository? _syncRepository;
  final Logger _logger;

  static const uploadErrorMessage =
      'Upload failed. Check the connection or server permissions, then retry.';

  Future<bool> submitCompletedOrder(String orderId) async {
    try {
      final order = await _localOrderRepository.getOrder(orderId);
      if (order == null || order.status != 'COMPLETED') {
        throw StateError('Completed local order is unavailable for upload.');
      }
      final items = await _localOrderRepository.getOrderItems(orderId);
      final syncRepository = _syncRepository;
      if (syncRepository == null) {
        throw StateError('The remote order service is unavailable.');
      }
      await syncRepository.submitCompletedOrder(order: order, items: items);
      await _localOrderRepository.updateSubmissionStatus(
        orderId: orderId,
        status: 'SYNCED',
        remoteOrderId: orderId,
      );
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'Unable to submit completed local order $orderId',
        error: error,
        stackTrace: stackTrace,
      );
      await _localOrderRepository.updateSubmissionStatus(
        orderId: orderId,
        status: 'FAILED',
        errorMessage: uploadErrorMessage,
      );
      return false;
    }
  }
}
