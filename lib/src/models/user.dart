class AppUser {
  final String id;
  final String? email;
  final String phone;
  final String? fullName;
  final String premiumTier;
  final DateTime? premiumExpiry;
  final String? stripeCustomerId;
  final String? telegramChatId;
  final String? emergencyContact;
  final DateTime createdAt;

  AppUser({
    required this.id,
    this.email,
    required this.phone,
    this.fullName,
    this.premiumTier = 'free',
    this.premiumExpiry,
    this.stripeCustomerId,
    this.telegramChatId,
    this.emergencyContact,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPremium => premiumTier != 'free';
  bool get isFamily => premiumTier == 'family';
  bool get premiumActive {
    if (premiumTier == 'free') return false;
    if (premiumExpiry == null) return true;
    return premiumExpiry!.isAfter(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'full_name': fullName,
    'premium_tier': premiumTier,
    'premium_expiry': premiumExpiry?.toIso8601String(),
    'stripe_customer_id': stripeCustomerId,
    'telegram_chat_id': telegramChatId,
    'emergency_contact': emergencyContact,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String,
    fullName: json['full_name'] as String?,
    premiumTier: json['premium_tier'] as String? ?? 'free',
    premiumExpiry: json['premium_expiry'] != null
        ? DateTime.parse(json['premium_expiry'] as String)
        : null,
    stripeCustomerId: json['stripe_customer_id'] as String?,
    telegramChatId: json['telegram_chat_id'] as String?,
    emergencyContact: json['emergency_contact'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
  );

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? premiumTier,
    DateTime? premiumExpiry,
    String? stripeCustomerId,
    String? telegramChatId,
    String? emergencyContact,
  }) => AppUser(
    id: id ?? this.id,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    fullName: fullName ?? this.fullName,
    premiumTier: premiumTier ?? this.premiumTier,
    premiumExpiry: premiumExpiry ?? this.premiumExpiry,
    stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
    telegramChatId: telegramChatId ?? this.telegramChatId,
    emergencyContact: emergencyContact ?? this.emergencyContact,
  );
}
