import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import 'bloc/auth_bloc.dart';

/// Account creation, one question per screen: name, national ID, phone, PIN,
/// then the Jawwal Pay number last (it only matters at payment time, and it
/// starts out as the phone number just given).
///
/// Nothing is sent until the last step. The server decides whether the phone or
/// ID is already registered; when it says so the form jumps back to the step
/// that holds the offending value instead of leaving the person on the last
/// screen with an error about something they typed three screens ago.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.initialPhone, this.storeName});

  final String? initialPhone;

  /// The bakery the visitor was looking at when they decided to book; shown as
  /// context above the steps.
  final String? storeName;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _total = 5;
  static const _nameStep = 0;
  static const _idStep = 1;
  static const _phoneStep = 2;
  static const _pinStep = 3;

  final _formKeys = List.generate(_total, (_) => GlobalKey<FormState>());

  late final _phoneController = TextEditingController(
    text: widget.initialPhone,
  );
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _nameController = TextEditingController();
  final _personalIdController = TextEditingController();
  final _jawwalPayController = TextEditingController();

  int _step = 0;
  bool _showPin = false;
  String? _formError;

  static final _palestinianMobile = RegExp(r'^05\d{8}$');
  static final _repeatedDigits = RegExp(r'^(\d)\1{3}$');
  static const _sequentialPins = {
    '0123',
    '1234',
    '2345',
    '3456',
    '4567',
    '5678',
    '6789',
    '3210',
    '4321',
    '5432',
    '6543',
    '7654',
    '8765',
    '9876',
  };

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _nameController.dispose();
    _personalIdController.dispose();
    _jawwalPayController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) =>
      (value ?? '').trim().isEmpty ? Strings.nameRequired : null;

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return Strings.phoneRequired;
    return _palestinianMobile.hasMatch(text) ? null : Strings.phoneInvalid;
  }

  String? _validateNationalId(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return Strings.nationalIdRequired;
    return text.length == 9 ? null : Strings.nationalIdLengthError;
  }

  String? _validatePin(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return Strings.pinRequired;
    if (text.length != 4) return Strings.pinLengthError;
    // Same rule the server enforces: repeated or sequential PINs are guessed
    // first.
    if (_repeatedDigits.hasMatch(text) || _sequentialPins.contains(text)) {
      return Strings.pinTooWeak;
    }
    return null;
  }

  String? _validateConfirmPin(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return Strings.pinRequired;
    return text == _pinController.text.trim() ? null : Strings.pinMismatch;
  }

  /// Optional: empty means "use the phone number / add it later".
  String? _validateJawwalPay(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return _palestinianMobile.hasMatch(text) ? null : Strings.jawwalPayInvalid;
  }

  void _goTo(int step) {
    setState(() {
      _step = step;
      _formError = null;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      _goTo(_step - 1);
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    final form = _formKeys[_step].currentState;
    if (form == null || !form.validate()) return;
    if (_step == _phoneStep) {
      // The wallet number starts out as the phone just given, unless the person
      // already typed their own.
      if (_jawwalPayController.text.isEmpty) {
        _jawwalPayController.text = _phoneController.text.trim();
      }
    }
    if (_step < _total - 1) {
      _goTo(_step + 1);
    } else {
      _submit();
    }
  }

  void _submit() {
    final wallet = _jawwalPayController.text.trim();
    setState(() => _formError = null);
    context.read<AuthBloc>().add(
      RegisterRequestedEvent(
        phone: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
        nationalId: _personalIdController.text.trim(),
        name: _nameController.text.trim(),
        jawwalPayNumber: wallet.isEmpty ? null : wallet,
      ),
    );
  }

  /// Where an error from the server belongs, so the person lands on the step
  /// they can fix.
  void _showFailure(String message) {
    final target = switch (message) {
      Strings.nationalIdAlreadyRegistered => _idStep,
      Strings.phoneAlreadyRegistered => _phoneStep,
      _ => null,
    };
    setState(() {
      if (target != null) _step = target;
      _formError = message;
    });
  }

  Widget _stepBody(bool isLoading) {
    switch (_step) {
      case _nameStep:
        return _single(
          title: Strings.stepNameTitle,
          hint: Strings.stepNameHint,
          label: Strings.nameLabel,
          controller: _nameController,
          validator: _validateName,
          enabled: !isLoading,
          keyboardType: TextInputType.name,
          autofill: const [AutofillHints.name],
          capitalization: TextCapitalization.words,
        );
      case _idStep:
        return _single(
          title: Strings.stepIdTitle,
          hint: Strings.stepIdHint,
          label: Strings.personalIdLabel,
          controller: _personalIdController,
          validator: _validateNationalId,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          helper: Strings.nationalIdHelper,
        );
      case _phoneStep:
        return _single(
          title: Strings.stepPhoneTitle,
          hint: Strings.stepPhoneHint,
          label: Strings.phoneLabel,
          controller: _phoneController,
          validator: _validatePhone,
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          autofill: const [AutofillHints.telephoneNumber],
        );
      case _pinStep:
        return _pinFields(isLoading);
      default:
        return _single(
          title: Strings.stepWalletTitle,
          hint: Strings.stepWalletHint,
          label: Strings.jawwalPayNumberLabel,
          controller: _jawwalPayController,
          validator: _validateJawwalPay,
          enabled: !isLoading,
          keyboardType: TextInputType.phone,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          helper: Strings.jawwalPayNumberHint,
        );
    }
  }

  Widget _heading(String title, String? hint) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(hint, style: textTheme.bodyLarge?.copyWith(color: muted)),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _single({
    required String title,
    required String hint,
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required bool enabled,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    Iterable<String>? autofill,
    TextCapitalization capitalization = TextCapitalization.none,
    String? helper,
  }) {
    return Form(
      key: _formKeys[_step],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(title, hint),
          LabeledField(
            label: label,
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              autofocus: true,
              keyboardType: keyboardType,
              inputFormatters: formatters,
              autofillHints: autofill,
              textCapitalization: capitalization,
              textInputAction: TextInputAction.next,
              validator: validator,
              onChanged: (_) {
                if (_formError != null) setState(() => _formError = null);
              },
              onFieldSubmitted: (_) => _next(),
              decoration: InputDecoration(helperText: helper),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinFields(bool isLoading) {
    return Form(
      key: _formKeys[_pinStep],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(Strings.stepPinTitle, Strings.pinHelper),
          LabeledField(
            label: Strings.pinLabel,
            child: TextFormField(
              controller: _pinController,
              enabled: !isLoading,
              autofocus: true,
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: _validatePin,
              onChanged: (_) {
                if (_formError != null) setState(() => _formError = null);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline_rounded),
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
          const SizedBox(height: AppSpacing.md),
          LabeledField(
            label: Strings.confirmPinLabel,
            child: TextFormField(
              controller: _confirmPinController,
              enabled: !isLoading,
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: _validateConfirmPin,
              onFieldSubmitted: (_) => _next(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          _showFailure(state.errorMessage);
        } else if (state is Authenticated) {
          // This screen is a pushed route; the base route already swapped to
          // the post-registration flow underneath, so pop back to it rather
          // than leaving the form stuck on top.
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final last = _step == _total - 1;
          return PopScope(
            canPop: _step == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                title: const Text(Strings.registrationTitle),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: Strings.back,
                  onPressed: isLoading ? null : _back,
                ),
              ),
              body: SafeArea(
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
                          if (widget.storeName != null) ...[
                            Text(
                              Strings.registrationFor(widget.storeName!),
                              style: textTheme.bodyLarge?.copyWith(
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Text(
                            Strings.stepOf(_step + 1, _total),
                            style: textTheme.bodyMedium?.copyWith(color: muted),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (_step + 1) / _total,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _stepBody(isLoading),
                          if (_formError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                              ),
                              child: Text(
                                _formError!,
                                key: const Key('registration-error'),
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            text: last
                                ? Strings.registerButton
                                : Strings.stepsNext,
                            loading: isLoading,
                            onPressed: _next,
                          ),
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
}
