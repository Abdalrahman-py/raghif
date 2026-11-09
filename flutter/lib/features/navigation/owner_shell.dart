import 'package:flutter/material.dart';

import '../../core/widgets/app_bottom_bar.dart';
import '../queue/owner_customers_screen.dart';
import '../queue/owner_dashboard_screen.dart';
import '../queue/owner_history_screen.dart';
import '../queue/queue_controller.dart';

/// The bakery owner's home, with the same bottom tabs the buyer has:
/// الرئيسية (today's stock, hours, the queue), سجل الزبائن, سجل المبيعات.
///
/// A tab's screen is rebuilt when it is selected, so the customer and sales
/// lists are read fresh each time rather than kept from the first visit.
class OwnerShell extends StatefulWidget {
  const OwnerShell({
    super.key,
    required this.controller,
    required this.storeId,
  });

  final QueueController controller;
  final String storeId;

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _index == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _index != 0) setState(() => _index = 0);
    },
    child: Scaffold(
      body: switch (_index) {
        0 => OwnerDashboardScreen(
          controller: widget.controller,
          storeId: widget.storeId,
        ),
        1 => OwnerCustomersScreen(
          controller: widget.controller,
          storeId: widget.storeId,
        ),
        _ => OwnerHistoryScreen(
          controller: widget.controller,
          storeId: widget.storeId,
        ),
      },
      bottomNavigationBar: AppBottomBar(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'سجل الزبائن',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'سجل المبيعات',
          ),
        ],
      ),
    ),
  );
}
