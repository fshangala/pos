import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/pos_held_orders_viewmodel.dart';

Future<bool> showHeldOrdersModal(BuildContext context) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const HeldOrdersModal(),
      ) ??
      false;
}

class HeldOrdersModal extends StatefulWidget {
  const HeldOrdersModal({super.key});

  @override
  State<HeldOrdersModal> createState() => _HeldOrdersModalState();
}

class _HeldOrdersModalState extends State<HeldOrdersModal> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      context.read<PosHeldOrdersViewModel>().loadHeldOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<PosHeldOrdersViewModel>(
          builder: (context, viewModel, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Held orders', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (viewModel.errorMessage != null)
                Text(
                  viewModel.errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.orders.isEmpty
                    ? const Center(child: Text('No held orders.'))
                    : ListView.separated(
                        itemCount: viewModel.orders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final order = viewModel.orders[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(order.totalAmount.toStringAsFixed(2)),
                            subtitle: Text(
                              '${order.totalItemsCount} items · '
                              '${DateTime.parse(order.createdAt).toLocal()}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Resume order',
                              onPressed: () async {
                                final resumed = await viewModel.resumeOrder(
                                  order.localOrderId,
                                );
                                if (resumed && context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
