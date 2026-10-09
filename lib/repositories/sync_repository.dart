import '../core/services/online_sync_service.dart';

class SyncRepository {
  SyncRepository(this._service);

  final OnlineSyncService _service;

  Future<void> pullBartenders() => _service.pullBartenders();

  Future<void> pullCounterData(String counterId) =>
      _service.pullCounterData(counterId);
}
