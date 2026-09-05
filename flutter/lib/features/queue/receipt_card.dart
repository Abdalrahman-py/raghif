import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/database/tables/converters.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Ticket-style receipt: store + purchase details above a scannable QR.
/// Rendered on screen and also captured via [RepaintBoundary] for
/// share/save, so its background must stay opaque, never transparent.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.storeName,
    required this.purchaseId,
    required this.purchaseDate,
    required this.batchNumber,
    required this.userName,
    required this.status,
    required this.qrData,
  });

  final String storeName;
  final String purchaseId;
  final String purchaseDate;
  final int batchNumber;
  final String userName;
  final PurchaseStatus status;
  final String qrData;

  String get _statusLabel => switch (status) {
    PurchaseStatus.waiting => Strings.statusWaitingShort,
    PurchaseStatus.notified => Strings.statusNotifiedShort,
    PurchaseStatus.collected => Strings.statusCollectedShort,
  };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppShapes.large,
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(storeName: storeName, statusLabel: _statusLabel),
              const _Perforation(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: Strings.receiptPurchaseIdLabel,
                      value: '#$purchaseId',
                    ),
                    _InfoRow(
                      label: Strings.receiptDateLabel,
                      value: purchaseDate,
                    ),
                    _InfoRow(
                      label: Strings.receiptBatchLabel,
                      value: '$batchNumber',
                    ),
                    _InfoRow(label: Strings.receiptNameLabel, value: userName),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: AppShapes.small,
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 180,
                        gapless: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      Strings.receiptQrSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.storeName, required this.statusLabel});

  final String storeName;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Text(
            Strings.appTitle,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            storeName,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: AppShapes.small,
            ),
            child: Text(
              statusLabel,
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// ponytail: dashed rule faking a ticket-stub perforation — real notch
/// cutouts would need a custom clipper; upgrade to that if the receipt ever
/// needs to look print-accurate.
class _Perforation extends StatelessWidget {
  const _Perforation();

  static const _dashWidth = 6.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / (_dashWidth + _gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) =>
                  Container(width: _dashWidth, height: 1, color: AppColors.border),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(
            value,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
