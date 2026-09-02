import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'demo_accounts.dart';

/// Phone + national ID + 4-digit PIN, matching app/.../ui/screens/LoginScreen.kt's
/// current behavior: known phone+PIN logs in, an unrecognized phone switches the
/// form into registration mode. Styled per UI_SPEC.md's design tokens.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoginBuyer,
    required this.onLoginOwner,
  });

  final ValueChanged<DemoUser> onLoginBuyer;
  final ValueChanged<DemoUser> onLoginOwner;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _personalIdController = TextEditingController();

  String? _error;
  bool _isLoggingIn = false;
  bool _isRegistering = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _nameController.dispose();
    _personalIdController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _isLoggingIn = true);

    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (_isRegistering) {
      final validationError = validateRegistration(
        phone: phone,
        pin: pin,
        personalId: _personalIdController.text,
        name: _nameController.text,
      );
      setState(() {
        _isLoggingIn = false;
        if (validationError != null) {
          _error = validationError;
        } else {
          _error = null;
          widget.onLoginBuyer(
            DemoUser(
              phone: phone,
              pin: pin,
              role: UserRole.buyer,
              name: _nameController.text.trim(),
            ),
          );
        }
      });
      return;
    }

    final user = findByPhoneAndPin(phone, pin);
    if (user != null) {
      setState(() {
        _isLoggingIn = false;
        _error = null;
      });
      if (user.role == UserRole.owner) {
        widget.onLoginOwner(user);
      } else {
        widget.onLoginBuyer(user);
      }
      return;
    }

    setState(() {
      _isLoggingIn = false;
      if (phoneExists(phone)) {
        _error = Strings.loginError;
      } else {
        _error = null;
        _isRegistering = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                  if (_isRegistering) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: Strings.nameLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _personalIdController,
                      decoration: const InputDecoration(
                        labelText: Strings.personalIdLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const StatusChip(
                      text: Strings.newAccountNotice,
                      tone: StatusTone.neutral,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    StatusChip(text: _error!, tone: StatusTone.danger),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: _isRegistering
                        ? Strings.registerButton
                        : Strings.loginButton,
                    loading: _isLoggingIn,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
  }
}
