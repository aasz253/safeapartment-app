# SafeApartment

**Zero-hardware home security - just your smartphone.**

SafeApartment turns any smartphone into a professional security system for apartment dwellers. No additional sensors, cameras, or hardware needed.

[![]()]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()

## Features

### Free Tier
- **Intruder Motion Detection** - Camera frame differencing every 500ms, records 10s video clips
- **Local Notifications** - Instant alert when motion is detected
- **Telegram Bot Alerts** - Free unlimited bot messages (optional setup)

### Premium Tier
All free features plus:

| Feature | How It Works |
|---|---|
| **Glass Break Detection** | FFT audio analysis (2-5kHz spike + sharp attack/decay pattern) |
| **Fire Detection** | Visual CNN (orange/red pixel analysis) + smoke alarm audio pattern |
| **Gas Leak Detection** | MFCC audio features - train on your LPG cylinder, MLP classifier |
| **Flood Detection** | Water sound analysis + accelerometer orientation change |
| **Earthquake Detection** | P-wave accelerometer monitoring with 10s countdown |
| **Cloud Recording** | 30-day rolling storage via Supabase |
| **Multi-Device Pairing** | Up to 5 devices per account |

### Peer-to-Peer Alerting (All Tiers)
- WebRTC-based live video streaming between paired devices
- Works during internet outage (WiFi Direct mode)
- Supabase Realtime signaling
- Fallback to cloud push when P2P unavailable

## Screenshots

<!-- Add screenshots here once available -->

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.16+ (Dart 3.0+) |
| State Management | Riverpod 2.4+ |
| Backend / Database | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| Local Storage | Hive 4.0 |
| ML / Audio | Custom FFT, MFCC, TensorFlow Lite (FireNet) |
| Peer-to-Peer | WebRTC (`flutter_webrtc`) |
| Push Alerts | Firebase Cloud Messaging + `flutter_local_notifications` |
| Subscriptions | Supabase-managed (no third-party processor) |

## Setup

### Prerequisites
- Flutter SDK (install via `snap install flutter --classic`)
- Android Studio / Xcode for platform builds
- A Supabase account (free tier)

### 1. Clone & Install

```bash
git clone https://github.com/aasz253/safeapartment-app.git
cd safeapartment-app
flutter pub get
```

### 2. Configure Supabase

Create a Supabase project at [supabase.com](https://supabase.com), then run this SQL in the SQL Editor:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  phone TEXT UNIQUE NOT NULL,
  full_name TEXT,
  premium_tier TEXT DEFAULT 'free',
  premium_expiry TIMESTAMP,
  stripe_customer_id TEXT,
  telegram_chat_id TEXT,
  emergency_contact TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Devices table
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  device_name TEXT NOT NULL,
  device_type TEXT NOT NULL,
  device_role TEXT DEFAULT 'monitor',
  is_active BOOLEAN DEFAULT true,
  last_seen TIMESTAMP,
  current_location TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Alerts table
CREATE TABLE alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id),
  threat_type TEXT NOT NULL,
  confidence REAL NOT NULL,
  media_url TEXT,
  thumbnail_url TEXT,
  is_confirmed BOOLEAN DEFAULT false,
  is_viewed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Push tokens table
CREATE TABLE push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  token TEXT NOT NULL,
  platform TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true
);

-- Family groups
CREATE TABLE family_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES users(id),
  group_name TEXT,
  max_devices INT DEFAULT 5,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Family members
CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES family_groups(id),
  user_id UUID REFERENCES users(id),
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMP DEFAULT NOW()
);

-- Buildings (B2B)
CREATE TABLE buildings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES users(id),
  building_name TEXT,
  address TEXT,
  total_units INT,
  subscription_tier TEXT DEFAULT 'building',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Building units
CREATE TABLE building_units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  building_id UUID REFERENCES buildings(id),
  unit_number TEXT NOT NULL,
  tenant_id UUID REFERENCES users(id),
  is_monitored BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can read own devices" ON devices
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can read own alerts" ON alerts
  FOR SELECT USING (
    device_id IN (SELECT id FROM devices WHERE user_id = auth.uid())
  );
```

### 3. Configure Firebase Cloud Messaging (FCM)

FCM delivers push notifications between paired devices — free, no payment required.

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a project (or use your existing Google project)
3. Register an Android app with package name `com.safeapartment.app`
4. Download `google-services.json` and place in `android/app/`
5. Register an iOS app with bundle ID `com.safeapartment.app`
6. Download `GoogleService-Info.plist` and place in `ios/Runner/`
7. Enable **Cloud Messaging** API in the Firebase console

### 4. Set API Keys

The Supabase URL and anon key are already configured in `lib/src/core/constants.dart` with your project values. If starting fresh, replace them:

```dart
// lib/src/core/constants.dart
static const String supabaseUrl = 'https://YOUR-PROJECT.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

**For Android:** Add this classpath to `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

Then add the plugin to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 5. Run

```bash
flutter run
```

For Android:
```bash
flutter run --release
```

For iOS:
```bash
flutter run --release --no-codesign  # or with proper signing
```

## Project Structure

```
lib/
├── main.dart                        # Entry point
├── app.dart                         # App widget with routing
└── src/
    ├── core/
    │   ├── constants.dart           # App-wide constants
    │   └── theme.dart               # Light/dark theme
    ├── models/
    │   ├── user.dart                # User model
    │   ├── device.dart              # Device + family models
    │   └── alert.dart               # Alert model + ThreatType enum
    ├── services/
    │   ├── supabase_service.dart    # Supabase client wrapper
    │   ├── camera_service.dart      # Camera + motion detection
    │   ├── audio_service.dart       # Microphone + FFT + sound analysis
    │   ├── sensor_service.dart      # Accelerometer + earthquake + flood
    │   ├── notification_service.dart # Local push notifications
    │   ├── storage_service.dart     # Local + cloud file management
    │   ├── telegram_service.dart    # Telegram bot API integration
    │   └── webrtc_service.dart      # WebRTC peer-to-peer streaming
    ├── providers/
    │   ├── auth_provider.dart       # Phone OTP authentication
    │   ├── subscription_provider.dart # Premium tier management
    │   ├── monitoring_provider.dart  # Orchestrates all detectors
    │   └── alert_provider.dart       # Alert state management
    └── features/
        ├── auth/screens/login_screen.dart
        ├── dashboard/screens/dashboard_screen.dart
        ├── monitoring/
        │   ├── screens/monitoring_screen.dart
        │   └── detectors/
        │       ├── glass_break_detector.dart
        │       ├── fire_detector.dart
        │       └── gas_leak_detector.dart
        ├── alerts/screens/alerts_screen.dart
        ├── settings/screens/settings_screen.dart
        ├── subscription/screens/paywall_screen.dart
        └── pairing/screens/pairing_screen.dart
```

## Detectors Explained

### Motion Detection
Frame differencing on the camera feed every 500ms. If >15% of sampled pixels changed, triggers a 10-second video recording at 720p / 5fps.

### Glass Break
FFT analysis every 100ms looking for a 2-5kHz frequency spike with a sharp attack (<10ms) followed by 200ms decay. Filters out similar frequencies like keys jingling.

### Fire Detection
Camera frame analysis at 1fps looking for orange/red pixels (R>200, G<150, B<100). Simultaneously listens for smoke alarm pattern: 3 beeps × 0.5s with 1.5s pause.

### Gas Leak
Training mode records 5s of gas hiss, extracts 13 MFCC coefficients. Real-time audio compared via Euclidean distance to trained signature. Confidence >75% for 2 consecutive readings triggers alert.

### Flood Detection
Phone placed face-down on floor. Microphone monitors for water sounds (500-1500Hz splashing, broadband 100-4000Hz flow). Accelerometer detects sudden orientation change >15° or sustained vibration >5s.

### Earthquake Detection
Accelerometer at 50Hz. P-wave detected when lateral acceleration is 0.2-0.5g for 0.5-2s with oscillatory decay pattern (3+ zero crossings). Shows 10s countdown before S-wave arrival.

## Business Model

| Tier | Price | Features |
|---|---|---|
| **Free** | $0 | Motion detection, 1 device, local storage, Telegram alerts, P2P |
| **Premium** | $3/mo or $30/yr | All 6 detectors, cloud recording, SMS, multi-device receiver |
| **Family** | $8/mo | Up to 5 monitoring devices, building dashboard |

Subscription status is managed via the `users.premium_tier` column in Supabase.

## Testing

```bash
flutter test
```

## License

MIT

## Built For

Emerging markets (Kenya, India, Nigeria, Brazil, Philippines, Indonesia, Vietnam) where traditional security systems are unaffordable but smartphone penetration is high.
