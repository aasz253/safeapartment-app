class AppConstants {
  static const String appName = 'SafeApartment';
  static const String appVersion = '1.0.0';

  // Supabase
  static const String supabaseUrl = 'https://owmlbpposyjujyblyyrt.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_JNUkPNTaBzd5p53uYvNYlg_gDS1pcv4';

  // RevenueCat (replaced with Supabase-based subscription)
  // static const String revenueCatApiKey = '';

  // Pricing
  static const double premiumMonthlyPrice = 3.0;
  static const double premiumYearlyPrice = 30.0;
  static const double familyMonthlyPrice = 8.0;

  // Monitoring
  static const int motionCheckIntervalMs = 500;
  static const double motionThreshold = 0.15;
  static const int videoClipDurationSeconds = 10;
  static const int videoFps = 5;
  static const int videoClipRetentionDays = 7;

  // Glass break
  static const int glassBreakMinFreq = 2000;
  static const int glassBreakMaxFreq = 5000;
  static const double glassBreakConfidenceThreshold = 0.8;

  // Fire detection
  static const int fireCheckIntervalMs = 1000;

  // Gas detection
  static const int gasCheckIntervalMs = 500;
  static const double gasConfidenceThreshold = 0.75;

  // Flood detection
  static const double floodSoundConfidenceThreshold = 0.6;
  static const double floodOrientationThreshold = 15.0;

  // Earthquake
  static const int accelerometerSampleRateHz = 50;
  static const double earthquakePWaveMinG = 0.2;
  static const double earthquakePWaveMaxG = 0.5;

  // Cloud
  static const int cloudRetentionDays = 30;
  static const String videoCodec = 'H.264';

  // Pairing
  static const int maxFamilyDevices = 5;
  static const int maxBuildingUnits = 20;

  // Telegram
  static const String telegramApiBase = 'https://api.telegram.org/bot';

  // Peer-to-peer
  static const int p2pLatencyTargetMs = 500;
  static const String stunServer = 'stun:stun.l.google.com:19302';
}
