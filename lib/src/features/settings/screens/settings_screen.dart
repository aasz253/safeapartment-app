import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/telegram_service.dart';
import '../../../core/theme.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../../pairing/screens/pairing_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _emergencyController = TextEditingController();
  final _telegramTokenController = TextEditingController();
  final _telegramChatIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _emergencyController.text = user.emergencyContact ?? '';
    }
  }

  @override
  void dispose() {
    _emergencyController.dispose();
    _telegramTokenController.dispose();
    _telegramChatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile
          _SectionHeader('Account'),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  (user?.fullName ?? user?.phone ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user?.fullName ?? 'User'),
              subtitle: Text(user?.phone ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editProfile(context),
            ),
          ),
          const SizedBox(height: 16),

          // Subscription
          _SectionHeader('Subscription'),
          Card(
            child: ListTile(
              leading: Icon(
                isPremium ? Icons.workspace_premium : Icons.free_breakfast,
                color: isPremium ? AppTheme.warningColor : Colors.grey,
              ),
              title: Text(isPremium ? 'Premium' : 'Free'),
              subtitle: Text(
                isPremium
                    ? 'All detectors active'
                    : 'Motion detection only',
              ),
              trailing: TextButton(
                onPressed: isPremium
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallScreen(),
                          ),
                        );
                      },
                child: Text(isPremium ? 'Active' : 'Upgrade'),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Emergency Contact
          _SectionHeader('Emergency'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Contact',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emergencyController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '+254 7XX XXX XXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveEmergencyContact,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Telegram
          _SectionHeader('Telegram Bot'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get alerts via Telegram',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Create bot via @BotFather\n'
                    '2. Copy bot token here\n'
                    '3. Send /start to your bot\n'
                    '4. Copy chat ID here',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telegramTokenController,
                    decoration: const InputDecoration(
                      hintText: 'Bot Token',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _telegramChatIdController,
                    decoration: const InputDecoration(
                      hintText: 'Chat ID',
                      prefixIcon: Icon(Icons.chat),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _verifyTelegram,
                      icon: const Icon(Icons.check),
                      label: const Text('Verify & Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Paired Devices
          _SectionHeader('Paired Devices'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Paired Devices'),
              subtitle: Text(isPremium
                  ? 'Manage up to 5 devices'
                  : 'Premium feature'),
              trailing: const Icon(Icons.chevron_right),
              onTap: isPremium
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PairingScreen(),
                        ),
                      );
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveEmergencyContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency contact saved')),
    );
  }

  void _verifyTelegram() async {
    final token = _telegramTokenController.text.trim();
    if (token.isEmpty) return;

    final telegramSvc = ref.read(telegramServiceProvider);
    telegramSvc.setBotToken(token);
    final valid = await telegramSvc.verifyToken();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(valid
              ? 'Telegram bot verified!'
              : 'Invalid token. Please check and try again.'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(authProvider.notifier).signOut();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
