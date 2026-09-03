import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';

/// Screen displayed after the mock Jawwal Pay OTP is verified successfully.
/// Tapping the action button completes the payment flow and triggers the
/// reservation creation.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.paymentSuccessTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    Strings.paymentSuccessTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Text(
                      Strings.paymentSuccessMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    text: Strings.completeReservationButton,
                    onPressed: () => Navigator.of(context).pop(true),
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
