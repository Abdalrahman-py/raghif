import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/repositories/queue_repository.dart';
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
  final int storeId;
  final DemoUser currentUser;

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool _isPaying = false;
  PurchaseModel? _blocker;

  int get _userId => widget.currentUser.id;

  @override
  void initState() {
    super.initState();
    _checkBlocker();
  }

  Future<void> _checkBlocker() async {
    final blocker = await widget.controller.blockingPurchaseFor(
      _userId,
      widget.storeId,
      todayDateString(),
    );
    if (mounted) {
      setState(() {
        _blocker = blocker;
      });
    }
  }

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
    final blocker = await widget.controller.blockingPurchaseFor(
      _userId,
      widget.storeId,
      date,
    );
    if (blocker != null) {
      if (!mounted) return;
      setState(() {
        _isPaying = false;
        _blocker = blocker;
      });
      _goToConfirmation(blocker.id);
      return;
    }

    try {
      final purchase = await widget.controller.buy(
        userId: _userId,
        storeId: widget.storeId,
        date: date,
      );
      if (!mounted) return;
      setState(() {
        _isPaying = false;
        _blocker = purchase;
      });
      _goToConfirmation(purchase.id);
    } on StoreSoldOutException {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.soldOut)),
      );
      Navigator.of(context).pop();
    }
  }

  void _goToConfirmation(int purchaseId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          controller: widget.controller,
          purchaseId: purchaseId,
          currentUser: widget.currentUser,
        ),
      ),
    );
    if (mounted) {
      _checkBlocker();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Strings.purchaseTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final store = widget.controller.storeById(widget.storeId);
                  final isAvailable = store?.isAvailable ?? false;
                  final blocker = _blocker;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.storefront,
                                        color: isAvailable
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          store?.name ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                StatusChip(
                                  text: isAvailable
                                      ? Strings.available
                                      : Strings.soldOut,
                                  tone: isAvailable
                                      ? StatusTone.success
                                      : StatusTone.danger,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              Strings.bagsRemaining(
                                store?.bagsRemaining ?? 0,
                                store?.dailyBagLimit ?? 0,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                      const SizedBox(height: AppSpacing.lg),
                      if (blocker != null) ...[
                        AppCard(
                          child: Text(
                            blocker.storeId == widget.storeId
                                ? Strings.dailyLimitReached
                                : Strings.dailyLimitReachedOtherStore(
                                    blocker.storeName ??
                                        widget.controller
                                            .storeById(blocker.storeId)
                                            ?.name ??
                                        '',
                                  ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          text: Strings.viewOrder,
                          onPressed: () => _goToConfirmation(blocker.id),
                        ),
                      ] else ...[
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
