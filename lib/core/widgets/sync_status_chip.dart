import 'package:flutter/material.dart';

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'SYNCED' => ('Uploaded', theme.colorScheme.primary),
      'FAILED' => ('Local only', theme.colorScheme.error),
      _ => ('Pending locally', theme.colorScheme.secondary),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      side: BorderSide(color: color),
      labelStyle: theme.textTheme.labelSmall?.copyWith(color: color),
    );
  }
}
