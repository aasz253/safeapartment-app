import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme.dart';
import 'src/providers/auth_provider.dart';
import 'src/features/auth/screens/login_screen.dart';
import 'src/features/dashboard/screens/dashboard_screen.dart';

class SafeApartmentApp extends ConsumerWidget {
  const SafeApartmentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'SafeApartment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState == AuthState.authenticated
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}
