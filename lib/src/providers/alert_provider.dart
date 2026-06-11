import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';

class AlertNotifier extends StateNotifier<List<Alert>> {
  final SupabaseService _supabase;
  final StorageService _storage;

  AlertNotifier(this._supabase, this._storage) : super([]);

  Future<void> loadAlerts(String deviceId) async {
    final alerts = await _supabase.getAlerts(deviceId, limit: 50);
    state = alerts;
  }

  Future<void> addAlert(Alert alert) async {
    await _supabase.createAlert(alert);
    state = [alert, ...state];
  }

  Future<void> confirmAlert(String alertId, bool isConfirmed) async {
    await _supabase.confirmAlert(alertId, isConfirmed);
    state = state.map((a) {
      if (a.id == alertId) return a.copyWith(isConfirmed: isConfirmed);
      return a;
    }).toList();
  }

  Future<void> markViewed(String alertId) async {
    await _supabase.markAlertViewed(alertId);
    state = state.map((a) {
      if (a.id == alertId) return a.copyWith(isViewed: true);
      return a;
    }).toList();
  }

  int get unreadCount => state.where((a) => !a.isViewed).length;
}

final alertProvider = StateNotifierProvider<AlertNotifier, List<Alert>>((ref) {
  return AlertNotifier(
    ref.read(supabaseServiceProvider),
    ref.read(storageServiceProvider),
  );
});

final unreadAlertsProvider = Provider<int>((ref) {
  return ref.watch(alertProvider).where((a) => !a.isViewed).length;
});
