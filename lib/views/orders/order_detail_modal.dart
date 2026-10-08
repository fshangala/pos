import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/sync_status_chip.dart';
import '../../models/local_order_item_model.dart';
import '../../models/local_order_model.dart';
import '../../viewmodels/pos_shift_viewmodel.dart';

Future<void> showOrderDetailModal(BuildContext context, LocalOrderModel order) {
  final itemsFuture = context.read<PosShiftViewModel>().loadOrderItems(
    order.localOrderId,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => OrderDetailModal(order: order, itemsFuture: itemsFuture),
  );
}

class OrderDetailModal extends StatelessWidget {
  const OrderDetailModal({
    required this.order,
    required this.itemsFuture,
    super.key,
  });

  final LocalOrderModel order;
  final Future<List<LocalOrderItemModel>> itemsFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order details',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                SyncStatusChip(status: order.syncStatus),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.paymentType.replaceAll('_', ' ')} · '
              '${DateTime.parse(order.createdAt).toLocal()}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<LocalOrderItemModel>>(
                future: itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load saved order details.'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.inventoryName),
                        subtitle: Text(
                          '${item.units} × ${item.unitPrice.toStringAsFixed(2)}',
                        ),
                        trailing: Text(item.subtotal.toStringAsFixed(2)),
                      );
                    },
                  );
                },
              ),
            ),
            if (order.notes?.isNotEmpty ?? false) ...[
              const Divider(),
              Text('Notes', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(order.notes!),
            ],
            const Divider(),
            if (order.discountAmount > 0)
              _AmountRow(
                label: 'Subtotal',
                value: order.totalAmount + order.discountAmount,
              ),
            if (order.discountAmount > 0)
              _AmountRow(label: 'Discount', value: -order.discountAmount),
            _AmountRow(
              label: 'Total',
              value: order.totalAmount,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}
