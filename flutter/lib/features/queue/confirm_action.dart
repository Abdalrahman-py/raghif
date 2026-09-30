import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n/strings.dart';
import '../auth/bloc/auth_bloc.dart';

/// Asks before an action that is one accidental tap away from costing someone
/// time or sales (signing out, closing the bakery). True only on an explicit
/// yes; dismissing the dialog is a no.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(Strings.cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Sign-out behind a confirmation: getting back in means recalling a
/// national ID and PIN, which is not a small ask of an older user.
Future<void> confirmLogout(BuildContext context) async {
  final bloc = context.read<AuthBloc>();
  final confirmed = await confirmAction(
    context,
    title: Strings.logoutConfirmTitle,
    body: Strings.logoutConfirmBody,
    confirmLabel: Strings.logout,
  );
  if (confirmed) bloc.add(const LogoutRequestedEvent());
}
