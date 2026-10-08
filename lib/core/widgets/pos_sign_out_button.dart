import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/pos_auth_viewmodel.dart';
import '../../viewmodels/pos_checkout_viewmodel.dart';
import '../../viewmodels/pos_register_viewmodel.dart';

class PosSignOutButton extends StatelessWidget {
  const PosSignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      onPressed: () {
        context.read<PosRegisterViewModel>().clearCart();
        context.read<PosCheckoutViewModel>().reset();
        context.read<PosAuthViewModel>().signOut();
      },
      icon: const Icon(Icons.logout_rounded),
    );
  }
}
