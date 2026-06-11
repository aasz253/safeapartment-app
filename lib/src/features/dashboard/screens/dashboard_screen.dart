import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/alert_provider.dart';
import '../../core/theme.dart';
import '../monitoring/screens/monitoring_screen.dart';
import '../alerts/screens/alerts_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../subscription/screens/paywall_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final _screens = const [
    MonitoringScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadAlerts = ref.watch(unreadAlertsProvider);
    final monitoringState = ref.watch(monitoringProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Security',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadAlerts > 0,
              label: Text('$unreadAlerts'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadAlerts > 0,
              label: Text('$unreadAlerts'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: user != null && !user.premiumActive
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Upgrade'),
            )
          : null,
    );
  }
}
