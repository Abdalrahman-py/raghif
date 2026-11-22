import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/repositories/queue_repository.dart';
import '../auth/demo_accounts.dart';
import '../payment/payment_number_screen.dart';
import 'confirmation_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// How the buyer chose to pay for a bag already reserved.
enum PaymentChoice { jawwal, cash }

/// True while a reservation request runs: a second tap must not send a
/// second one. Released once the request answers; from then on the sheet's
/// barrier and the pushed screens cover the buy button.
bool _reserving = false;

/// "اشتري ربطة": reserve the bag first, then choose how to pay.
///
/// Order of events: a buyer who already holds today's booking is taken to it
/// (one bag a day, the server enforces it too). Otherwise the bag is reserved
/// (`reserve_bag`, idempotent), so sold out, closed or offline is reported
/// before any payment screen. Then the buyer picks Jawwal Pay (the simulated
/// wallet screens, then a payment record) or cash at pickup (no record).
/// Backing out of the wallet, or a failed record, keeps the booking with cash
/// due. The receipt opens last. The caller's [BuildContext] must stay mounted.
Future<void> startPurchase(
  BuildContext context, {
  required QueueController controller,
  required DemoUser currentUser,
  required String storeId,
}) async {
  if (_reserving) return;
  final PurchaseModel? purchase;
  _reserving = true;
  try {
    purchase = await _reserve(
      context,
      controller: controller,
      currentUser: currentUser,
      storeId: storeId,
    );
  } finally {
    _reserving = false;
  }
  if (purchase == null || !context.mounted) return;
  // The bag is held from here on. Every exit below shows its receipt.
  final navigator = Navigator.of(context);
  final choice = await showModalBottomSheet<PaymentChoice>(
    context: context,
    showDragHandle: true,
    // Grows with large text instead of overflowing; the sheet scrolls.
    isScrollControlled: true,
    builder: (_) => const PaymentChoiceSheet(),
  );
  if (choice == PaymentChoice.jawwal) {
    final paid = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentNumberScreen(initialNumber: currentUser.phone),
      ),
    );
    if (paid == true) {
      try {
        await controller.recordWalletPayment(purchase.id);
      } catch (_) {
        // The booking stands; without a record the bakery asks for cash.
      }
    }
  }
  // Cash, a dismissed sheet or a cancelled wallet: cash is due at pickup.
  _openReceipt(navigator, controller, currentUser, purchase.id);
}

// Not awaited: the purchase is over once the receipt is on screen.
void _openReceipt(
  NavigatorState navigator,
  QueueController controller,
  DemoUser currentUser,
  String purchaseId,
) => navigator.push(
  MaterialPageRoute(
    builder: (_) => ConfirmationScreen(
      controller: controller,
      purchaseId: purchaseId,
      currentUser: currentUser,
    ),
  ),
);

/// Reserves the bag, or reports why not and returns null (an existing booking
/// today opens its receipt instead).
Future<PurchaseModel?> _reserve(
  BuildContext context, {
  required QueueController controller,
  required DemoUser currentUser,
  required String storeId,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final date = todayDateString();

  void say(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  try {
    final existing = await controller.blockingPurchaseFor(currentUser.id, date);
    if (existing != null) {
      final sameStore = existing.storeId == storeId;
      say(
        sameStore
            ? Strings.dailyLimitReached
            : Strings.dailyLimitReachedOtherStore(
                existing.storeName ??
                    controller.storeById(existing.storeId)?.name ??
                    '',
              ),
      );
      _openReceipt(navigator, controller, currentUser, existing.id);
      return null;
    }
  } on BackendUnavailableException {
    // Unknown, not "none": reserve_bag enforces one bag a day regardless.
  }

  try {
    return await controller.buy(storeId: storeId, date: date);
  } on StoreSoldOutException {
    say(Strings.soldOut);
  } on BackendUnavailableException {
    // Postgres holds the bag count, so an unreachable server means no
    // reservation was made. Saying "done" here is how two buyers end up
    // holding the same last bag.
    say(Strings.offlineWriteFailed);
  }
  return null;
}

/// Shown once the bag is reserved: pay now through Jawwal Pay, or in cash at
/// the bakery. Dismissing it means cash.
class PaymentChoiceSheet extends StatelessWidget {
  const PaymentChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(Strings.bagHeldTitle, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(Strings.bagHeldBody, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: Strings.payWithJawwalOption,
              onPressed: () => Navigator.of(context).pop(PaymentChoice.jawwal),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              Strings.payWithJawwalHint,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              text: Strings.payCashOption,
              onPressed: () => Navigator.of(context).pop(PaymentChoice.cash),
            ),
          ],
        ),
      ),
    );
  }
}
