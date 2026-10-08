import 'package:flutter/material.dart';

class QuickTenderChips extends StatelessWidget {
  const QuickTenderChips({
    required this.total,
    required this.onSelected,
    super.key,
  });

  final double total;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final presets = <double>{
      total,
      10,
      20,
      50,
      100,
    }.where((amount) => amount >= total).toList()..sort();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final amount in presets)
          ActionChip(
            label: Text(amount == total ? 'Exact' : amount.toStringAsFixed(0)),
            onPressed: () => onSelected(amount),
          ),
      ],
    );
  }
}
