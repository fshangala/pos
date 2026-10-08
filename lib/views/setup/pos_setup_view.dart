import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/pos_button.dart';
import '../../viewmodels/pos_app_viewmodel.dart';

class PosSetupView extends StatelessWidget {
  const PosSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PosAppViewModel>(
      builder: (context, viewModel, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.point_of_sale_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Set up this register',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      viewModel.setupError ??
                          'Connect to the catalog service to set up this device.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (viewModel.configurationError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        viewModel.configurationError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    if (viewModel.refreshMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(viewModel.refreshMessage!),
                    ],
                    const SizedBox(height: 28),
                    PosButton(
                      label: 'Sync catalog',
                      icon: Icons.sync_rounded,
                      isLoading: viewModel.isSyncingCatalog,
                      onPressed: viewModel.refreshCatalog,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The first catalog sync must finish before this register can be used.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
