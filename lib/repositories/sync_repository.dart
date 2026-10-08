import '../core/services/online_sync_service.dart';

class SyncRepository {
  SyncRepository(this._service);

  final OnlineSyncService _service;

  Future<void> pullCatalog() => _service.pullOnlineCatalogData();
}
