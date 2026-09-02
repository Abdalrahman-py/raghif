import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'bloc/auth_bloc.dart';
import 'demo_accounts.dart';
import 'registration_screen.dart';

/// Phone + 4-digit PIN. An unrecognized phone number pushes
/// [RegistrationScreen] with the phone prefilled. Styled per UI_SPEC.md's
/// design tokens.
///
/// Reads/dispatches the [AuthBloc] provided above it in the widget tree —
/// a successful login is picked up by the app-level [AuthBloc] listener in
/// main.dart, which swaps this screen out. No direct repository access here.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(
          LoginRequestedEvent(
            phone: _phoneController.text.trim(),
            pin: _pinController.text.trim(),
          ),
        );
  }

  void _goToRegistration([String? initialPhone]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(initialPhone: initialPhone),
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
        } else if (state is AuthSwitchToRegister) {
          _goToRegistration(state.phone);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            width: 88,
                            height: 88,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          Strings.appTitle,
                          textAlign: TextAlign.center,
                          style: textTheme.displayMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          Strings.appSubtitle,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Center(
                          child: StatusChip(
                            text: Strings.demoBadge,
                            tone: StatusTone.neutral,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: Strings.phoneLabel,
                          ),
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
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          StatusChip(text: _error!, tone: StatusTone.danger),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          text: Strings.loginButton,
                          loading: isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              Strings.createAccountPrompt,
                              style: textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => _goToRegistration(),
                              child: const Text(Strings.createAccountLink),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Strings.demoAccountsTitle,
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${Strings.demoBuyerLabel} — $demoBuyerPhone / $demoBuyerPin',
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                '${Strings.demoOwnerLabel} — $demoOwnerPhone / $demoOwnerPin',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
