import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/payment_type_selector.dart';
import '../../core/widgets/pos_button.dart';
import '../../core/widgets/pos_text_field.dart';
import '../../core/widgets/quick_tender_chips.dart';
import '../../viewmodels/pos_checkout_viewmodel.dart';

enum CheckoutResult { uploaded, savedLocally }

class PhoneCheckoutView extends StatefulWidget {
  const PhoneCheckoutView({
    required this.counterId,
    required this.bartenderId,
    super.key,
  });

  final String counterId;
  final String bartenderId;

  @override
  State<PhoneCheckoutView> createState() => _PhoneCheckoutViewState();
}

class _PhoneCheckoutViewState extends State<PhoneCheckoutView> {
  final _tenderController = TextEditingController();

  @override
  void dispose() {
    _tenderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PosCheckoutViewModel>(
      builder: (context, viewModel, _) => Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Amount due', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                viewModel.total.toStringAsFixed(2),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              PaymentTypeSelector(
                selected: viewModel.paymentType,
                onChanged: (value) {
                  _tenderController.clear();
                  viewModel.setPaymentType(value);
                },
              ),
              if (viewModel.paymentType == 'CASH') ...[
                const SizedBox(height: 24),
                PosTextField(
                  controller: _tenderController,
                  label: 'Cash received',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  onChanged: viewModel.setTenderedAmount,
                ),
                const SizedBox(height: 12),
                QuickTenderChips(
                  total: viewModel.total,
                  onSelected: (amount) {
                    _tenderController.text = amount.toStringAsFixed(2);
                    viewModel.selectTenderPreset(amount);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('Change due')),
                    Text(
                      viewModel.changeDue.toStringAsFixed(2),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 24),
                Text(
                  'Confirm the mobile payment before completing this order.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
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
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PosButton(
              label: 'Complete order',
              icon: Icons.check_rounded,
              enabled: viewModel.canComplete,
              isLoading: viewModel.isSaving,
              onPressed: () async {
                final order = await viewModel.completeOrder(
                  counterId: widget.counterId,
                  bartenderId: widget.bartenderId,
                );
                if (order != null && context.mounted) {
                  Navigator.of(context).pop(
                    viewModel.uploadSucceeded == true
                        ? CheckoutResult.uploaded
                        : CheckoutResult.savedLocally,
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
