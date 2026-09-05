import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/demo_accounts.dart';
import 'models.dart';
import 'qr_payload.dart';
import 'queue_controller.dart';
import 'queue_logic.dart';

/// UI_SPEC.md ConfirmationScreen: big status statement, batch/store at
/// titleMedium, plain-language status while waiting rather than a raw
/// countdown digit grid.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.controller,
    required this.purchaseId,
    required this.currentUser,
  });

  final QueueController controller;
  final String purchaseId;
  final DemoUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Strings.confirmationTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final purchase = controller.purchaseById(purchaseId);
          if (purchase == null) return const SizedBox.shrink();
          final queue = controller.queueForStore(
            purchase.storeId,
            purchase.purchaseDate,
          );
          final position = queue.indexWhere((p) => p.id == purchaseId) + 1;
          final readyAtLabel = formatReadyTime(
            estimatedReadyAtMillis(
              purchase.createdAtMillis,
              purchase.batchNumber,
            ),
          );
          final store = controller.storeById(purchase.storeId);
          final qrPayload = QrPayload(
            purchaseId: purchase.id,
            userName: currentUser.name,
            storeName: store?.name ?? '',
            purchaseDate: purchase.purchaseDate,
          );

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (position > 0)
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            StatusChip(
                              text: '${Strings.queuePosition} $position',
                              tone: StatusTone.neutral,
                            ),
                            StatusChip(
                              text: Strings.batchLabel(purchase.batchNumber),
                              tone: StatusTone.neutral,
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      if (purchase.status == PurchaseStatus.waiting) ...[
                        Text(
                          Strings.statusWaiting,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          child: Column(
                            children: [
                              Text(
                                Strings.estimatedTime,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                readyAtLabel,
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        AppCard(
                          child: Center(
                            child: Text(
                              Strings.statusNotified,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(color: AppColors.accent),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: Column(
                          children: [
                            Text(
                              Strings.receiptQrTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              Strings.receiptQrSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: QrImageView(
                                  data: qrPayload.encode(),
                                  version: QrVersions.auto,
                                  size: 200.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SecondaryButton(
                              text: Strings.shareQrButton,
                              onPressed: () => _shareQr(context, qrPayload),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SecondaryButton(
                              text: Strings.saveQrButton,
                              onPressed: () => _saveQrToGallery(context, qrPayload),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        text: Strings.returnToStores,
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List?> _generateQrBytes(QrPayload payload) async {
    try {
      final painter = QrPainter(
        data: payload.encode(),
        version: QrVersions.auto,
        gapless: true,
      );
      final picData = await painter.toImageData(600);
      return picData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareQr(BuildContext context, QrPayload payload) async {
    try {
      final bytes = await _generateQrBytes(payload);
      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_${payload.purchaseId}.png');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([
          XFile(file.path, mimeType: 'image/png'),
        ], text: '${payload.storeName} - ${payload.userName}');
        return;
      }
    } catch (_) {
      // Fallback
    }
    await Share.share(payload.encode());
  }

  Future<void> _saveQrToGallery(BuildContext context, QrPayload payload) async {
    try {
      final bytes = await _generateQrBytes(payload);
      if (bytes != null) {
        await Gal.putImageBytes(bytes, name: 'qr_${payload.purchaseId}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(Strings.qrSavedSuccess)),
          );
        }
        return;
      }
    } catch (_) {
      // Fallback
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.qrSaveFailed)),
      );
    }
  }
}
