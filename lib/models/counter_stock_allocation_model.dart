class CounterStockAllocationModel {
  const CounterStockAllocationModel({
    required this.id,
    required this.counterId,
    required this.counterName,
    required this.stockItemId,
    required this.stockOrderId,
    required this.inventoryId,
    required this.unitsPerQuantity,
    required this.inventoryName,
    required this.barcode,
    required this.description,
    required this.listingId,
    required this.price,
    required this.quantity,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedCounterId,
    required this.unitsSold,
    required this.outOfStock,
    required this.syncedAt,
  });

  final String id;
  final String counterId;
  final String counterName;
  final String stockItemId;
  final String? stockOrderId;
  final String inventoryId;
  final double unitsPerQuantity;
  final String inventoryName;
  final String? barcode;
  final String? description;
  final String? listingId;
  final double? price;
  final double quantity;
  final double lowStockThreshold;
  final String createdAt;
  final String updatedAt;
  final String assignedCounterId;
  final double unitsSold;
  final bool outOfStock;
  final String syncedAt;

  double get availableUnits => (quantity * unitsPerQuantity - unitsSold)
      .clamp(0, double.infinity)
      .toDouble();

  factory CounterStockAllocationModel.fromCounterStockView(
    Map<String, dynamic> map, {
    required String counterName,
  }) {
    return CounterStockAllocationModel(
      id: map['id'] as String,
      counterId: map['counter_id'] as String,
      counterName: counterName,
      stockItemId: map['stock_item_id'] as String,
      stockOrderId: map['stock_order_id'] as String?,
      inventoryId: map['inventory_id'] as String,
      unitsPerQuantity: (map['units_per_quantity'] as num).toDouble(),
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      description: map['description'] as String?,
      listingId: map['listing_id'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      assignedCounterId: map['assigned_counter_id'] as String,
      unitsSold: (map['units_sold'] as num?)?.toDouble() ?? 0,
      outOfStock: map['out_of_stock'] as bool? ?? false,
      syncedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'counter_id': counterId,
    'counter_name': counterName,
    'stock_item_id': stockItemId,
    'stock_order_id': stockOrderId,
    'inventory_id': inventoryId,
    'units_per_quantity': unitsPerQuantity,
    'inventory_name': inventoryName,
    'barcode': barcode,
    'description': description,
    'listing_id': listingId,
    'price': price,
    'quantity': quantity,
    'low_stock_threshold': lowStockThreshold,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'assigned_counter_id': assignedCounterId,
    'units_sold': unitsSold,
    'out_of_stock': outOfStock ? 1 : 0,
    'synced_at': syncedAt,
  };
}
