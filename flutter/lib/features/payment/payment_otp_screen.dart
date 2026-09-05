import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'mock_jawwal_pay_service.dart';
import 'payment_success_screen.dart';

/// Screen where user verifies the 4-digit mock OTP code for Jawwal Pay payment.
class PaymentOtpScreen extends StatefulWidget {
  const PaymentOtpScreen({
    super.key,
    required this.service,
    required this.phoneNumber,
  });

  final MockJawwalPayService service;
  final String phoneNumber;

  @override
  State<PaymentOtpScreen> createState() => _PaymentOtpScreenState();
}

class _PaymentOtpScreenState extends State<PaymentOtpScreen> {
  final _codeController = TextEditingController();
  late String _currentCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.service.generateCode();
    _notifyOtp(_currentCode);
  }

  void _notifyOtp(String code) {
    NotificationService.instance.showNotification(
      title: Strings.otpNotificationTitle,
      body: Strings.otpNotificationBody(code),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _resend() {
    setState(() {
      _currentCode = widget.service.resendCode();
      _error = null;
    });
    _notifyOtp(_currentCode);
  }

  void _confirm() async {
    final entered = _codeController.text.trim();
    if (!widget.service.verifyCode(entered)) {
      setState(() => _error = Strings.wrongOtpError);
      return;
    }

    setState(() => _error = null);
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
    );

    if (success == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.paymentOtpTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            Strings.demoOtpNotification(_currentCode),
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    Strings.paymentOtpInstructions,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${Strings.phoneLabel}: ${widget.phoneNumber}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: Strings.paymentOtpLabel,
                      counterText: '',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    StatusChip(text: _error!, tone: StatusTone.danger),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: Strings.confirmPaymentButton,
                    onPressed: _confirm,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: TextButton(
                      onPressed: _resend,
                      child: const Text(Strings.resendCodeButton),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SecondaryButton(
                    text: Strings.back,
                    onPressed: () => Navigator.of(context).pop(false),
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
