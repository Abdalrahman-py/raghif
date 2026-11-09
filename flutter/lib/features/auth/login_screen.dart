import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/i18n/strings.dart';
import '../../core/support/support_contact.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'bloc/auth_bloc.dart';
import 'demo_accounts.dart';
import 'registration_screen.dart';

enum _Step { id, pin }

/// The demo-account shortcut (PIN 1234, in the repository) exists for local
/// work and demos only. Release builds leave it out; opt in with
/// `--dart-define=SHOW_DEMO_ACCOUNTS=true`.
const bool kShowDemoAccounts = bool.fromEnvironment('SHOW_DEMO_ACCOUNTS');

/// One question per screen: who are you (national ID), then your PIN. A
/// forgotten PIN is reset by support (there is no SMS gateway, and a code shown
/// on screen would let anyone in), so the screen only points to them.
///
/// Errors sit on the field they belong to, with the recovery next to them.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.showDemoAccounts = kShowDemoAccounts});

  /// Whether the demo-account shortcut is offered ([kShowDemoAccounts] by
  /// default; tests pass it explicitly).
  final bool showDemoAccounts;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();

  _Step _step = _Step.id;
  bool _showPin = false;

  String? _idError;
  String? _pinError;
  String? _formError;

  /// The server said this number has no account: offer registration right where
  /// the message appears instead of making the user hunt for it.
  bool _notRegistered = false;

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  // --- validation ---------------------------------------------------------

  String? _validateId() {
    final value = _idController.text.trim();
    if (value.isEmpty) return Strings.phoneRequired;
    if (!RegExp(r'^05\d{8}$').hasMatch(value)) return Strings.phoneInvalid;
    return null;
  }

  String? _validatePin() {
    final value = _pinController.text.trim();
    if (value.isEmpty) return Strings.pinRequired;
    if (value.length != 4) return Strings.pinLengthError;
    return null;
  }

  void _clearErrors() {
    if (_idError == null && _pinError == null && _formError == null) {
      return;
    }
    setState(() {
      _notRegistered = false;
      _idError = null;
      _pinError = null;
      _formError = null;
    });
  }

  // --- actions ------------------------------------------------------------

  void _continue() {
    final error = _validateId();
    setState(() {
      _idError = error;
      _formError = null;
      if (error == null) _step = _Step.pin;
    });
  }

  void _submitPin() {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    final error = _validatePin();
    setState(() {
      _pinError = error;
      _formError = null;
    });
    if (error != null) return;
    context.read<AuthBloc>().add(
      LoginRequestedEvent(
        phone: _idController.text.trim(),
        pin: _pinController.text.trim(),
      ),
    );
  }

  /// There is no automatic reset: the person contacts support, who reset the PIN
  /// from the admin panel.
  void _forgotPin() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.forgotPinTitle),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(Strings.forgotPinBody),
            SizedBox(height: 16),
            SupportWhatsAppButton(
              message: 'مرحبًا، نسيت الرمز السري لحسابي في تطبيق رغيف.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Strings.ok),
          ),
        ],
      ),
    );
  }

  /// After a refused PIN the field is emptied and focused again, so the next
  /// attempt is just typing. (Before, the field was disabled while the request
  /// ran, lost focus for good, and kept the wrong digits that had to be
  /// deleted one by one.)
  void _retryPin() {
    if (_step != _Step.pin) return;
    _pinController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  void _back() {
    setState(() {
      _formError = null;
      _idError = null;
      _pinError = null;
      _pinController.clear();
      _step = _Step.id;
    });
  }

  void _goToRegistration() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationScreen()));
  }

  /// Pilot credentials for testing. One tap signs in — the alternative is
  /// copying nine digits off a sheet by hand on the phone under test.
  Future<void> _showDemoAccounts() async {
    final picked = await showModalBottomSheet<({String id, String pin})>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Strings.demoAccountsTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _demoRow(
                sheetContext,
                Strings.demoBuyerLabel,
                demoBuyerPhone,
                demoBuyerPin,
              ),
              const SizedBox(height: AppSpacing.sm),
              _demoRow(
                sheetContext,
                demoBuyer2Name,
                demoBuyer2Phone,
                demoBuyer2Pin,
              ),
              const SizedBox(height: AppSpacing.sm),
              _demoRow(
                sheetContext,
                Strings.demoOwnerLabel,
                demoOwnerPhone,
                demoOwnerPin,
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _idController.text = picked.id;
      _pinController.text = picked.pin;
      _step = _Step.pin;
      _idError = _pinError = _formError = null;
    });
    _submitPin();
  }

  Widget _demoRow(BuildContext sheet, String label, String id, String pin) {
    return Semantics(
      button: true,
      label: Strings.fillDemoAccount(label),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        onTap: () => Navigator.of(sheet).pop((id: id, pin: pin)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '$label — $id / $pin',
              style: Theme.of(sheet).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }

  // --- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          setState(() => _formError = state.errorMessage);
          _retryPin();
        } else if (state is AuthSwitchToRegister) {
          setState(() {
            _formError = Strings.phoneNotFound;
            _notRegistered = true;
          });
        } else if (state is Authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return PopScope(
            canPop: _step == _Step.id,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Scaffold(
              appBar: AppBar(
                // Pushed from the guest screen there is somewhere to go back
                // to; as the root route the first step needs no bar at all.
                toolbarHeight: _step == _Step.id && !Navigator.canPop(context)
                    ? 16
                    : kToolbarHeight,
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                leading: _step == _Step.id && !Navigator.canPop(context)
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: Strings.back,
                        onPressed: isLoading
                            ? null
                            : (_step == _Step.id
                                  ? () => Navigator.of(context).maybePop()
                                  : _back),
                      ),
              ),
              body: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _content(isLoading),
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

  Widget _content(bool isLoading) {
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).height < 720;
    final title = switch (_step) {
      _Step.id => Strings.loginIdTitle,
      _Step.pin => Strings.loginPinTitle,
    };
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/stitch_loaf.svg',
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'رغيف',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.accentContainer,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/images/stitch_loaf.svg',
                  width: 52,
                  height: 52,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'رغيف',
              textAlign: TextAlign.center,
              style: textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_step != _Step.id) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Strings.loginForId(_idController.text.trim()),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                switch (_step) {
                  _Step.id => _idStep(isLoading),
                  _Step.pin => _pinStep(isLoading),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    final error = _formError;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: StatusChip(text: error, tone: StatusTone.danger),
      ),
    );
  }

  Widget _registerOffer() {
    if (!_notRegistered) return const SizedBox.shrink();
    return Center(
      child: TextButton(
        onPressed: _goToRegistration,
        child: const Text(Strings.createAccountLink),
      ),
    );
  }

  Widget _idStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: Strings.phoneLabel,
          child: TextField(
            controller: _idController,
            readOnly: isLoading,
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => _clearErrors(),
            onSubmitted: (_) => _continue(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_outlined),
              errorText: _idError,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(text: Strings.continueButton, onPressed: _continue),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: _goToRegistration,
            child: const Text(Strings.createAccountLink),
          ),
        ),
        if (widget.showDemoAccounts)
          Center(
            child: TextButton(
              onPressed: _showDemoAccounts,
              child: Text(
                Strings.demoAccountsTitle,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pinStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: Strings.pinLabel,
          child: TextField(
            controller: _pinController,
            focusNode: _pinFocus,
            readOnly: isLoading,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            obscureText: !_showPin,
            autofillHints: const [AutofillHints.password],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            // A complete PIN is a submitted PIN: nobody hunts for the button
            // with a full field.
            onChanged: (value) {
              _clearErrors();
              if (value.trim().length == 4) _submitPin();
            },
            onSubmitted: (_) => _submitPin(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              errorText: _pinError,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPin = !_showPin),
                tooltip: _showPin ? Strings.hidePin : Strings.showPin,
                icon: Icon(
                  _showPin ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        _error(),
        _registerOffer(),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          text: Strings.loginButton,
          loading: isLoading,
          onPressed: _submitPin,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : _forgotPin,
            child: const Text(Strings.forgotPin),
          ),
        ),
      ],
    );
  }
}
