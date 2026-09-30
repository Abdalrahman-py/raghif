import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'bloc/auth_bloc.dart';
import 'demo_accounts.dart';
import 'registration_screen.dart';
import '../../core/widgets/labeled_field.dart';

/// LoginScreen: National ID is the login identifier per spec.md.
/// Default flow: OTP login (Step 1: enter National ID -> Step 2: verify on-screen demo OTP).
/// Alternate flow: PIN login (National ID + 4-digit PIN), reached via the
/// always-visible link under the form.
///
/// Validation lives on the field it belongs to, not in a banner under the
/// button: an empty National ID used to print "يرجى تعبئة جميع الحقول" — a
/// registration sentence naming a problem the user can't see.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Seconds a resend stays locked after a code is requested, so the button is
  /// not a free-for-all and the wait is legible.
  static const _resendCooldownSeconds = 30;

  final _nationalIdController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isPinMode = false;
  bool _isOtpVerifyStep = false;
  bool _showPin = false;
  String? _demoOtpCode;

  String? _idError;
  String? _pinError;
  String? _otpError;
  String? _formError;

  int _resendIn = 0;
  Timer? _cooldown;

  @override
  void dispose() {
    _cooldown?.cancel();
    _nationalIdController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // --- validation ---------------------------------------------------------

  String? _validateNationalId() {
    final value = _nationalIdController.text.trim();
    if (value.isEmpty) return Strings.nationalIdRequired;
    if (value.length != 9) return Strings.nationalIdLengthError;
    return null;
  }

  String? _validatePin() {
    final value = _pinController.text.trim();
    if (value.isEmpty) return Strings.pinRequired;
    if (value.length != 4) return Strings.pinLengthError;
    return null;
  }

  String? _validateOtp() {
    final value = _otpController.text.trim();
    if (value.isEmpty) return Strings.otpRequired;
    if (value.length != 4) return Strings.otpLengthError;
    return null;
  }

  /// Clears inline errors as soon as the user starts fixing them; the banner
  /// waits for the next submit so a server message doesn't flicker away.
  void _clearFieldErrors() {
    if (_idError == null && _pinError == null && _otpError == null) return;
    setState(() {
      _idError = null;
      _pinError = null;
      _otpError = null;
    });
  }

  // --- actions ------------------------------------------------------------

  void _requestOtp() {
    final idError = _validateNationalId();
    if (idError != null) {
      setState(() {
        _idError = idError;
        _formError = null;
      });
      return;
    }
    setState(() {
      _idError = null;
      _formError = null;
    });
    context.read<AuthBloc>().add(
      RequestOtpEvent(nationalId: _nationalIdController.text.trim()),
    );
  }

  void _resendOtp() {
    if (_resendIn > 0) return;
    _requestOtp();
  }

  void _verifyOtp() {
    final otpError = _validateOtp();
    if (otpError != null) {
      setState(() {
        _otpError = otpError;
        _formError = null;
      });
      return;
    }
    setState(() {
      _otpError = null;
      _formError = null;
    });
    context.read<AuthBloc>().add(
      VerifyOtpEvent(
        nationalId: _nationalIdController.text.trim(),
        otp: _otpController.text.trim(),
      ),
    );
  }

  void _submitPinLogin() {
    final idError = _validateNationalId();
    final pinError = _validatePin();
    setState(() {
      _idError = idError;
      _pinError = pinError;
      _formError = null;
    });
    if (idError != null || pinError != null) return;
    context.read<AuthBloc>().add(
      PinLoginRequestedEvent(
        nationalId: _nationalIdController.text.trim(),
        pin: _pinController.text.trim(),
      ),
    );
  }

  /// Fills the code the screen is already showing. The pilot has no SMS, so the
  /// code is on-screen anyway — making the tester retype four digits adds
  /// nothing but typos.
  void _fillDemoOtp() {
    final code = _demoOtpCode;
    if (code == null) return;
    _otpController.text = code;
    _verifyOtp();
  }

  void _fillDemoAccount({required String nationalId, required String pin}) {
    setState(() {
      _isPinMode = true;
      _isOtpVerifyStep = false;
      _nationalIdController.text = nationalId;
      _pinController.text = pin;
      _idError = null;
      _pinError = null;
      _formError = null;
    });
  }

  void _switchToPinMode() {
    setState(() {
      _isPinMode = true;
      _idError = null;
      _pinError = null;
      _formError = null;
    });
  }

  void _switchToOtpMode() {
    setState(() {
      _isPinMode = false;
      _idError = null;
      _pinError = null;
      _formError = null;
    });
  }

  void _resetOtpStep() {
    _cooldown?.cancel();
    setState(() {
      _isOtpVerifyStep = false;
      _otpController.clear();
      _otpError = null;
      _formError = null;
      _resendIn = 0;
    });
  }

  void _startResendCooldown() {
    _cooldown?.cancel();
    _resendIn = _resendCooldownSeconds;
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendIn = _resendIn - 1);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  void _goToRegistration() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationScreen()));
  }

  // --- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          setState(() => _formError = state.errorMessage);
        } else if (state is AuthSwitchToRegister) {
          setState(() => _formError = Strings.nationalIdNotFound);
        } else if (state is AuthOtpSent) {
          setState(() {
            _isOtpVerifyStep = true;
            _isPinMode = false;
            _demoOtpCode = state.otpCode;
            _formError = null;
            _otpError = null;
            _otpController.clear();
          });
          _startResendCooldown();
        } else if (state is Authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                  child: Center(
                    child: StatusChip(
                      text: Strings.demoBadge,
                      tone: StatusTone.neutral,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: AutofillGroup(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SvgPicture.asset(
                              'assets/images/logo.svg',
                              width: 80,
                              height: 80,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (_isPinMode)
                            _pinForm(isLoading)
                          else if (!_isOtpVerifyStep)
                            _nationalIdForm(isLoading)
                          else
                            _otpForm(isLoading),
                          const SizedBox(height: AppSpacing.sm),
                          ..._alternatePath(textTheme, isLoading),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                Strings.createAccountPrompt,
                                style: textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _goToRegistration(),
                                child: const Text(Strings.createAccountLink),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _demoAccountsCard(),
                        ],
                      ),
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

  Widget _formErrorNotice() {
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

  Widget _nationalIdField({required bool isLoading, required bool autofocus}) {
    return LabeledField(
      label: Strings.personalIdLabel,
      child: TextField(
        controller: _nationalIdController,
        enabled: !isLoading,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.username],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        onChanged: (_) => _clearFieldErrors(),
        onSubmitted: (_) => _isPinMode ? _submitPinLogin() : _requestOtp(),
        decoration: InputDecoration(
          helperText: Strings.nationalIdHelper,
          errorText: _idError,
        ),
      ),
    );
  }

  Widget _nationalIdForm(bool isLoading) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _nationalIdField(isLoading: isLoading, autofocus: false),
          _formErrorNotice(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: Strings.requestOtpButton,
            loading: isLoading,
            onPressed: _requestOtp,
          ),
        ],
      ),
    );
  }

  Widget _pinForm(bool isLoading) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _nationalIdField(isLoading: isLoading, autofocus: false),
          const SizedBox(height: AppSpacing.md),
          LabeledField(
            label: Strings.pinLabel,
            child: TextField(
              controller: _pinController,
              enabled: !isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              obscureText: !_showPin,
              autofillHints: const [AutofillHints.password],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (_) => _clearFieldErrors(),
              onSubmitted: (_) => _submitPinLogin(),
              decoration: InputDecoration(
                errorText: _pinError,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showPin = !_showPin),
                  tooltip: _showPin ? Strings.hidePin : Strings.showPin,
                  icon: Icon(
                    _showPin ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          _formErrorNotice(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: Strings.loginButton,
            loading: isLoading,
            onPressed: _submitPinLogin,
          ),
        ],
      ),
    );
  }

  Widget _otpForm(bool isLoading) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Strings.personalIdLabel}: '
                  '${_nationalIdController.text.trim()}',
                  style: textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : _resetOtpStep,
                child: const Text(Strings.changeNationalId),
              ),
            ],
          ),
          if (_demoOtpCode != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _demoOtpNotice(_demoOtpCode!),
          ],
          const SizedBox(height: AppSpacing.md),
          LabeledField(
            label: Strings.otpLabel,
            child: TextField(
              controller: _otpController,
              enabled: !isLoading,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(letterSpacing: 8),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              // A complete code is a submitted code: typing the fourth digit
              // verifies, so nobody hunts for the button with a full field.
              onChanged: (value) {
                _clearFieldErrors();
                if (value.trim().length == 4) _verifyOtp();
              },
              onSubmitted: (_) => _verifyOtp(),
              decoration: InputDecoration(
                helperText: Strings.otpHelper,
                errorText: _otpError,
              ),
            ),
          ),
          _formErrorNotice(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            text: Strings.verifyOtpButton,
            loading: isLoading,
            onPressed: _verifyOtp,
          ),
        ],
      ),
    );
  }

  /// The code this pilot would have texted, made tappable: it is printed on
  /// screen either way.
  Widget _demoOtpNotice(String code) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: _fillDemoOtp,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.accentContainer,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.sms_outlined, size: 18, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Strings.demoOtpBanner(code),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    Strings.demoOtpTapToFill,
                    style: textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The path the current mode isn't on. Both are always visible: hiding the
  /// PIN route until a National ID is typed meant returning users couldn't see
  /// the way they normally log in.
  List<Widget> _alternatePath(TextTheme textTheme, bool isLoading) {
    if (_isOtpVerifyStep) {
      final waiting = _resendIn > 0;
      return [
        Center(
          child: TextButton(
            onPressed: (isLoading || waiting) ? null : _resendOtp,
            child: Text(
              waiting ? Strings.resendOtpIn(_resendIn) : Strings.resendOtp,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : _switchToPinMode,
            child: Text(
              Strings.loginWithPinInstead,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      Center(
        child: TextButton(
          onPressed: isLoading
              ? null
              : (_isPinMode ? _switchToOtpMode : _switchToPinMode),
          child: Text(
            _isPinMode
                ? Strings.loginWithOtpInstead
                : Strings.loginWithPinInstead,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ];
  }

  /// Tertiary by design: pilot credentials, for testing. Each row fills the
  /// form, because the alternative is copying nine digits off the screen by
  /// hand on the device this is being tested on.
  Widget _demoAccountsCard() {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: muted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                Strings.demoAccountsTitle,
                style: textTheme.labelMedium?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _demoRow(
            label: Strings.demoBuyerLabel,
            nationalId: demoBuyerNationalId,
            pin: demoBuyerPin,
          ),
          const SizedBox(height: AppSpacing.sm),
          _demoRow(
            label: Strings.demoOwnerLabel,
            nationalId: demoOwnerNationalId,
            pin: demoOwnerPin,
          ),
        ],
      ),
    );
  }

  Widget _demoRow({
    required String label,
    required String nationalId,
    required String pin,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: Strings.fillDemoAccount(label),
      child: InkWell(
        onTap: () => _fillDemoAccount(nationalId: nationalId, pin: pin),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        child: ConstrainedBox(
          // 48dp target, and the 8dp between rows the constitution asks for.
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label — $nationalId / $pin',
                  style: textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.edit_outlined, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
