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
                      'Bartender profiles',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      viewModel.setupError ??
                          'Connect to load the bartender profiles for this register.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (viewModel.refreshMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(viewModel.refreshMessage!),
                    ],
                    const SizedBox(height: 28),
                    PosButton(
                      label: 'Retry profile sync',
                      icon: Icons.sync_rounded,
                      isLoading: viewModel.isSyncingProfiles,
                      onPressed: viewModel.refreshBartenderProfiles,
                    ),
                    if (viewModel.canContinueWithLocalBartenders) ...[
                      const SizedBox(height: 12),
                      PosButton(
                        label: 'Continue with local data',
                        icon: Icons.offline_bolt_outlined,
                        onPressed: viewModel.continueWithLocalBartenders,
                      ),
                    ],
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
