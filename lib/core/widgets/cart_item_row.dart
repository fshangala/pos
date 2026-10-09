import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/cart_item_model.dart';

class CartItemRow extends StatefulWidget {
  const CartItemRow({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSetQuantity,
    required this.onRemove,
    super.key,
  });

  final CartItemModel item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool Function(int quantity) onSetQuantity;
  final VoidCallback onRemove;

  @override
  State<CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<CartItemRow> {
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.units.toString(),
    );
  }

  @override
  void didUpdateWidget(CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.units != widget.item.units &&
        _quantityController.text != widget.item.units.toString()) {
      _quantityController.text = widget.item.units.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submitQuantity(String value) {
    final quantity = int.tryParse(value);
    if (quantity == null || !widget.onSetQuantity(quantity)) {
      _quantityController.text = widget.item.units.toString();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Quantity must be between 0 and '
              '${widget.item.availableUnits.floor()}.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.inventoryName,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${widget.item.unitPrice.toStringAsFixed(2)} each',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onDecrement,
            tooltip: 'Decrease quantity',
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 48,
            child: TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              onSubmitted: _submitQuantity,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          IconButton(
            onPressed: widget.item.units >= widget.item.availableUnits.floor()
                ? null
                : widget.onIncrement,
            tooltip: 'Increase quantity',
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            onPressed: widget.onRemove,
            tooltip: 'Remove item',
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}
