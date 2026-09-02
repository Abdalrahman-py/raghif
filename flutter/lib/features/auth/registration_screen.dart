import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'bloc/auth_bloc.dart';

/// Dedicated registration form — name, phone, national ID, PIN, and the
/// Jawwal Pay number (saved once here, reused at purchase time). Reached
/// from onboarding's "Get Started" or an unrecognized phone at login.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late final _phoneController = TextEditingController(text: widget.initialPhone);
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _personalIdController = TextEditingController();
  final _jawwalPayController = TextEditingController();

  String? _error;

  @override
  void initState() {
    super.initState();
    // Jawwal Pay is SIM-tied — default it to the phone number being
    // registered, editable if the user's wallet number actually differs.
    _phoneController.addListener(() {
      if (_jawwalPayController.text.isEmpty ||
          _jawwalPayController.text == _phoneController.text) {
        _jawwalPayController.text = _phoneController.text;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _personalIdController.dispose();
    _jawwalPayController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty ||
        _personalIdController.text.trim().isEmpty ||
        _jawwalPayController.text.trim().isEmpty) {
      setState(() => _error = Strings.registerError);
      return;
    }
    context.read<AuthBloc>().add(
          RegisterRequestedEvent(
            phone: _phoneController.text.trim(),
            pin: _pinController.text.trim(),
            nationalId: _personalIdController.text.trim(),
            name: _nameController.text.trim(),
            jawwalPayNumber: _jawwalPayController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          setState(() => _error = state.errorMessage);
        } else if (state is Authenticated) {
          // This screen is a pushed route; the base route already swapped
          // to the post-registration flow underneath, so pop back to it
          // rather than leaving the form stuck on top.
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            appBar: AppBar(title: const Text(Strings.registrationTitle)),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Strings.registrationSubtitle,
                        style: textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: Strings.nameLabel),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: Strings.phoneLabel),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _personalIdController,
                        decoration: const InputDecoration(labelText: Strings.personalIdLabel),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: Strings.pinLabel,
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _jawwalPayController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: Strings.jawwalPayNumberLabel,
                          helperText: Strings.jawwalPayNumberHint,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        StatusChip(text: _error!, tone: StatusTone.danger),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        text: Strings.registerButton,
                        loading: isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
