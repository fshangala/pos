import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/pos_sign_out_button.dart';
import '../../core/widgets/sync_status_chip.dart';
import '../../viewmodels/pos_shift_viewmodel.dart';
import '../../viewmodels/pos_sync_viewmodel.dart';
import 'order_detail_modal.dart';

class CompletedOrdersView extends StatefulWidget {
  const CompletedOrdersView({super.key});

  @override
  State<CompletedOrdersView> createState() => _CompletedOrdersViewState();
}

class _CompletedOrdersViewState extends State<CompletedOrdersView> {
  bool _didLoadOrders = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadOrders) {
      _didLoadOrders = true;
      context.read<PosShiftViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer2<PosShiftViewModel, PosSyncViewModel>(
      builder: (context, viewModel, syncViewModel, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Today’s orders'),
          actions: [
            IconButton(
              tooltip: 'Retry pending uploads',
              onPressed: syncViewModel.isRetryingOrders
                  ? null
                  : () async {
                      await syncViewModel.retryPendingOrders();
                      await viewModel.refresh();
                    },
              icon: syncViewModel.isRetryingOrders
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
            ),
            IconButton(
              tooltip: 'Refresh orders',
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const PosSignOutButton(),
          ],
        ),
        body: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Material(
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              syncViewModel.message,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        viewModel.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  Expanded(
                    child: viewModel.orders.isEmpty
                        ? Center(
                            child: Text(
                              'No completed orders today.',
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: viewModel.orders.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final order = viewModel.orders[index];
                              final created = DateTime.parse(
                                order.createdAt,
                              ).toLocal();
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                title: Text(
                                  order.totalAmount.toStringAsFixed(2),
                                ),
                                subtitle: Text(
                                  '${order.paymentType.replaceAll('_', ' ')} · '
                                  '${order.totalItemsCount} items · '
                                  '${TimeOfDay.fromDateTime(created).format(context)}',
                                ),
                                trailing: SyncStatusChip(
                                  status: order.syncStatus,
                                ),
                                onTap: () =>
                                    showOrderDetailModal(context, order),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
