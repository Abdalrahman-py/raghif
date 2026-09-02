import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/queue/owner_dashboard_screen.dart';
import 'features/queue/queue_controller.dart';
import 'features/queue/store_list_screen.dart';

void main() {
  runApp(RaghifApp());
}

class RaghifApp extends StatelessWidget {
  RaghifApp({super.key});

  // Lives for the app's process lifetime, standing in for the SQLDelight
  // database until issue #7 wires real on-device persistence.
  final QueueController _controller = QueueController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رغيف',
      theme: AppTheme.light,
      // Forced RTL regardless of device locale — this app is Arabic-only.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: LoginScreen(
        onLoginBuyer: (user) => Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: StoreListScreen.routeName),
            builder: (_) =>
                StoreListScreen(controller: _controller, currentUser: user),
          ),
        ),
        onLoginOwner: (user) => Navigator.of(context).push(
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
      ),
    );
  }
}
