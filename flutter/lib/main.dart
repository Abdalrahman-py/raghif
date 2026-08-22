import 'package:flutter/material.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/session_store.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  final db = AppDatabase();
  runApp(RaghifApp(authRepository: AuthRepository(db), sessionStore: SessionStore()));
}

class RaghifApp extends StatefulWidget {
  const RaghifApp({
    super.key,
    required this.authRepository,
    required this.sessionStore,
  });

  final AuthRepository authRepository;
  final SessionStore sessionStore;

  @override
  State<RaghifApp> createState() => _RaghifAppState();
}

class _RaghifAppState extends State<RaghifApp> {
  /// null while the seed/session check is in flight, then either a restored
  /// user id (skip straight past login) or -1 to mean "show login".
  int? _restoredUserId;
  static const _noSession = -1;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await widget.authRepository.ensureSeeded();
    final userId = await widget.sessionStore.loadUserId();
    if (!mounted) return;
    setState(() => _restoredUserId = userId ?? _noSession);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رغيف',
      theme: AppTheme.light,
      // Forced RTL regardless of device locale — this app is Arabic-only.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: _restoredUserId == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _restoredUserId == _noSession
          ? LoginScreen(
              authRepository: widget.authRepository,
              sessionStore: widget.sessionStore,
              onLoginBuyer: () => _showStub(context, 'قائمة المخابز'),
              onLoginOwner: () => _showStub(context, 'لوحة صاحب المخبز'),
            )
          // Restored session — skip straight past login. The screen it
          // lands on (store list vs. owner dashboard) is follow-up work,
          // so this slice just confirms the session held.
          : const Scaffold(
              body: Center(child: Text('تم تسجيل الدخول — قائمة المخابز قريباً')),
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
