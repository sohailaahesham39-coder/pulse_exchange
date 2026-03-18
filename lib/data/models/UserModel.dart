import 'dart:convert';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? phone; // Renamed from phoneNumber
  final String? profileImageUrl;
  final String? role; // 'doctor' or 'patient'
  final String? location;
  final Map<String, dynamic>? healthData;
  final Map<String, dynamic>? additionalInfo; // Added for doctor-specific data
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> donatedMedications;
  final List<String> requestedMedications;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.role,
    this.location,
    this.healthData,
    this.additionalInfo,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? donatedMedications,
    List<String>? requestedMedications,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        donatedMedications = donatedMedications ?? [],
        requestedMedications = requestedMedications ?? [];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String? ?? json['id'] as String?;
    final name = json['name'] as String?;
    final email = json['email'] as String?;

    if (userId == null || userId.isEmpty) {
      throw FormatException('userId is required and cannot be empty');
    }
    if (name == null || name.isEmpty) {
      throw FormatException('name is required and cannot be empty');
    }
    if (email == null || email.isEmpty) {
      throw FormatException('email is required and cannot be empty');
    }

    return UserModel(
      userId: userId,
      name: name,
      email: email,
      phone: json['phone'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: json['role'] as String?,
      location: json['location'] as String?,
      healthData: json['healthData'] != null
          ? Map<String, dynamic>.from(json['healthData'] as Map)
          : null,
      additionalInfo: json['additionalInfo'] != null
          ? Map<String, dynamic>.from(json['additionalInfo'] as Map)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      donatedMedications:
      (json['donatedMedications'] as List<dynamic>?)?.cast<String>() ?? [],
      requestedMedications:
      (json['requestedMedications'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'location': location,
      'healthData': healthData,
      'additionalInfo': additionalInfo,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'donatedMedications': donatedMedications,
      'requestedMedications': requestedMedications,
    };
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? role,
    String? location,
    Map<String, dynamic>? healthData,
    Map<String, dynamic>? additionalInfo,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? donatedMedications,
    List<String>? requestedMedications,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      location: location ?? this.location,
      healthData: healthData != null
          ? Map<String, dynamic>.from(healthData)
          : this.healthData != null
          ? Map<String, dynamic>.from(this.healthData!)
          : null,
      additionalInfo: additionalInfo != null
          ? Map<String, dynamic>.from(additionalInfo)
          : this.additionalInfo != null
          ? Map<String, dynamic>.from(this.additionalInfo!)
          : null,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      donatedMedications: donatedMedications ?? this.donatedMedications,
      requestedMedications: requestedMedications ?? this.requestedMedications,
    );
  }

  String get id => userId;
}