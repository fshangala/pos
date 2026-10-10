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
  bool get hasSearchQuery => _query.isNotEmpty;
  List<CartItemModel> get cart => _cart.values.toList(growable: false);
  int get itemCount => _cart.values.fold(0, (sum, item) => sum + item.units);
  double get subtotal =>
      _cart.values.fold(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal;
  bool get isCartEmpty => _cart.isEmpty;

  Future<void> loadProducts(String counterId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _products = await _repository.getProducts(counterId);
      final productsByInventory = {
        for (final product in _products) product.inventoryId: product,
      };
      for (final entry in _cart.entries.toList()) {
        final product = productsByInventory[entry.key];
        _cart[entry.key] = entry.value.copyWith(
          availableUnits: product?.availableUnits ?? 0,
        );
      }
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

  Future<RegisterProductModel?> lookupBarcode(
    String counterId,
    String barcode,
  ) async {
    errorMessage = null;
    try {
      return await _repository.getProductByBarcode(counterId, barcode);
    } catch (error, stackTrace) {
      _logger.e(
        'Barcode lookup failed for the assigned counter',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage = 'Could not look up this barcode in saved counter stock.';
      notifyListeners();
      return null;
    }
  }

  bool canAddProduct(RegisterProductModel product) {
    final currentUnits = _cart[product.inventoryId]?.units ?? 0;
    return product.availableUnits >= 1 &&
        currentUnits < product.availableUnits.floor();
  }

  bool addProduct(RegisterProductModel product) {
    if (!canAddProduct(product)) return false;
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

  bool setQuantity(String inventoryId, int quantity) {
    final item = _cart[inventoryId];
    if (item == null || quantity < 0) return false;
    if (quantity == 0) {
      _cart.remove(inventoryId);
    } else if (quantity > item.availableUnits.floor()) {
      return false;
    } else {
      _cart[inventoryId] = item.copyWith(units: quantity);
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
    notes = '';
    notifyListeners();
  }

  void restoreCart({
    required List<CartItemModel> items,
    required String? notes,
  }) {
    _cart
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.inventoryId, item)));
    this.notes = notes ?? '';
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }
}
