import 'package:flutter_test/flutter_test.dart';
import 'package:safeapartment/src/models/alert.dart';
import 'package:safeapartment/src/models/user.dart';
import 'package:safeapartment/src/models/device.dart';

void main() {
  group('Alert Model', () {
    test('creates alert with correct threat type', () {
      final alert = Alert(
        id: '1',
        deviceId: 'device1',
        threatType: ThreatType.intruder,
        confidence: 0.95,
      );
      expect(alert.threatType, ThreatType.intruder);
      expect(alert.confidenceLabel, '95%');
      expect(alert.isViewed, false);
    });

    test('toJson and fromJson roundtrip', () {
      final alert = Alert(
        id: '1',
        deviceId: 'device1',
        threatType: ThreatType.fire,
        confidence: 0.85,
        mediaUrl: 'https://example.com/video.mp4',
      );
      final json = alert.toJson();
      final restored = Alert.fromJson(json);
      expect(restored.id, alert.id);
      expect(restored.threatType, alert.threatType);
      expect(restored.confidence, alert.confidence);
    });

    test('copyWith updates fields', () {
      final alert = Alert(
        id: '1',
        deviceId: 'device1',
        threatType: ThreatType.intruder,
        confidence: 0.9,
      );
      final updated = alert.copyWith(isConfirmed: true, isViewed: true);
      expect(updated.isConfirmed, true);
      expect(updated.isViewed, true);
      expect(updated.id, alert.id);
    });
  });

  group('User Model', () {
    test('premium tier checks', () {
      final freeUser = AppUser(id: '1', phone: '+254700000000');
      expect(freeUser.isPremium, false);
      expect(freeUser.premiumActive, false);

      final premiumUser = AppUser(
        id: '2',
        phone: '+254700000001',
        premiumTier: 'premium',
        premiumExpiry: DateTime.now().add(const Duration(days: 30)),
      );
      expect(premiumUser.isPremium, true);
      expect(premiumUser.premiumActive, true);
    });

    test('toJson and fromJson roundtrip', () {
      final user = AppUser(
        id: '1',
        phone: '+254700000000',
        email: 'test@example.com',
        fullName: 'Test User',
        premiumTier: 'premium',
      );
      final json = user.toJson();
      final restored = AppUser.fromJson(json);
      expect(restored.id, user.id);
      expect(restored.phone, user.phone);
      expect(restored.email, user.email);
    });
  });

  group('Device Model', () {
    test('role checks', () {
      final monitor = Device(
        id: '1',
        userId: 'user1',
        deviceName: 'Living Room',
        deviceType: 'android',
        deviceRole: 'monitor',
      );
      expect(monitor.isMonitor, true);
      expect(monitor.isReceiver, false);
    });
  });

  group('ThreatType', () {
    test('intruder is free tier', () {
      expect(ThreatType.intruder.isFree, true);
      expect(ThreatType.fire.isFree, false);
    });

    test('all threat types have labels', () {
      for (final type in ThreatType.values) {
        expect(type.label.isNotEmpty, true);
      }
    });
  });
}
