import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../core/widgets/status_chip.dart';

/// The booking's payment state, by the same rule as the receipt: "paid" only
/// when prepaid through the real wallet ([PurchaseModel.isPrepaid]); anything
/// else, a simulated wallet payment included, means cash is due at pickup.
class PaymentChip extends StatelessWidget {
  const PaymentChip({super.key, required this.prepaid, required this.price});

  final bool prepaid;
  final double price;

  @override
  Widget build(BuildContext context) => prepaid
      ? const StatusChip(
          text: Strings.paidBadge,
          tone: StatusTone.success,
          icon: Icons.check_circle_rounded,
        )
      : StatusChip(
          text: Strings.cashDueChip(price),
          tone: StatusTone.warning,
          icon: Icons.payments_outlined,
        );
}
