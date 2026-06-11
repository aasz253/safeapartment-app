import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../models/alert.dart';
import '../models/device.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Auth
  Future<AuthResponse> signInWithOtp(String phone) async {
    return await _client.auth.signInWithOTP(phone: phone);
  }

  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _client.auth.verifyOTP(phone: phone, token: token);
  }

  Future<AuthResponse> signInWithGoogle(String idToken) async {
    return await _client.auth.signInWithIdToken(
      provider: Provider.google,
      idToken: idToken,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authState => _client.auth.onAuthStateChange;

  // Users
  Future<AppUser?> getUser(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return AppUser.fromJson(response);
  }

  Future<void> createUser(AppUser user) async {
    await _client.from('users').insert(user.toJson());
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', userId);
  }

  // Devices
  Future<List<Device>> getUserDevices(String userId) async {
    final response = await _client
        .from('devices')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return response.map((d) => Device.fromJson(d)).toList();
  }

  Future<void> registerDevice(Device device) async {
    await _client.from('devices').insert(device.toJson());
  }

  Future<void> updateDevice(String deviceId, Map<String, dynamic> data) async {
    await _client.from('devices').update(data).eq('id', deviceId);
  }

  Future<void> updateDeviceLocation(String deviceId, double lat, double lng) async {
    await _client.rpc('update_device_location', params: {
      'p_device_id': deviceId,
      'p_latitude': lat,
      'p_longitude': lng,
    });
  }

  // Alerts
  Future<List<Alert>> getAlerts(String deviceId, {int limit = 50}) async {
    final response = await _client
        .from('alerts')
        .select()
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(limit);
    return response.map((a) => Alert.fromJson(a)).toList();
  }

  Future<void> createAlert(Alert alert) async {
    await _client.from('alerts').insert(alert.toJson());
  }

  Future<void> confirmAlert(String alertId, bool isConfirmed) async {
    await _client
        .from('alerts')
        .update({'is_confirmed': isConfirmed})
        .eq('id', alertId);
  }

  Future<void> markAlertViewed(String alertId) async {
    await _client
        .from('alerts')
        .update({'is_viewed': true})
        .eq('id', alertId);
  }

  // Storage
  Future<String> uploadVideo(String userId, String filePath) async {
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
    await _client.storage.from('videos').upload(fileName, filePath);
    final url = _client.storage.from('videos').getPublicUrl(fileName);
    return url;
  }

  Future<String> uploadPhoto(String userId, String filePath) async {
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('photos').upload(fileName, filePath);
    return _client.storage.from('photos').getPublicUrl(fileName);
  }

  // Realtime
  RealtimeChannel createAlertChannel(String deviceId) {
    return _client
        .channel('alerts:$deviceId')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'alerts',
            filter: 'device_id=eq.$deviceId',
          ),
          (payload) {},
        )
        .subscribe();
  }

  RealtimeChannel createSignalingChannel(String roomId) {
    return _client.channel('signaling:$roomId', opts: const RealtimeChannelConfig(
      selfBroadcast: true,
    )).subscribe();
  }

  // Edge functions
  Future<void> triggerSubscriptionExpiryCheck() async {
    await _client.functions.invoke('check-subscription-expiry');
  }
}
