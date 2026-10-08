import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/pos_auth_viewmodel.dart';

class PhoneStationSelectView extends StatelessWidget {
  const PhoneStationSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PosAuthViewModel>(
      builder: (context, viewModel, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Choose counter'),
          actions: [
            TextButton.icon(
              onPressed: viewModel.signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Select the station for this shift.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            for (final station in viewModel.stations)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(station.name),
                  subtitle: station.location == null
                      ? null
                      : Text(station.location!),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => viewModel.selectStation(station),
                ),
              ),
            if (viewModel.stations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  viewModel.errorMessage ?? 'No active stations are cached.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
