import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';

enum AuthState { unauthenticated, loading, authenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabase;

  AuthNotifier(this._supabase) : super(AuthState.unauthenticated);

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => state == AuthState.authenticated;

  Future<void> sendOtp(String phone) async {
    state = AuthState.loading;
    try {
      await _supabase.signInWithOtp(phone);
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    state = AuthState.loading;
    try {
      final response = await _supabase.verifyOtp(phone, code);
      final user = response.user;
      if (user != null) {
        _currentUser = AppUser(
          id: user.id,
          phone: user.phone ?? phone,
          email: user.email,
        );
        state = AuthState.authenticated;
      }
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.signOut();
    _currentUser = null;
    state = AuthState.unauthenticated;
  }

  Future<void> loadUser(String userId) async {
    state = AuthState.loading;
    try {
      _currentUser = await _supabase.getUser(userId);
      if (_currentUser != null) {
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (_) {
      state = AuthState.unauthenticated;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(supabaseServiceProvider));
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthNotifier ? auth.currentUser : null;
});
