import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';

class SubscriptionNotifier extends StateNotifier<bool> {
  final SupabaseService _supabase;
  final Ref _ref;

  SubscriptionNotifier(this._supabase, this._ref) : super(false);

  Future<bool> isPremium() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    return user.premiumActive;
  }

  Future<void> upgradeToPremium(String tier) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    await _supabase.updateUser(user.id, {
      'premium_tier': tier,
      'premium_expiry': DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String(),
    });

    state = true;
  }

  Future<void> downgradeToFree() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    await _supabase.updateUser(user.id, {
      'premium_tier': 'free',
      'premium_expiry': null,
    });

    state = false;
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, bool>((ref) {
  return SubscriptionNotifier(
    ref.read(supabaseServiceProvider),
    ref,
  );
});

final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.premiumActive ?? false;
});
