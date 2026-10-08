import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/pos_sign_out_button.dart';
import '../../viewmodels/pos_shift_viewmodel.dart';
import '../../viewmodels/pos_sync_viewmodel.dart';

class PhoneShiftSummaryView extends StatefulWidget {
  const PhoneShiftSummaryView({super.key});

  @override
  State<PhoneShiftSummaryView> createState() => _PhoneShiftSummaryViewState();
}

class _PhoneShiftSummaryViewState extends State<PhoneShiftSummaryView> {
  bool _didLoadSummary = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadSummary) {
      _didLoadSummary = true;
      context.read<PosShiftViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syncMessage = context.read<PosSyncViewModel>().message;
    return Consumer<PosShiftViewModel>(
      builder: (context, viewModel, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Shift summary'),
          actions: [
            IconButton(
              tooltip: 'Refresh summary',
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const PosSignOutButton(),
          ],
        ),
        body: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Today', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Cash sales',
                    value: viewModel.summary?.cashTotal ?? 0,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Mobile money',
                    value: viewModel.summary?.mobileMoneyTotal ?? 0,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Total sales',
                    value: viewModel.summary?.total ?? 0,
                    emphasized: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${viewModel.summary?.completedOrders ?? 0} completed orders',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '${viewModel.summary?.pendingOrders ?? 0} orders saved locally',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
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
                              syncMessage,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleLarge
        : theme.textTheme.titleMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value.toStringAsFixed(2), style: style),
      ],
    );
  }
}
