import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/auth/session_store.dart';
import '../../core/database/app_database.dart' show User;
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'demo_accounts.dart';

/// Phone + national ID + 4-digit PIN, matching app/.../ui/screens/LoginScreen.kt's
/// current behavior: known phone+PIN logs in, an unrecognized phone switches the
/// form into registration mode. Styled per UI_SPEC.md's design tokens.
///
/// Backed by [AuthRepository] (drift, on-device) rather than an in-memory
/// list — the returned row is adapted to [DemoUser] so downstream screens
/// (store list, owner dashboard) don't need to know about drift at all.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.sessionStore,
    required this.onLoginBuyer,
    required this.onLoginOwner,
  });

  final AuthRepository authRepository;
  final SessionStore sessionStore;
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

  DemoUser _asDemoUser(User user) => DemoUser(
    phone: user.phone,
    pin: '',
    role: user.role == 'owner' ? UserRole.owner : UserRole.buyer,
    name: user.name,
  );

  Future<void> _submit() async {
    setState(() => _isLoggingIn = true);

    final repo = widget.authRepository;
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (_isRegistering) {
      final validationError = repo.validateRegistration(
        phone: phone,
        pin: pin,
        nationalId: _personalIdController.text,
        name: _nameController.text,
      );
      if (validationError != null) {
        setState(() {
          _isLoggingIn = false;
          _error = validationError;
        });
        return;
      }
      final user = await repo.register(
        phone: phone,
        pin: pin,
        nationalId: _personalIdController.text.trim(),
        name: _nameController.text.trim(),
      );
      await widget.sessionStore.saveUserId(user.id);
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        _error = null;
      });
      widget.onLoginBuyer(_asDemoUser(user));
      return;
    }

    final user = await repo.findByPhoneAndPin(phone, pin);
    if (user != null) {
      await widget.sessionStore.saveUserId(user.id);
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        _error = null;
      });
      if (user.role == 'owner') {
        widget.onLoginOwner(_asDemoUser(user));
      } else {
        widget.onLoginBuyer(_asDemoUser(user));
      }
      return;
    }

    final exists = await repo.phoneExists(phone);
    if (!mounted) return;
    setState(() {
      _isLoggingIn = false;
      if (exists) {
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
