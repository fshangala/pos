import '../core/services/online_sync_service.dart';
import '../models/local_order_item_model.dart';
import '../models/local_order_model.dart';

class SyncRepository {
  SyncRepository(this._service);

  final OnlineSyncService _service;

  Future<void> pullBartenders() => _service.pullBartenders();

  Future<void> pullCounterData(String counterId) =>
      _service.pullCounterData(counterId);

  Future<void> submitCompletedOrder({
    required LocalOrderModel order,
    required List<LocalOrderItemModel> items,
  }) => _service.submitCompletedOrder(order: order, items: items);
}
