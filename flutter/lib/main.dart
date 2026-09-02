import 'package:flutter/material.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/session_store.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/demo_accounts.dart';
import 'features/auth/login_screen.dart';
import 'features/queue/owner_dashboard_screen.dart';
import 'features/queue/queue_controller.dart';
import 'features/queue/store_list_screen.dart';

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
  // Lives for the app's process lifetime, standing in for real drift-backed
  // stores/purchases queries until issue #7 wires those up.
  final QueueController _controller = QueueController();

  /// null while the seed/session check is in flight, then the restored user
  /// (skip straight past login) or null-after-load to mean "show login".
  DemoUser? _restoredUser;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await widget.authRepository.ensureSeeded();
    final userId = await widget.sessionStore.loadUserId();
    final user = userId == null ? null : await widget.authRepository.findById(userId);
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _restoredUser = user == null
          ? null
          : DemoUser(
              phone: user.phone,
              pin: '',
              role: user.role == 'owner' ? UserRole.owner : UserRole.buyer,
              name: user.name,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رغيف',
      theme: AppTheme.light,
      // Forced RTL regardless of device locale — this app is Arabic-only.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Builder(
        builder: (context) {
          if (_restoring) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final restored = _restoredUser;
          if (restored != null) {
            return restored.role == UserRole.owner
                ? OwnerDashboardScreen(
                    controller: _controller,
                    storeId: demoOwnerStoreId,
                  )
                : StoreListScreen(controller: _controller, currentUser: restored);
          }
          return LoginScreen(
            authRepository: widget.authRepository,
            sessionStore: widget.sessionStore,
            onLoginBuyer: (user) => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: StoreListScreen.routeName),
                builder: (_) =>
                    StoreListScreen(controller: _controller, currentUser: user),
              ),
            ),
            onLoginOwner: (user) => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(
                  name: OwnerDashboardScreen.routeName,
                ),
                builder: (_) => OwnerDashboardScreen(
                  controller: _controller,
                  storeId: demoOwnerStoreId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
