import 'package:flutter/material.dart';

class StickyBottomCartBar extends StatelessWidget {
  const StickyBottomCartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
    super.key,
  });

  final int itemCount;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$itemCount items', style: theme.textTheme.labelLarge),
                    Text(
                      total.toStringAsFixed(2),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: itemCount == 0 ? null : onTap,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('View cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
