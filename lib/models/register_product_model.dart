class RegisterProductModel {
  const RegisterProductModel({
    required this.inventoryId,
    required this.listingId,
    required this.inventoryName,
    required this.price,
    required this.availableUnits,
    this.barcode,
  });

  final String inventoryId;
  final String listingId;
  final String inventoryName;
  final String? barcode;
  final double price;
  final double availableUnits;

  factory RegisterProductModel.fromMap(Map<String, Object?> map) {
    return RegisterProductModel(
      inventoryId: map['inventory_id'] as String,
      listingId: map['listing_id'] as String,
      inventoryName: map['inventory_name'] as String,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      availableUnits: (map['available_units'] as num).toDouble(),
    );
  }
}
