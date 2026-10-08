import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/pos_button.dart';
import '../../core/widgets/pos_text_field.dart';
import '../../viewmodels/pos_auth_viewmodel.dart';

class PhonePinLoginView extends StatefulWidget {
  const PhonePinLoginView({super.key});

  @override
  State<PhonePinLoginView> createState() => _PhonePinLoginViewState();
}

class _PhonePinLoginViewState extends State<PhonePinLoginView> {
  final _pinController = TextEditingController();
  String? _bartenderId;
  bool _didLoadProfiles = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadProfiles) {
      _didLoadProfiles = true;
      context.read<PosAuthViewModel>().loadProfiles();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _signIn(PosAuthViewModel viewModel) async {
    final id = _bartenderId;
    if (id == null || _pinController.text.isEmpty) return;
    final success = await viewModel.authenticate(
      bartenderId: id,
      pin: _pinController.text,
    );
    _pinController.clear();
    if (!success && mounted) FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<PosAuthViewModel>(
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
                      Icons.local_bar_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bartender sign in',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your profile and enter your PIN.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    if (viewModel.isLoadingProfiles)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _bartenderId,
                        decoration: const InputDecoration(
                          labelText: 'Bartender',
                        ),
                        items: [
                          for (final bartender in viewModel.bartenders)
                            DropdownMenuItem(
                              value: bartender.id,
                              child: Text(bartender.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _bartenderId = value),
                      ),
                      const SizedBox(height: 16),
                      PosTextField(
                        controller: _pinController,
                        label: 'PIN',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        obscureText: true,
                        onSubmitted: (_) => _signIn(viewModel),
                      ),
                    ],
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        viewModel.errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PosButton(
                      label: 'Continue',
                      icon: Icons.lock_open_rounded,
                      enabled: _bartenderId != null,
                      isLoading: viewModel.isAuthenticating,
                      onPressed: () => _signIn(viewModel),
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
