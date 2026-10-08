class CartItemModel {
  const CartItemModel({
    required this.listingId,
    required this.inventoryId,
    required this.inventoryName,
    required this.unitPrice,
    required this.availableUnits,
    required this.units,
  });

  final String listingId;
  final String inventoryId;
  final String inventoryName;
  final double unitPrice;
  final double availableUnits;
  final int units;

  double get subtotal => unitPrice * units;

  CartItemModel copyWith({int? units}) => CartItemModel(
    listingId: listingId,
    inventoryId: inventoryId,
    inventoryName: inventoryName,
    unitPrice: unitPrice,
    availableUnits: availableUnits,
    units: units ?? this.units,
  );
}
