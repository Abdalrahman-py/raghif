import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.dart';
import '../theme/app_colors.dart';

/// Opens a WhatsApp chat with support. Falls back to showing the number when
/// WhatsApp (or a browser) cannot be opened, so the person can still reach us.
Future<void> openSupportWhatsApp(
  BuildContext context, {
  String? message,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final number = Strings.supportWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri.https('wa.me', '/$number', {
    if (message != null && message.isNotEmpty) 'text': message,
  });
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'تعذّر فتح واتساب. راسلنا على: ${Strings.supportWhatsapp}',
        ),
      ),
    );
  }
}

/// "تواصل مع الدعم على واتساب": one tap to the support chat.
class SupportWhatsAppButton extends StatelessWidget {
  const SupportWhatsAppButton({super.key, this.message, this.label});

  /// Text pre-filled in the chat.
  final String? message;
  final String? label;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => openSupportWhatsApp(context, message: message),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: AppColors.success,
      side: const BorderSide(color: AppColors.success),
    ),
    icon: const Icon(Icons.chat_rounded),
    label: Text(label ?? Strings.contactSupportWhatsapp),
  );
}
