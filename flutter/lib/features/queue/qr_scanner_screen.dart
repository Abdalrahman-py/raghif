import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import 'qr_payload.dart';
import 'qr_redemption.dart';
import 'queue_controller.dart';

/// Issue #28: in-app QR redemption scanner for [OwnerQueueScreen].
///
/// Camera-only surface — all decode/match decisions live in
/// [evaluateQrRedemption] so they are testable without a camera. Once a code
/// is read, the camera stops and the result state takes over; "مسح رمز آخر"
/// restarts it.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
    required this.controller,
    required this.storeId,
  });

  final QueueController controller;
  final dynamic storeId;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController();

  int? _ownerStoreId;
  bool _scanning = true;
  bool _processing = false;
  bool _cameraError = false;
  bool _invalidCode = false;
  QrRedemptionResult? _result;

  @override
  void initState() {
    super.initState();
    _ownerStoreId = widget.controller.storeById(widget.storeId)?.id;
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_scanning || _processing) return;
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _processing = true;
    await _scanner.stop();

    final payload = QrPayload.tryDecode(raw);
    if (payload == null) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _invalidCode = true;
        _result = null;
      });
      return;
    }

    final purchase = await widget.controller.purchaseById(payload.purchaseId);
    final result = evaluateQrRedemption(
      payload: payload,
      purchase: purchase,
      ownerStoreId: _ownerStoreId ?? -1,
    );
    if (result.outcome == QrRedemptionOutcome.checkedIn &&
        result.purchase != null) {
      await widget.controller.toggleArrival(result.purchase!.id);
    }
    if (!mounted) return;
    setState(() {
      _processing = false;
      _result = result;
      _invalidCode = false;
    });
  }

  Future<void> _rescan() async {
    setState(() {
      _result = null;
      _invalidCode = false;
      _cameraError = false;
    });
    await _scanner.start();
    setState(() => _scanning = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Strings.scanQrTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _result != null
                ? _ResultView(
                    result: _result!,
                    onRescan: _rescan,
                    onDone: () => Navigator.of(context).pop(),
                  )
                : _invalidCode
                    ? _MessageView(
                        icon: Icons.error_outline,
                        title: Strings.scanInvalidCode,
                        onPrimary: _rescan,
                        primaryLabel: Strings.scanAgain,
                        onSecondary: () => Navigator.of(context).pop(),
                      )
                    : _cameraError
                        ? _MessageView(
                            icon: Icons.no_photography_outlined,
                            title: Strings.scanCameraError,
                            onPrimary: _rescan,
                            primaryLabel: Strings.scanAgain,
                            onSecondary: () => Navigator.of(context).pop(),
                          )
                        : _cameraView(),
          ),
        ),
      ),
    );
  }

  Widget _cameraView() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                controller: _scanner,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  // Permission denied / camera unavailable — surface once.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_cameraError) {
                      setState(() => _cameraError = true);
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            Strings.scanCameraHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Full decoded details are always shown (issue #28: never a silent failure) —
/// the header/icon communicates what happened, the card shows what was encoded.
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.onRescan,
    required this.onDone,
  });

  final QrRedemptionResult result;
  final VoidCallback onRescan;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body, tone) = switch (result.outcome) {
      QrRedemptionOutcome.checkedIn => (
          Icons.check_circle_outline,
          Strings.scanCheckedInTitle,
          Strings.scanCheckedInBody,
          AppColors.success,
        ),
      QrRedemptionOutcome.alreadyCollected => (
          Icons.verified_outlined,
          Strings.scanAlreadyCollected,
          null,
          AppColors.success,
        ),
      QrRedemptionOutcome.batchNotCalledYet => (
          Icons.schedule_outlined,
          Strings.scanBatchNotCalledYet(result.batchNumber ?? 0),
          null,
          AppColors.warning,
        ),
      QrRedemptionOutcome.notFoundHere => (
          Icons.search_off_outlined,
          Strings.scanNotFoundTitle,
          Strings.scanNotFoundBody,
          AppColors.textSecondary,
        ),
      QrRedemptionOutcome.wrongStore => (
          Icons.store_outlined,
          Strings.scanWrongStoreTitle,
          Strings.scanWrongStoreBody(result.actualStoreName ?? '—'),
          AppColors.danger,
        ),
    };

    final payload = result.payload;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 72, color: tone),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payload.userName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${payload.storeName} · ${payload.purchaseDate}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  payload.purchaseId,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(text: Strings.scanAgain, onPressed: onRescan),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(text: Strings.back, onPressed: onDone),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.onPrimary,
    required this.primaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(text: primaryLabel, onPressed: onPrimary),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(text: Strings.back, onPressed: onSecondary),
        ],
      ),
    );
  }
}
