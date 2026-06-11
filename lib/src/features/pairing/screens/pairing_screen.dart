import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final List<Map<String, String>> _pairedDevices = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paired Devices'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.wifi_tethering,
                    size: 64,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pair a Device',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect another device to receive alerts\n'
                    'works via WiFi Direct or cloud',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _startPairing,
                      icon: Icon(_isSearching ? Icons.sync : Icons.search),
                      label: Text(_isSearching
                          ? 'Searching...'
                          : 'Find Nearby Devices'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_pairedDevices.isNotEmpty) ...[
            Text(
              'Paired Devices (${_pairedDevices.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._pairedDevices.map((device) => _DeviceCard(device: device)),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No devices paired',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Find Nearby Devices" to pair',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startPairing() {
    setState(() => _isSearching = true);

    // Simulate device discovery
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _pairedDevices.add({
            'name': 'Living Room Phone',
            'type': 'Android',
            'status': 'Receiver',
          });
          _pairedDevices.add({
            'name': 'Kitchen Phone',
            'type': 'iPhone',
            'status': 'Receiver',
          });
        });
      }
    });
  }
}

class _DeviceCard extends StatelessWidget {
  final Map<String, String> device;

  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.successColor.withOpacity(0.1),
          child: Icon(
            device['type'] == 'iPhone' ? Icons.phone_iphone : Icons.phone_android,
            color: AppTheme.successColor,
          ),
        ),
        title: Text(device['name'] ?? ''),
        subtitle: Text('${device['type']} • ${device['status']}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device['name']} removed'),
                ),
              );
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'swap',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 20),
                  SizedBox(width: 8),
                  Text('Swap Roles'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
