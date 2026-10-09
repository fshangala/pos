class ActiveListingModel {
  const ActiveListingModel({
    required this.listingId,
    required this.inventoryId,
    required this.inventoryName,
    required this.price,
    required this.active,
    required this.syncedAt,
    this.barcode,
  });

  final String listingId;
  final String inventoryId;
  final String inventoryName;
  final String? barcode;
  final double price;
  final bool active;
  final String syncedAt;

  factory ActiveListingModel.fromRemote(Map<String, dynamic> map) {
    return ActiveListingModel(
      listingId: map['listing_id'] as String,
      inventoryId: map['inventory_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      active: map['active'] as bool? ?? true,
      syncedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  factory ActiveListingModel.fromCounterStockView(Map<String, dynamic> map) {
    return ActiveListingModel(
      listingId: map['listing_id'] as String,
      inventoryId: map['inventory_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      active: true,
      syncedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  factory ActiveListingModel.fromLocal(Map<String, Object?> map) {
    return ActiveListingModel(
      listingId: map['listing_id'] as String,
      inventoryId: map['inventory_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      active: (map['active'] as num) == 1,
      syncedAt: map['synced_at'] as String,
    );
  }

  Map<String, Object?> toMap() => {
    'listing_id': listingId,
    'inventory_id': inventoryId,
    'inventory_name': inventoryName,
    'barcode': barcode,
    'price': price,
    'active': active ? 1 : 0,
    'synced_at': syncedAt,
  };
}
