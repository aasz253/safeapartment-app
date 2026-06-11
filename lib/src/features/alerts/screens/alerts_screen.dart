import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/alert.dart';
import '../../../core/theme.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(alertProvider.notifier).loadAlerts(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              for (final a in alerts) {
                ref.read(alertProvider.notifier).markViewed(a.id);
              }
            },
          ),
        ],
      ),
      body: alerts.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _AlertCard(alert: alert);
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppTheme.successColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No alerts yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your apartment is secure',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _threatColor(alert.threatType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(alertProvider.notifier).markViewed(alert.id);
          _showAlertDetail(context, ref, alert);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _threatIcon(alert.threatType),
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alert.threatType.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (!alert.isViewed) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${alert.confidenceLabel}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatTime(alert.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: alert.isConfirmed == null
                      ? Colors.orange.withOpacity(0.1)
                      : alert.isConfirmed == true
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.isConfirmed == null
                      ? 'Pending'
                      : alert.isConfirmed == true
                          ? 'Real'
                          : 'False',
                  style: TextStyle(
                    fontSize: 11,
                    color: alert.isConfirmed == null
                        ? Colors.orange
                        : alert.isConfirmed == true
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _threatColor(ThreatType type) {
    switch (type) {
      case ThreatType.intruder: return Colors.orange;
      case ThreatType.glass: return Colors.purple;
      case ThreatType.fire: return Colors.red;
      case ThreatType.gas: return Colors.amber;
      case ThreatType.flood: return Colors.blue;
      case ThreatType.earthquake: return Colors.brown;
    }
  }

  IconData _threatIcon(ThreatType type) {
    switch (type) {
      case ThreatType.intruder: return Icons.person_outline;
      case ThreatType.glass: return Icons.broken_image_outlined;
      case ThreatType.fire: return Icons.whatshot_outlined;
      case ThreatType.gas: return Icons.gas_meter_outlined;
      case ThreatType.flood: return Icons.water_drop_outlined;
      case ThreatType.earthquake: return Icons.landslide_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showAlertDetail(BuildContext context, WidgetRef ref, Alert alert) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${alert.threatType.label} Alert',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _detailRow('Confidence', alert.confidenceLabel),
            _detailRow('Time', _formatTime(alert.createdAt)),
            if (alert.mediaUrl != null)
              _detailRow('Recording', alert.mediaUrl!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(alertProvider.notifier).confirmAlert(
                        alert.id,
                        false,
                      );
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('False Alarm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(alertProvider.notifier).confirmAlert(
                        alert.id,
                        true,
                      );
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Real Threat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
