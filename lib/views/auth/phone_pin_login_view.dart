import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/pos_button.dart';
import '../../core/widgets/pos_text_field.dart';
import '../../viewmodels/pos_app_viewmodel.dart';
import '../../viewmodels/pos_auth_viewmodel.dart';

class PhonePinLoginView extends StatefulWidget {
  const PhonePinLoginView({super.key});

  @override
  State<PhonePinLoginView> createState() => _PhonePinLoginViewState();
}

class _PhonePinLoginViewState extends State<PhonePinLoginView> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  bool _didLoadProfiles = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadProfiles) {
      _didLoadProfiles = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PosAuthViewModel>().loadProfiles();
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn(PosAuthViewModel viewModel) async {
    if (_phoneController.text.isEmpty || _pinController.text.isEmpty) return;
    final success = await viewModel.authenticate(
      phone: _phoneController.text,
      pin: _pinController.text,
    );
    _pinController.clear();
    if (!success && mounted) FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appViewModel = context.watch<PosAppViewModel>();
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
                      'Enter your phone number and PIN.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (appViewModel.refreshMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        appViewModel.refreshMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (viewModel.isLoadingProfiles)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      PosTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _pinFocusNode.requestFocus(),
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
                        autofocus: false,
                        obscureText: true,
                        onSubmitted: (_) => _signIn(viewModel),
                        focusNode: _pinFocusNode,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    if (viewModel.bartenders.isEmpty &&
                        !viewModel.isLoadingProfiles) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () async {
                          final app = context.read<PosAppViewModel>();
                          await app.refreshBartenderProfiles();
                          if (app.canProceedToLogin) {
                            await viewModel.loadProfiles();
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry profile sync'),
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
                      enabled:
                          _phoneController.text.isNotEmpty &&
                          _pinController.text.isNotEmpty,
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
