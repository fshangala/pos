class CounterStockAllocationModel {
  const CounterStockAllocationModel({
    required this.counterStockId,
    required this.counterId,
    required this.counterName,
    required this.stockItemId,
    required this.stockOrderId,
    required this.inventoryId,
    required this.inventoryName,
    required this.description,
    required this.listingId,
    required this.price,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedCounterId,
    required this.unitsSold,
    required this.outOfStock,
    required this.remoteRemainingUnits,
    required this.unitsPerQuantity,
    required this.totalAssignedUnits,
    required this.lowStockThreshold,
    required this.isLowStock,
    required this.syncedAt,
    this.barcode,
    this.localUnitsSold = 0,
  });

  final String counterStockId;
  final String counterId;
  final String counterName;
  final String stockItemId;
  final String? stockOrderId;
  final String inventoryId;
  final String inventoryName;
  final String? barcode;
  final String? description;
  final String? listingId;
  final double? price;
  final double quantity;
  final String createdAt;
  final String updatedAt;
  final String assignedCounterId;
  final double unitsSold;
  final bool outOfStock;
  final double remoteRemainingUnits;
  final double unitsPerQuantity;
  final double totalAssignedUnits;
  final double localUnitsSold;
  final double lowStockThreshold;
  final bool isLowStock;
  final String syncedAt;

  double get availableUnits =>
      (totalAssignedUnits - unitsSold).clamp(0, double.infinity).toDouble();

  factory CounterStockAllocationModel.fromCounterStockView(
    Map<String, dynamic> map, {
    required String counterName,
  }) {
    final unitsPerQuantity = (map['units_per_quantity'] as num).toDouble();
    final quantity = (map['quantity'] as num).toDouble();
    final assignedUnits = quantity * unitsPerQuantity;
    final unitsSold = (map['units_sold'] as num?)?.toDouble() ?? 0;
    final thresholdUnits =
        (map['low_stock_threshold'] as num).toDouble() * unitsPerQuantity;
    return CounterStockAllocationModel(
      counterStockId: map['id'] as String,
      counterId: map['counter_id'] as String,
      counterName: counterName,
      stockItemId: map['stock_item_id'] as String,
      stockOrderId: map['stock_order_id'] as String?,
      inventoryId: map['inventory_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      description: map['description'] as String?,
      listingId: map['listing_id'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      quantity: quantity,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      assignedCounterId: map['assigned_counter_id'] as String,
      unitsSold: unitsSold,
      outOfStock: map['out_of_stock'] as bool? ?? false,
      remoteRemainingUnits: assignedUnits,
      unitsPerQuantity: unitsPerQuantity,
      totalAssignedUnits: assignedUnits,
      lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
      isLowStock: (assignedUnits - unitsSold) <= thresholdUnits,
      syncedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  factory CounterStockAllocationModel.fromLocal(Map<String, Object?> map) {
    return CounterStockAllocationModel(
      counterStockId: map['counter_stock_id'] as String,
      counterId: map['counter_id'] as String,
      counterName: map['counter_name'] as String,
      stockItemId: map['stock_item_id'] as String,
      stockOrderId: map['stock_order_id'] as String?,
      inventoryId: map['inventory_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      description: map['description'] as String?,
      listingId: map['listing_id'] as String?,
      price: (map['price'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      assignedCounterId: map['assigned_counter_id'] as String,
      unitsSold: (map['units_sold'] as num).toDouble(),
      outOfStock: (map['out_of_stock'] as num) == 1,
      remoteRemainingUnits: (map['remote_remaining_units'] as num).toDouble(),
      unitsPerQuantity: (map['units_per_quantity'] as num).toDouble(),
      totalAssignedUnits: (map['total_assigned_units'] as num).toDouble(),
      localUnitsSold: (map['local_units_sold'] as num).toDouble(),
      lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
      isLowStock: (map['is_low_stock'] as num) == 1,
      syncedAt: map['synced_at'] as String,
    );
  }

  Map<String, Object?> toMap() => {
    'counter_stock_id': counterStockId,
    'id': counterStockId,
    'counter_id': counterId,
    'counter_name': counterName,
    'stock_item_id': stockItemId,
    'stock_order_id': stockOrderId,
    'inventory_id': inventoryId,
    'inventory_name': inventoryName,
    'barcode': barcode,
    'description': description,
    'listing_id': listingId,
    'price': price,
    'quantity': quantity,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'assigned_counter_id': assignedCounterId,
    'units_sold': unitsSold,
    'out_of_stock': outOfStock ? 1 : 0,
    'remote_remaining_units': remoteRemainingUnits,
    'units_per_quantity': unitsPerQuantity,
    'total_assigned_units': totalAssignedUnits,
    'local_units_sold': localUnitsSold,
    'low_stock_threshold': lowStockThreshold,
    'is_low_stock': isLowStock ? 1 : 0,
    'synced_at': syncedAt,
  };
}
