import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/monitoring_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../core/theme.dart';
import '../../../services/camera_service.dart';
import '../../subscription/screens/paywall_screen.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(monitoringProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isMonitoring = monitoringState == MonitoringState.active;
    final isAlert = monitoringState == MonitoringState.alert;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeApartment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showStatusInfo(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview background
          if (isMonitoring)
            _CameraPreview()
          else
            _IdleBackground(),

          // Status overlay
          Column(
            children: [
              const Spacer(),
              _StatusCard(
                isMonitoring: isMonitoring,
                isAlert: isAlert,
                isPremium: isPremium,
              ),
              const SizedBox(height: 24),
              _MonitoringControls(
                isMonitoring: isMonitoring,
                onToggle: () => _toggleMonitoring(),
              ),
              if (!isPremium && !isMonitoring) ...[
                const SizedBox(height: 16),
                _PremiumTeaser(
                  onUpgrade: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMonitoring() async {
    final notifier = ref.read(monitoringProvider.notifier);
    if (notifier.isMonitoring) {
      await notifier.stopMonitoring();
    } else {
      await notifier.startMonitoring();
    }
  }

  void _showStatusInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monitoring Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Motion Detection', true),
            _infoRow('Glass Break', false),
            _infoRow('Fire Detection', false),
            _infoRow('Gas Leak', false),
            _infoRow('Flood Detection', false),
            _infoRow('Earthquake', false),
            const SizedBox(height: 16),
            Text(
              'Active sensors are shown in green. '
              'Upgrade to Premium for all detectors.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: active ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _CameraPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraSvc = ref.watch(cameraServiceProvider);
    final controller = cameraSvc.controller;

    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return ClipRRect(
      child: CameraPreview(controller),
    );
  }
}

class _IdleBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            Colors.black87,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your apartment is not being monitored',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to start',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isMonitoring;
  final bool isAlert;
  final bool isPremium;

  const _StatusCard({
    required this.isMonitoring,
    required this.isAlert,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Security Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAlert
                        ? Colors.red
                        : isMonitoring
                            ? Colors.green
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAlert
                        ? 'ALERT'
                        : isMonitoring
                            ? 'ACTIVE'
                            : 'OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _sensorStatus(Icons.person_outline, 'Motion', true),
                _sensorStatus(Icons.broken_image_outlined, 'Glass', isPremium),
                _sensorStatus(Icons.whatshot_outlined, 'Fire', isPremium),
                _sensorStatus(Icons.gas_meter_outlined, 'Gas', isPremium),
                _sensorStatus(Icons.water_drop_outlined, 'Flood', isPremium),
                _sensorStatus(Icons.landslide_outlined, 'Quake', isPremium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorStatus(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: active ? AppTheme.successColor : Colors.grey[400],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppTheme.successColor : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

class _MonitoringControls extends StatelessWidget {
  final bool isMonitoring;
  final VoidCallback onToggle;

  const _MonitoringControls({
    required this.isMonitoring,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton.large(
        onPressed: onToggle,
        backgroundColor: isMonitoring ? Colors.red : AppTheme.successColor,
        child: Icon(
          isMonitoring ? Icons.stop : Icons.play_arrow,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class _PremiumTeaser extends StatelessWidget {
  final VoidCallback onUpgrade;

  const _PremiumTeaser({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: AppTheme.warningColor.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.workspace_premium, color: AppTheme.warningColor),
        title: const Text('Get Premium'),
        subtitle: const Text('Unlock all 6 threat detectors'),
        trailing: TextButton(
          onPressed: onUpgrade,
          child: const Text('Upgrade'),
        ),
      ),
    );
  }
}
