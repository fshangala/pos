class LocalOrderItemModel {
  const LocalOrderItemModel({
    required this.localItemId,
    required this.localOrderId,
    required this.inventoryId,
    required this.stockItemId,
    required this.listingId,
    required this.inventoryName,
    required this.unitPrice,
    required this.units,
    required this.subtotal,
  });

  final String localItemId;
  final String localOrderId;
  final String inventoryId;
  final String stockItemId;
  final String listingId;
  final String inventoryName;
  final double unitPrice;
  final int units;
  final double subtotal;

  Map<String, Object?> toMap() => {
    'local_item_id': localItemId,
    'local_order_id': localOrderId,
    'inventory_id': inventoryId,
    'stock_item_id': stockItemId,
    'listing_id': listingId,
    'inventory_name': inventoryName,
    'unit_price': unitPrice,
    'units': units,
    'subtotal': subtotal,
  };
}
