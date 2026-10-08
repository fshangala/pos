import 'package:flutter/material.dart';

import '../../models/cart_item_model.dart';

class CartItemRow extends StatelessWidget {
  const CartItemRow({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
    super.key,
  });

  final CartItemModel item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

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
                Text(item.inventoryName, style: theme.textTheme.titleSmall),
                Text(
                  '${item.unitPrice.toStringAsFixed(2)} each',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecrement,
            tooltip: 'Decrease quantity',
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text('$item.units', textAlign: TextAlign.center),
          ),
          IconButton(
            onPressed: onIncrement,
            tooltip: 'Increase quantity',
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove item',
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}
