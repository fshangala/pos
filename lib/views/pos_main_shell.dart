import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/pos_auth_viewmodel.dart';
import '../viewmodels/pos_shift_viewmodel.dart';
import 'orders/completed_orders_view.dart';
import 'register/phone_register_view.dart';
import 'shift/phone_shift_summary_view.dart';

class PosMainShell extends StatefulWidget {
  const PosMainShell({super.key});

  @override
  State<PosMainShell> createState() => _PosMainShellState();
}

class _PosMainShellState extends State<PosMainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<PosAuthViewModel>();
    final bartender = auth.bartender!;
    final station = auth.station!;
    final pages = [
      PhoneRegisterView(
        key: ValueKey('register-${station.id}'),
        counterId: station.id,
        bartenderId: bartender.id,
      ),
      const CompletedOrdersView(),
      const PhoneShiftSummaryView(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index != 0) context.read<PosShiftViewModel>().refresh();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'Register',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize_outlined),
            selectedIcon: Icon(Icons.summarize_rounded),
            label: 'Shift',
          ),
        ],
      ),
    );
  }
}
