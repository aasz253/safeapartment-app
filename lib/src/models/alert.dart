enum ThreatType {
  intruder,
  glass,
  fire,
  gas,
  flood,
  earthquake;

  String get label {
    switch (this) {
      case ThreatType.intruder: return 'Intruder';
      case ThreatType.glass: return 'Glass Break';
      case ThreatType.fire: return 'Fire';
      case ThreatType.gas: return 'Gas Leak';
      case ThreatType.flood: return 'Flood';
      case ThreatType.earthquake: return 'Earthquake';
    }
  }

  String get iconAsset {
    switch (this) {
      case ThreatType.intruder: return 'person';
      case ThreatType.glass: return 'broken_image';
      case ThreatType.fire: return 'whatshot';
      case ThreatType.gas: return 'gas_meter';
      case ThreatType.flood: return 'water_drop';
      case ThreatType.earthquake: return 'landslide';
    }
  }

  bool get isFree {
    return this == ThreatType.intruder;
  }
}

class Alert {
  final String id;
  final String deviceId;
  final ThreatType threatType;
  final double confidence;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final bool isConfirmed;
  final bool isViewed;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.deviceId,
    required this.threatType,
    required this.confidence,
    this.mediaUrl,
    this.thumbnailUrl,
    this.isConfirmed = false,
    this.isViewed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get confidenceLabel => '${(confidence * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'threat_type': threatType.name,
    'confidence': confidence,
    'media_url': mediaUrl,
    'thumbnail_url': thumbnailUrl,
    'is_confirmed': isConfirmed,
    'is_viewed': isViewed,
  };

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'] as String,
    deviceId: json['device_id'] as String,
    threatType: ThreatType.values.firstWhere(
      (e) => e.name == json['threat_type'],
    ),
    confidence: (json['confidence'] as num).toDouble(),
    mediaUrl: json['media_url'] as String?,
    thumbnailUrl: json['thumbnail_url'] as String?,
    isConfirmed: json['is_confirmed'] as bool? ?? false,
    isViewed: json['is_viewed'] as bool? ?? false,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );

  Alert copyWith({
    bool? isConfirmed,
    bool? isViewed,
  }) => Alert(
    id: id,
    deviceId: deviceId,
    threatType: threatType,
    confidence: confidence,
    mediaUrl: mediaUrl,
    thumbnailUrl: thumbnailUrl,
    isConfirmed: isConfirmed ?? this.isConfirmed,
    isViewed: isViewed ?? this.isViewed,
    createdAt: createdAt,
  );
}
