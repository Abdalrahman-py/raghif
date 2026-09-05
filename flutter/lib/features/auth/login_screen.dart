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

/// LoginScreen: National ID is the login identifier per spec.md.
/// Default flow: OTP login (Step 1: enter National ID -> Step 2: verify on-screen demo OTP).
/// Alternate flow: PIN login (National ID + 4-digit PIN), reached via low-emphasis text link.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nationalIdController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isPinMode = false;
  bool _isOtpVerifyStep = false;
  String? _demoOtpCode;
  String? _error;

  @override
  void dispose() {
    _nationalIdController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.isEmpty) {
      setState(() => _error = Strings.registerError);
      return;
    }
    setState(() => _error = null);
    context.read<AuthBloc>().add(RequestOtpEvent(nationalId: nationalId));
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = Strings.otpError);
      return;
    }
    setState(() => _error = null);
    context.read<AuthBloc>().add(
          VerifyOtpEvent(
            nationalId: _nationalIdController.text.trim(),
            otp: otp,
          ),
        );
  }

  void _submitPinLogin() {
    final nationalId = _nationalIdController.text.trim();
    final pin = _pinController.text.trim();
    if (nationalId.isEmpty || pin.isEmpty) {
      setState(() => _error = Strings.registerError);
      return;
    }
    setState(() => _error = null);
    context.read<AuthBloc>().add(
          PinLoginRequestedEvent(
            nationalId: nationalId,
            pin: pin,
          ),
        );
  }

  void _switchToPinMode() {
    setState(() {
      _isPinMode = true;
      _error = null;
    });
  }

  void _switchToOtpMode() {
    setState(() {
      _isPinMode = false;
      _error = null;
    });
  }

  void _resetOtpStep() {
    setState(() {
      _isOtpVerifyStep = false;
      _otpController.clear();
      _error = null;
    });
  }

  void _goToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegistrationScreen(),
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
          setState(() {
            _error = Strings.nationalIdNotFound;
          });
        } else if (state is AuthOtpSent) {
          setState(() {
            _isOtpVerifyStep = true;
            _demoOtpCode = state.otpCode;
            _error = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Strings.demoOtpBanner(state.otpCode)),
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is Authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
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
                        if (_isPinMode) ...[
                          TextField(
                            controller: _nationalIdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: Strings.personalIdLabel,
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
                            onPressed: _submitPinLogin,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: TextButton(
                              onPressed: _switchToOtpMode,
                              child: Text(
                                Strings.loginWithOtpInstead,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ] else if (!_isOtpVerifyStep) ...[
                          TextField(
                            controller: _nationalIdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: Strings.personalIdLabel,
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            StatusChip(text: _error!, tone: StatusTone.danger),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            text: Strings.requestOtpButton,
                            loading: isLoading,
                            onPressed: _requestOtp,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: TextButton(
                              onPressed: _switchToPinMode,
                              child: Text(
                                Strings.loginWithPinInstead,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          AppCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    Strings.demoOtpBanner(
                                        _demoOtpCode ?? '4821'),
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${Strings.personalIdLabel}: ${_nationalIdController.text.trim()}',
                                style: textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: _resetOtpStep,
                                child: const Text(Strings.changeNationalId),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              labelText: Strings.otpLabel,
                              counterText: '',
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            StatusChip(text: _error!, tone: StatusTone.danger),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            text: Strings.verifyOtpButton,
                            loading: isLoading,
                            onPressed: _verifyOtp,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Center(
                            child: TextButton(
                              onPressed: isLoading ? null : _requestOtp,
                              child: const Text(Strings.resendOtp),
                            ),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: _switchToPinMode,
                              child: Text(
                                Strings.loginWithPinInstead,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                                '${Strings.demoBuyerLabel} — $demoBuyerNationalId / $demoBuyerPin',
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                '${Strings.demoOwnerLabel} — $demoOwnerNationalId / $demoOwnerPin',
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
