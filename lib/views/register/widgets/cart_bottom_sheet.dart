import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/cart_item_row.dart';
import '../../../core/widgets/pos_button.dart';
import '../../../core/widgets/pos_text_field.dart';
import '../../../viewmodels/pos_held_orders_viewmodel.dart';
import '../../../viewmodels/pos_register_viewmodel.dart';

enum CartSheetResult { checkout, held }

Future<CartSheetResult?> showCartBottomSheet(
  BuildContext context, {
  required String counterId,
  required String bartenderId,
}) {
  return showModalBottomSheet<CartSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        CartBottomSheet(counterId: counterId, bartenderId: bartenderId),
  );
}

class CartBottomSheet extends StatefulWidget {
  const CartBottomSheet({
    required this.counterId,
    required this.bartenderId,
    super.key,
  });

  final String counterId;
  final String bartenderId;

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _didInitializeFields = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitializeFields) {
      _didInitializeFields = true;
      final viewModel = context.read<PosRegisterViewModel>();
      _discountController.text = viewModel.discountAmount == 0
          ? ''
          : viewModel.discountAmount.toStringAsFixed(2);
      _notesController.text = viewModel.notes;
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heldOrders = context.watch<PosHeldOrdersViewModel>();
    return Consumer<PosRegisterViewModel>(
      builder: (context, viewModel, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Current order', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (heldOrders.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    heldOrders.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: viewModel.cart.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = viewModel.cart[index];
                    return CartItemRow(
                      item: item,
                      onDecrement: () =>
                          viewModel.changeQuantity(item.inventoryId, -1),
                      onIncrement: () =>
                          viewModel.changeQuantity(item.inventoryId, 1),
                      onRemove: () => viewModel.removeItem(item.inventoryId),
                    );
                  },
                ),
              ),
              PosTextField(
                controller: _discountController,
                label: 'Order discount',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                textInputAction: TextInputAction.done,
                autofocus: false,
                onChanged: viewModel.setDiscountAmount,
              ),
              const SizedBox(height: 10),
              PosTextField(
                controller: _notesController,
                label: 'Order notes',
                keyboardType: TextInputType.multiline,
                inputFormatters: const [],
                textInputAction: TextInputAction.newline,
                autofocus: false,
                maxLines: 2,
                onChanged: viewModel.setNotes,
              ),
              const SizedBox(height: 10),
              const Divider(),
              Row(
                children: [
                  const Expanded(child: Text('Subtotal')),
                  Text(viewModel.subtotal.toStringAsFixed(2)),
                ],
              ),
              if (viewModel.discountAmount > 0)
                Row(
                  children: [
                    const Expanded(child: Text('Discount')),
                    Text('-${viewModel.discountAmount.toStringAsFixed(2)}'),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: Text('Total', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    viewModel.total.toStringAsFixed(2),
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isCartEmpty || heldOrders.isLoading
                          ? null
                          : () async {
                              final saved = await heldOrders.holdCurrentOrder(
                                counterId: widget.counterId,
                                bartenderId: widget.bartenderId,
                              );
                              if (saved && context.mounted) {
                                Navigator.of(context).pop(CartSheetResult.held);
                              }
                            },
                      icon: const Icon(Icons.pause_circle_outline_rounded),
                      label: const Text('Hold'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PosButton(
                      label: 'Proceed to pay',
                      icon: Icons.arrow_forward_rounded,
                      enabled: !viewModel.isCartEmpty,
                      onPressed: () =>
                          Navigator.of(context).pop(CartSheetResult.checkout),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
