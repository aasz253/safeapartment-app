class Device {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String deviceRole;
  final bool isActive;
  final DateTime? lastSeen;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    this.deviceRole = 'monitor',
    this.isActive = true,
    this.lastSeen,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isMonitor => deviceRole == 'monitor' || deviceRole == 'both';
  bool get isReceiver => deviceRole == 'receiver' || deviceRole == 'both';

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'device_name': deviceName,
    'device_type': deviceType,
    'device_role': deviceRole,
    'is_active': isActive,
    'last_seen': lastSeen?.toIso8601String(),
    'current_location': latitude != null && longitude != null
        ? 'POINT($longitude $latitude)'
        : null,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    deviceName: json['device_name'] as String,
    deviceType: json['device_type'] as String,
    deviceRole: json['device_role'] as String? ?? 'monitor',
    isActive: json['is_active'] as bool? ?? true,
    lastSeen: json['last_seen'] != null
        ? DateTime.parse(json['last_seen'] as String)
        : null,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );
}

class FamilyGroup {
  final String id;
  final String ownerId;
  final String groupName;
  final int maxDevices;
  final DateTime createdAt;

  FamilyGroup({
    required this.id,
    required this.ownerId,
    required this.groupName,
    this.maxDevices = 5,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class Building {
  final String id;
  final String ownerId;
  final String buildingName;
  final String? address;
  final int totalUnits;
  final String subscriptionTier;

  Building({
    required this.id,
    required this.ownerId,
    required this.buildingName,
    this.address,
    this.totalUnits = 0,
    this.subscriptionTier = 'building',
  });
}

class BuildingUnit {
  final String id;
  final String buildingId;
  final String unitNumber;
  final String? tenantId;
  final bool isMonitored;

  BuildingUnit({
    required this.id,
    required this.buildingId,
    required this.unitNumber,
    this.tenantId,
    this.isMonitored = false,
  });
}
