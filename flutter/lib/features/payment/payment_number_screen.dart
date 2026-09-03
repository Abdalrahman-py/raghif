import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import 'mock_jawwal_pay_service.dart';
import 'payment_otp_screen.dart';

/// Screen where user reviews and confirms their registered Jawwal Pay number
/// before the simulated OTP is generated.
class PaymentNumberScreen extends StatefulWidget {
  const PaymentNumberScreen({
    super.key,
    required this.initialNumber,
    this.service,
  });

  final String initialNumber;
  final MockJawwalPayService? service;

  @override
  State<PaymentNumberScreen> createState() => _PaymentNumberScreenState();
}

class _PaymentNumberScreenState extends State<PaymentNumberScreen> {
  late final TextEditingController _phoneController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _proceed() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty) {
      setState(() => _error = Strings.registerError);
      return;
    }

    setState(() => _error = null);
    final service = widget.service ?? MockJawwalPayService();
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentOtpScreen(service: service, phoneNumber: number),
      ),
    );

    if (success == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.paymentTitle)),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Strings.confirmJawwalPayNumber,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          Strings.jawwalPayPrompt,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: Strings.jawwalPayNumberLabel,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    StatusChip(text: _error!, tone: StatusTone.danger),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: Strings.proceedToOtp,
                    onPressed: _proceed,
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
