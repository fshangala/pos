import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../models/cart_item_model.dart';
import '../models/register_product_model.dart';
import '../repositories/local_catalog_repository.dart';

class PosRegisterViewModel extends ChangeNotifier {
  PosRegisterViewModel({
    required LocalCatalogRepository repository,
    Logger? logger,
  }) : _repository = repository,
       _logger = logger ?? Logger();

  final LocalCatalogRepository _repository;
  final Logger _logger;
  final Map<String, CartItemModel> _cart = {};

  List<RegisterProductModel> _products = [];
  String _query = '';
  double discountAmount = 0;
  String notes = '';
  bool isLoading = false;
  String? errorMessage;

  List<RegisterProductModel> get products => _products
      .where(
        (product) =>
            product.inventoryName.toLowerCase().contains(_query) ||
            (product.barcode?.toLowerCase().contains(_query) ?? false),
      )
      .toList(growable: false);
  List<CartItemModel> get cart => _cart.values.toList(growable: false);
  int get itemCount => _cart.values.fold(0, (sum, item) => sum + item.units);
  double get subtotal =>
      _cart.values.fold(0, (sum, item) => sum + item.subtotal);
  double get total => (subtotal - discountAmount).clamp(0, double.infinity);
  bool get isCartEmpty => _cart.isEmpty;

  Future<void> loadProducts(String counterId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _products = await _repository.getProducts(counterId);
    } catch (error, stackTrace) {
      _logger.e(
        'Register could not load catalog',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Could not load products from this device.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  RegisterProductModel? findByBarcode(String barcode) {
    for (final product in _products) {
      if (product.barcode == barcode) return product;
    }
    return null;
  }

  bool addProduct(RegisterProductModel product) {
    if (product.availableUnits < 1) return false;
    final current = _cart[product.inventoryId];
    final nextUnits = (current?.units ?? 0) + 1;
    if (nextUnits > product.availableUnits.floor()) return false;
    _cart[product.inventoryId] = CartItemModel(
      listingId: product.listingId,
      inventoryId: product.inventoryId,
      inventoryName: product.inventoryName,
      unitPrice: product.price,
      availableUnits: product.availableUnits,
      units: nextUnits,
    );
    notifyListeners();
    return true;
  }

  bool changeQuantity(String inventoryId, int difference) {
    final item = _cart[inventoryId];
    if (item == null) return false;
    final nextUnits = item.units + difference;
    if (nextUnits <= 0) {
      _cart.remove(inventoryId);
    } else if (nextUnits > item.availableUnits.floor()) {
      return false;
    } else {
      _cart[inventoryId] = item.copyWith(units: nextUnits);
    }
    notifyListeners();
    return true;
  }

  void removeItem(String inventoryId) {
    _cart.remove(inventoryId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    discountAmount = 0;
    notes = '';
    notifyListeners();
  }

  void restoreCart({
    required List<CartItemModel> items,
    required double discountAmount,
    required String? notes,
  }) {
    _cart
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.inventoryId, item)));
    this.discountAmount = discountAmount.clamp(0, subtotal);
    this.notes = notes ?? '';
    notifyListeners();
  }

  void setDiscountAmount(String value) {
    final discount = double.tryParse(value) ?? 0;
    discountAmount = discount.clamp(0, subtotal);
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }
}
