import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import '../../domain/repositories/queue_repository.dart';

/// Runs a backend write and tells the user when it did not happen.
///
/// Postgres owns the state, so a write that failed is a non-event, not
/// something queued for later (constitution II). Returns true when the write
/// went through; on failure it shows [Strings.offlineWriteFailed] and returns
/// false so the caller can skip whatever depended on it.
Future<bool> guardWrite(
  BuildContext context,
  Future<void> Function() write,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await write();
    return true;
  } on BackendUnavailableException {
    messenger.showSnackBar(
      const SnackBar(content: Text(Strings.offlineWriteFailed)),
    );
    return false;
  }
}
