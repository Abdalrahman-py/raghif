import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/labeled_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../payment/mock_jawwal_pay_service.dart';

/// A new buyer proves the account by confirming their phone number (which is
/// also their Jawwal Pay number): a code is "sent" to it and typed back.
///
/// The text message is simulated for now ([MockJawwalPayService] always uses
/// 1234 and the code is shown on screen). The server repeats the check, so
/// swapping in the real gateway changes the service and one SQL function, not
/// this screen.
class WalletVerificationScreen extends StatefulWidget {
  const WalletVerificationScreen({
    super.key,
    required this.number,
    required this.onVerify,
    required this.onLogout,
    this.busy = false,
    this.error,
    this.service,
  });

  /// The account's phone number. Shown, never edited here.
  final String number;

  /// Called with the code the person typed, after the local check passed. The
  /// caller asks the server and swaps this screen away.
  final void Function(String code) onVerify;

  final VoidCallback onLogout;

  /// The server call is in flight.
  final bool busy;

  /// The server refused the code or could not be reached.
  final String? error;

  final MockJawwalPayService? service;

  @override
  State<WalletVerificationScreen> createState() =>
      _WalletVerificationScreenState();
}

class _WalletVerificationScreenState extends State<WalletVerificationScreen> {
  static final _numberPattern = RegExp(r'^05[69][0-9]{7}$');

  late final TextEditingController _number;
  final _code = TextEditingController();
  late final MockJawwalPayService _service;
  String? _sentCode;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MockJawwalPayService();
    _number = TextEditingController(text: widget.number);
  }

  @override
  void dispose() {
    _number.dispose();
    _code.dispose();
    super.dispose();
  }

  void _send() {
    final number = _number.text.trim();
    if (!_numberPattern.hasMatch(number)) {
      setState(() => _localError = Strings.phoneInvalid);
      return;
    }
    setState(() {
      _localError = null;
      _code.clear();
      _sentCode = _service.resendCode();
    });
  }

  void _confirm() {
    if (widget.busy) return;
    final entered = _code.text.trim();
    if (!_service.verifyCode(entered)) {
      setState(() => _localError = Strings.wrongOtpError);
      return;
    }
    setState(() => _localError = null);
    widget.onVerify(entered);
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sentCode != null;
    final error = _localError ?? widget.error;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/stitch_loaf.svg',
                      width: 72,
                      height: 56,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ExcludeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.accentContainer,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.accent,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          Strings.walletVerifyTitle,
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          sent
                              ? Strings.walletVerifySent(_number.text.trim())
                              : Strings.walletVerifyBody,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (!sent)
                          LabeledField(
                            label: Strings.jawwalPayNumberLabel,
                            child: TextField(
                              controller: _number,
                              readOnly: true,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              style: AppTypography.bodyLarge,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(),
                            ),
                          )
                        else ...[
                          AppCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ExcludeSemantics(
                                  child: Icon(
                                    Icons.info_outline,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    Strings.demoOtpNotification(_sentCode!),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          LabeledField(
                            label: Strings.walletVerifyCodeLabel,
                            child: TextField(
                              controller: _code,
                              keyboardType: TextInputType.number,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center,
                              style: AppTypography.displayMedium,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _confirm(),
                              maxLength: 4,
                              decoration: const InputDecoration(
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    StatusChip(text: error, tone: StatusTone.danger),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (!sent)
                    PrimaryButton(
                      text: Strings.walletVerifySend,
                      onPressed: _send,
                    )
                  else ...[
                    PrimaryButton(
                      text: Strings.walletVerifyConfirm,
                      onPressed: widget.busy ? null : _confirm,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: _send,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: AppColors.accent,
                          textStyle: AppTypography.labelMedium,
                        ),
                        child: const Text(Strings.resendCodeButton),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton(
                      onPressed: widget.onLogout,
                      child: const Text(Strings.logout),
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
