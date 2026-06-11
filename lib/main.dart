import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'app.dart';
import 'src/core/constants.dart';
import 'src/services/supabase_service.dart';
import 'src/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize OneSignal
  OneSignal.initialize(AppConstants.oneSignalAppId);

  // Initialize RevenueCat
  await Purchases.setup(AppConstants.revenueCatApiKey);

  runApp(const ProviderScope(child: SafeApartmentApp()));
}
