import 'package:flutter/material.dart';

class PaymentTypeSelector extends StatelessWidget {
  const PaymentTypeSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'CASH',
          label: Text('Cash'),
          icon: Icon(Icons.payments_outlined),
        ),
        ButtonSegment(
          value: 'MOBILE_MONEY',
          label: Text('Mobile money'),
          icon: Icon(Icons.phone_android_rounded),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
