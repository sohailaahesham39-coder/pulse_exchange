import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicationModel {
  final String id;
  final String donorId;
  final String? donorName;
  final String? recipientId;
  final String? recipientName;
  final String name;
  final String type;
  final String dosage;
  final DateTime expiryDate;
  final int quantity;
  final List<String> imageUrls;
  final String location;
  final double? latitude;
  final double? longitude;
  final String description;
  final String status;
  final DateTime createdAt;

  MedicationModel({
    required this.id,
    required this.donorId,
    this.donorName,
    this.recipientId,
    this.recipientName,
    required this.name,
    required this.type,
    required this.dosage,
    required this.expiryDate,
    required this.quantity,
    List<String>? imageUrls,
    required this.location,
    this.latitude,
    this.longitude,
    required this.description,
    required this.status,
    required this.createdAt,
  })  : assert(id.isNotEmpty, 'ID cannot be empty'),
        assert(donorId.isNotEmpty, 'Donor ID cannot be empty'),
        assert(name.isNotEmpty, 'Name cannot be empty'),
        assert(type.isNotEmpty, 'Type cannot be empty'),
        assert(quantity >= 0, 'Quantity cannot be negative'),
        imageUrls = imageUrls ?? [];

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    try {
      return MedicationModel(
        id: json['id']?.toString() ?? (throw ArgumentError('Missing id')),
        donorId: json['donorId']?.toString() ?? (throw ArgumentError('Missing donorId')),
        donorName: json['donorName']?.toString(),
        recipientId: json['recipientId']?.toString(),
        recipientName: json['recipientName']?.toString(),
        name: json['name']?.toString() ?? (throw ArgumentError('Missing name')),
        type: json['type']?.toString() ?? (throw ArgumentError('Missing type')),
        dosage: json['dosage']?.toString() ?? '',
        expiryDate: _parseDate(json['expiryDate'], 'expiryDate'),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        imageUrls: (json['imageUrls'] as List<dynamic>?)
            ?.where((url) => url != null)
            .map((url) => url.toString())
            .toList() ??
            [],
        location: json['location']?.toString() ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        description: json['description']?.toString() ?? '',
        status: json['status']?.toString()?.toLowerCase() ?? 'unknown',
        createdAt: _parseDate(json['createdAt'], 'createdAt'),
      );
    } catch (e) {
      throw FormatException('Failed to parse MedicationModel: $e');
    }
  }

  static DateTime _parseDate(dynamic value, String fieldName) {
    if (value == null) {
      throw ArgumentError('Missing $fieldName');
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      try {
        final formatter = DateFormat('yyyy-MM-dd');
        return formatter.parse(value.toString());
      } catch (_) {
        throw FormatException('Invalid $fieldName format: $value');
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'name': name,
      'type': type,
      'dosage': dosage,
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'imageUrls': imageUrls,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MedicationModel copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? recipientId,
    String? recipientName,
    String? name,
    String? type,
    String? dosage,
    DateTime? expiryDate,
    int? quantity,
    List<String>? imageUrls,
    String? location,
    double? latitude,
    double? longitude,
    String? description,
    String? status,
    DateTime? createdAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Utility method for concise display
  String toDisplayString() => dosage.isEmpty ? name : '$name $dosage';

  // Comparison for sorting by date
  int compareByDate(MedicationModel other, {bool byCreatedAt = true, bool ascending = true}) {
    final dateA = byCreatedAt ? createdAt : expiryDate;
    final dateB = byCreatedAt ? other.createdAt : other.expiryDate;
    return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
  }
}

// Extension for status and expiry handling
extension MedicationStatus on MedicationModel {
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isNearExpiry => !isExpired && expiryDate.difference(DateTime.now()).inDays <= 30;

  bool get canBeRequested => status.toLowerCase() == 'available' && !isExpired && quantity > 0;

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  String get formattedExpiryDate => DateFormat('dd MMM yyyy').format(expiryDate);

  String get formattedCreatedAt => DateFormat('dd MMM yyyy').format(createdAt);

  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle;
      case 'reserved':
        return Icons.lock;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
}