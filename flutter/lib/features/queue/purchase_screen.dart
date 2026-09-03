import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../auth/demo_accounts.dart';
import '../payment/payment_number_screen.dart';
import 'confirmation_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// UI_SPEC.md PurchaseScreen: store name + price hero, single prominent Buy
/// button, no secondary actions competing for attention — "back" is the only
/// other affordance, and it's visually secondary.
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({
    super.key,
    required this.controller,
    required this.storeId,
    required this.currentUser,
  });

  final QueueController controller;
  final String storeId;
  final DemoUser currentUser;

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool _isPaying = false;

  String get _userId => widget.currentUser.phone;

  void _startPaymentFlow() async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentNumberScreen(
          initialNumber:
              widget.currentUser.jawwalPayNumber ?? widget.currentUser.phone,
        ),
      ),
    );
    if (paid == true && mounted) {
      _pay();
    }
  }

  void _pay() async {
    setState(() => _isPaying = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final date = todayDateString();
    final blocker = widget.controller.blockingPurchaseFor(
      _userId,
      widget.storeId,
      date,
    );
    if (blocker != null) {
      setState(() => _isPaying = false);
      _goToConfirmation(blocker.id);
      return;
    }

    final purchase = widget.controller.buy(
      userId: _userId,
      storeId: widget.storeId,
      date: date,
    );
    setState(() => _isPaying = false);
    _goToConfirmation(purchase.id);
  }

  void _goToConfirmation(String purchaseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          controller: widget.controller,
          purchaseId: purchaseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.controller.storeById(widget.storeId);
    final blocker = widget.controller.blockingPurchaseFor(
      _userId,
      widget.storeId,
      todayDateString(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(Strings.purchaseTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    store?.name ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (blocker != null) ...[
                    AppCard(
                      child: Text(
                        Strings.dailyLimitReached,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      text: Strings.viewOrder,
                      onPressed: () => _goToConfirmation(blocker.id),
                    ),
                  ] else ...[
                    AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Strings.priceLabel,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            Strings.priceValue,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      text: Strings.payButton,
                      loading: _isPaying,
                      onPressed: _startPaymentFlow,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    text: Strings.back,
                    onPressed: () => Navigator.of(context).pop(),
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
