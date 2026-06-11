import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/subscription_provider.dart';
import '../../../core/constants.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selectedPlan = 'monthly';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Full protection for your apartment',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Features
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.person_outline,
                      title: 'Intruder Motion Detection',
                      subtitle: 'Camera-based motion alerts',
                      included: true,
                    ),
                    _FeatureRow(
                      icon: Icons.broken_image_outlined,
                      title: 'Glass Break Detection',
                      subtitle: 'Audio frequency analysis',
                      included: true,
                    ),
                    _FeatureRow(
                      icon: Icons.whatshot_outlined,
                      title: 'Fire Detection',
                      subtitle: 'Visual + audio smoke alarm',
                      included: true,
                    ),
                    _FeatureRow(
                      icon: Icons.gas_meter_outlined,
                      title: 'Gas Leak Detection',
                      subtitle: 'Train on your LPG cylinder',
                      included: true,
                    ),
                    _FeatureRow(
                      icon: Icons.water_drop_outlined,
                      title: 'Flood Detection',
                      subtitle: 'Water sound + orientation',
                      included: true,
                    ),
                    _FeatureRow(
                      icon: Icons.landslide_outlined,
                      title: 'Earthquake Detection',
                      subtitle: 'Accelerometer P-wave',
                      included: true,
                    ),
                    _FeatureRow(
                      icon: Icons.cloud_upload_outlined,
                      title: '30-Day Cloud Recording',
                      subtitle: 'Auto-upload & share',
                      included: true,
                    ),
                    _FeatureRow(
                      icon: Icons.devices,
                      title: 'Multi-Device Support',
                      subtitle: 'Up to 5 devices',
                      included: true,
                    ),

                    const SizedBox(height: 32),

                    // Plan selector
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PlanButton(
                              label: 'Monthly',
                              price: '\$${AppConstants.premiumMonthlyPrice}',
                              isSelected: _selectedPlan == 'monthly',
                              onTap: () => setState(() => _selectedPlan = 'monthly'),
                            ),
                          ),
                          Expanded(
                            child: _PlanButton(
                              label: 'Yearly',
                              price: '\$${AppConstants.premiumYearlyPrice}',
                              sublabel: 'Save 17%',
                              isSelected: _selectedPlan == 'yearly',
                              onTap: () => setState(() => _selectedPlan = 'yearly'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Family plan
                    InkWell(
                      onTap: () => setState(() => _selectedPlan = 'family'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPlan == 'family'
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: _selectedPlan == 'family' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: _selectedPlan == 'family'
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Family / Building Plan',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Up to 5 monitoring devices',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${AppConstants.familyMonthlyPrice}/mo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedPlan == 'family'
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Subscribe button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _subscribe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2,
                              )
                            : Text(
                                _selectedPlan == 'monthly'
                                    ? 'Subscribe \$${AppConstants.premiumMonthlyPrice}/mo'
                                    : _selectedPlan == 'yearly'
                                        ? 'Subscribe \$${AppConstants.premiumYearlyPrice}/yr'
                                        : 'Subscribe \$${AppConstants.familyMonthlyPrice}/mo',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Cancel anytime • No questions asked',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);

    try {
      final tier = _selectedPlan == 'family' ? 'family' : 'premium';
      await ref.read(subscriptionProvider.notifier).upgradeToPremium(tier);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Premium!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool included;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.included,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            included ? Icons.check : Icons.close,
            color: included ? AppTheme.successColor : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PlanButton extends StatelessWidget {
  final String label;
  final String price;
  final String? sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanButton({
    required this.label,
    required this.price,
    this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sublabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
