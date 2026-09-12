import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'qr_redemption.dart';

/// The two feedback states a pickup scan can produce.
enum ScanFeedback { success, failure }

/// A scan is a "success" only when it actually hands a bag over — every other
/// outcome (already collected, batch not called, wrong store, not found here,
/// unreadable code) is a failure buzz, so the owner can hear the difference
/// without looking at the screen mid-queue.
ScanFeedback scanFeedbackFor(QrRedemptionOutcome outcome) =>
    outcome == QrRedemptionOutcome.checkedIn
    ? ScanFeedback.success
    : ScanFeedback.failure;

/// Plays the scan tone + haptic. Best-effort by design: sound and vibration are
/// a nicety on top of the scan, so a device without a working audio route (or
/// a muted stream) must never break redemption — failures are swallowed.
class ScanFeedbackPlayer {
  ScanFeedbackPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  static const _successAsset = 'sounds/scan_success.wav';
  static const _failureAsset = 'sounds/scan_failure.wav';

  Future<void> play(ScanFeedback feedback) async {
    try {
      if (feedback == ScanFeedback.success) {
        await HapticFeedback.mediumImpact();
        await _player.play(AssetSource(_successAsset));
      } else {
        await HapticFeedback.heavyImpact();
        await _player.play(AssetSource(_failureAsset));
      }
    } catch (_) {
      // No audio route / haptics unavailable — the on-screen result is enough.
    }
  }

  Future<void> dispose() => _player.dispose();
}
