class CounterStockAllocationModel {
  const CounterStockAllocationModel({
    required this.counterStockId,
    required this.counterId,
    required this.counterName,
    required this.stockItemId,
    required this.inventoryId,
    required this.inventoryName,
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
  final String inventoryId;
  final String inventoryName;
  final String? barcode;
  final double remoteRemainingUnits;
  final double unitsPerQuantity;
  final double totalAssignedUnits;
  final double localUnitsSold;
  final double lowStockThreshold;
  final bool isLowStock;
  final String syncedAt;

  double get availableUnits =>
      (remoteRemainingUnits - localUnitsSold).clamp(0, double.infinity);

  factory CounterStockAllocationModel.fromRemote(Map<String, dynamic> map) {
    return CounterStockAllocationModel(
      counterStockId: map['counter_stock_id'] as String,
      counterId: map['counter_id'] as String,
      counterName: map['counter_name'] as String,
      stockItemId: map['stock_item_id'] as String,
      inventoryId: map['inventory_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      remoteRemainingUnits: (map['remaining_units'] as num).toDouble(),
      unitsPerQuantity: (map['units_per_quantity'] as num).toDouble(),
      totalAssignedUnits: (map['total_assigned_units'] as num).toDouble(),
      lowStockThreshold: (map['low_stock_threshold_units'] as num).toDouble(),
      isLowStock: map['is_low_stock'] as bool,
      syncedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  factory CounterStockAllocationModel.fromLocal(Map<String, Object?> map) {
    return CounterStockAllocationModel(
      counterStockId: map['counter_stock_id'] as String,
      counterId: map['counter_id'] as String,
      counterName: map['counter_name'] as String,
      stockItemId: map['stock_item_id'] as String,
      inventoryId: map['inventory_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
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
    'counter_id': counterId,
    'counter_name': counterName,
    'stock_item_id': stockItemId,
    'inventory_id': inventoryId,
    'inventory_name': inventoryName,
    'barcode': barcode,
    'remote_remaining_units': remoteRemainingUnits,
    'units_per_quantity': unitsPerQuantity,
    'total_assigned_units': totalAssignedUnits,
    'local_units_sold': localUnitsSold,
    'low_stock_threshold': lowStockThreshold,
    'is_low_stock': isLowStock ? 1 : 0,
    'synced_at': syncedAt,
  };
}
