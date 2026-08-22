import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const RaghifApp());
}

class RaghifApp extends StatelessWidget {
  const RaghifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رغيف',
      theme: AppTheme.light,
      // Forced RTL regardless of device locale — this app is Arabic-only.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: LoginScreen(
        onLoginBuyer: () => _showStub(context, 'قائمة المخابز'),
        onLoginOwner: () => _showStub(context, 'لوحة صاحب المخبز'),
      ),
    );
  }

  // Store list / owner dashboard screens are follow-up work — this slice
  // ports the scaffold plus the login screen only.
  void _showStub(BuildContext context, String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$destination — قريباً')),
    );
  }
}
