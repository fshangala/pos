import 'package:flutter/material.dart';

class PosSearchBar extends StatelessWidget {
  const PosSearchBar({
    required this.onChanged,
    required this.onScan,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.text,
      inputFormatters: const [],
      textInputAction: TextInputAction.search,
      autofocus: false,
      autocorrect: false,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search products or barcode',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          tooltip: 'Scan barcode',
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_scanner_rounded),
        ),
      ),
    );
  }
}
