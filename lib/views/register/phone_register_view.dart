import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/phone_product_tile.dart';
import '../../core/widgets/pos_search_bar.dart';
import '../../core/widgets/pos_sign_out_button.dart';
import '../../core/widgets/sticky_bottom_cart_bar.dart';
import '../../viewmodels/pos_auth_viewmodel.dart';
import '../../viewmodels/pos_register_viewmodel.dart';
import '../checkout/phone_checkout_view.dart';
import 'widgets/barcode_scanner_modal.dart';
import 'widgets/cart_bottom_sheet.dart';
import 'widgets/held_orders_modal.dart';

class PhoneRegisterView extends StatefulWidget {
  const PhoneRegisterView({
    required this.counterId,
    required this.bartenderId,
    super.key,
  });

  final String counterId;
  final String bartenderId;

  @override
  State<PhoneRegisterView> createState() => _PhoneRegisterViewState();
}

class _PhoneRegisterViewState extends State<PhoneRegisterView> {
  bool _didLoadCatalog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadCatalog) {
      _didLoadCatalog = true;
      context.read<PosRegisterViewModel>().loadProducts(widget.counterId);
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await showBarcodeScannerModal(context);
    if (!mounted || barcode == null) return;
    final viewModel = context.read<PosRegisterViewModel>();
    final product = await viewModel.lookupBarcode(widget.counterId, barcode);
    if (!mounted) return;
    if (product == null) {
      _showMessage(
        viewModel.errorMessage ?? 'No available product matches this barcode.',
      );
    } else if (!viewModel.addProduct(product)) {
      _showMessage('There is not enough local stock for this item.');
    } else {
      _showMessage('${product.inventoryName} added to the order.');
    }
  }

  Future<void> _openCart() async {
    final result = await showCartBottomSheet(
      context,
      counterId: widget.counterId,
      bartenderId: widget.bartenderId,
    );
    if (!mounted || result == null) return;
    if (result == CartSheetResult.held) {
      _showMessage('Order held on this device.');
      return;
    }
    final checkoutResult = await Navigator.of(context).push<CheckoutResult>(
      MaterialPageRoute(
        builder: (_) => PhoneCheckoutView(
          counterId: widget.counterId,
          bartenderId: widget.bartenderId,
        ),
      ),
    );
    if (!mounted || checkoutResult == null) return;
    await context.read<PosRegisterViewModel>().loadProducts(widget.counterId);
    if (!mounted) return;
    _showMessage(
      checkoutResult == CheckoutResult.uploaded
          ? 'Order saved and uploaded.'
          : 'Order saved on this device. Upload failed; retry from Orders.',
    );
  }

  Future<void> _openHeldOrders() async {
    final resumed = await showHeldOrdersModal(context);
    if (!mounted || !resumed) return;
    _showMessage('Held order resumed. Check stock before checkout.');
  }

  Future<void> _refreshCounterData() async {
    final authViewModel = context.read<PosAuthViewModel>();
    await authViewModel.refreshAssignedCounterData();
    if (!mounted) return;
    await context.read<PosRegisterViewModel>().loadProducts(widget.counterId);
    if (!mounted) return;
    final message = authViewModel.counterDataMessage;
    if (message != null) _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = context.watch<PosAuthViewModel>();
    return Consumer<PosRegisterViewModel>(
      builder: (context, viewModel, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Register'),
          actions: [
            IconButton(
              tooltip: 'Held orders',
              onPressed: _openHeldOrders,
              icon: const Icon(Icons.pause_circle_outline_rounded),
            ),
            IconButton(
              tooltip: 'Refresh this counter',
              onPressed: authViewModel.isRefreshingCounterData
                  ? null
                  : _refreshCounterData,
              icon: authViewModel.isRefreshingCounterData
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            const PosSignOutButton(),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: PosSearchBar(
                onChanged: viewModel.setSearchQuery,
                onScan: _scanBarcode,
              ),
            ),
            if (authViewModel.counterDataMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    authViewModel.counterDataMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  viewModel.errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          viewModel.hasSearchQuery
                              ? 'No matching products.'
                              : 'No sellable products are available at this counter.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : viewModel.hasSearchQuery
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: viewModel.products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final product = viewModel.products[index];
                        final canAdd = viewModel.canAddProduct(product);
                        final hasStock = product.availableUnits >= 1;
                        return Card(
                          child: ListTile(
                            title: Text(product.inventoryName),
                            subtitle: Text(
                              '${product.price.toStringAsFixed(2)}'
                              '${product.barcode == null ? '' : ' • ${product.barcode}'}',
                            ),
                            trailing: Text(
                              hasStock
                                  ? canAdd
                                        ? '${product.availableUnits.floor()} left'
                                        : 'Limit reached'
                                  : 'Out of stock',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: canAdd
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.error,
                              ),
                            ),
                            enabled: canAdd,
                            onTap: () {
                              viewModel.addProduct(product);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        );
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: viewModel.products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.86,
                          ),
                      itemBuilder: (context, index) {
                        final product = viewModel.products[index];
                        return PhoneProductTile(
                          product: product,
                          onTap: () {
                            if (!viewModel.addProduct(product)) {
                              _showMessage(
                                'There is not enough local stock for this item.',
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: StickyBottomCartBar(
          itemCount: viewModel.itemCount,
          total: viewModel.total,
          onTap: _openCart,
        ),
      ),
    );
  }
}
