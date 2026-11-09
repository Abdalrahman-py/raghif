import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../domain/models/purchase_model.dart';
import '../../domain/repositories/queue_repository.dart';
import '../auth/demo_accounts.dart';
import '../payment/payment_number_screen.dart';
import 'confirmation_screen.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// "اشتري ربطة" — straight to payment, with no review screen in between.
///
/// Order of events: a buyer who already holds today's booking is taken to it
/// (one bag a day, the server enforces it too); otherwise the wallet payment
/// screens run, then the booking is made, the payment recorded, and the
/// receipt shown. The caller's [BuildContext] must stay mounted.
Future<void> startPurchase(
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

  void openReceipt(String purchaseId) {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          controller: controller,
          purchaseId: purchaseId,
          currentUser: currentUser,
        ),
      ),
    );
  }

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
      openReceipt(existing.id);
      return;
    }
  } on BackendUnavailableException {
    // Unknown, not "none": reserve_bag enforces one bag a day regardless.
  }

  final paid = await navigator.push<bool>(
    MaterialPageRoute(
      builder: (_) => PaymentNumberScreen(initialNumber: currentUser.phone),
    ),
  );
  if (paid != true) return;

  try {
    final PurchaseModel purchase = await controller.buy(
      storeId: storeId,
      date: date,
    );
    try {
      await controller.recordWalletPayment(purchase.id);
    } catch (_) {
      // The booking stands; without a record the bakery asks for cash.
    }
    openReceipt(purchase.id);
  } on StoreSoldOutException {
    say(Strings.soldOut);
  } on BackendUnavailableException {
    // Postgres holds the bag count, so an unreachable server means no
    // reservation was made. Saying "done" here is how two buyers end up
    // holding the same last bag.
    say(Strings.offlineWriteFailed);
  }
}
