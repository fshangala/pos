import 'package:flutter/material.dart';

import '../../models/register_product_model.dart';

class PhoneProductTile extends StatelessWidget {
  const PhoneProductTile({
    required this.product,
    required this.onTap,
    super.key,
  });

  final RegisterProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStock = product.availableUnits >= 1;
    return Card(
      child: InkWell(
        onTap: hasStock ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    product.inventoryName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              if (product.barcode != null)
                Text(
                  product.barcode!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.price.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    hasStock ? '${product.availableUnits.floor()} left' : 'Out',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: hasStock
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.error,
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
