import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// Constants for BP ranges and status descriptions
class BPReadingConstants {
  static const int minSystolic = 50;
  static const int maxSystolic = 250;
  static const int minDiastolic = 30;
  static const int maxDiastolic = 150;
  static const int minPulse = 30;
  static const int maxPulse = 200;

  static const Map<String, String> statusDescriptions = {
    'normal': 'Your blood pressure is normal.',
    'elevated': 'Your blood pressure is elevated. Consider lifestyle changes.',
    'hypertension_stage1': 'You have Stage 1 Hypertension. Consider consulting a doctor.',
    'hypertension_stage2': 'You have Stage 2 Hypertension. Please consult a doctor.',
    'hypertensive_crisis': 'Hypertensive Crisis! Seek emergency medical attention immediately!',
  };
}

class BPReadingModel {
  final String id;
  final String userId;
  final int systolic;
  final int diastolic;
  final int pulse;
  final String status; // "normal", "elevated", "hypertension_stage1", "hypertension_stage2", "hypertensive_crisis"
  final DateTime timestamp;
  final String? notes;
  final String source; // "manual", "device_name", etc.
  final Map<String, dynamic>? metadata;

  BPReadingModel({
    required this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.status,
    required this.timestamp,
    this.notes,
    required this.source,
    this.metadata,
  }) {
    // Validate inputs
    if (systolic < BPReadingConstants.minSystolic || systolic > BPReadingConstants.maxSystolic) {
      throw ArgumentError('Systolic must be between ${BPReadingConstants.minSystolic} and ${BPReadingConstants.maxSystolic} mmHg');
    }
    if (diastolic < BPReadingConstants.minDiastolic || diastolic > BPReadingConstants.maxDiastolic) {
      throw ArgumentError('Diastolic must be between ${BPReadingConstants.minDiastolic} and ${BPReadingConstants.maxDiastolic} mmHg');
    }
    if (pulse < BPReadingConstants.minPulse || pulse > BPReadingConstants.maxPulse) {
      throw ArgumentError('Pulse must be between ${BPReadingConstants.minPulse} and ${BPReadingConstants.maxPulse} bpm');
    }
    if (!BPReadingConstants.statusDescriptions.containsKey(status)) {
      throw ArgumentError('Invalid status: $status');
    }
  }

  factory BPReadingModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['id'] is! String || json['id'].isEmpty) {
      throw const FormatException('Invalid or missing id');
    }
    if (json['userId'] is! String || json['userId'].isEmpty) {
      throw const FormatException('Invalid or missing userId');
    }
    if (json['systolic'] is! int) {
      throw const FormatException('Invalid or missing systolic');
    }
    if (json['diastolic'] is! int) {
      throw const FormatException('Invalid or missing diastolic');
    }
    if (json['pulse'] is! int) {
      throw const FormatException('Invalid or missing pulse');
    }
    if (json['status'] is! String || json['status'].isEmpty) {
      throw const FormatException('Invalid or missing status');
    }
    if (json['timestamp'] is! String || json['timestamp'].isEmpty) {
      throw const FormatException('Invalid or missing timestamp');
    }
    if (json['source'] is! String || json['source'].isEmpty) {
      throw const FormatException('Invalid or missing source');
    }

    try {
      return BPReadingModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        systolic: json['systolic'] as int,
        diastolic: json['diastolic'] as int,
        pulse: json['pulse'] as int,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        notes: json['notes'] as String?,
        source: json['source'] as String,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw FormatException('Failed to parse BPReadingModel: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'source': source,
      'metadata': metadata,
    }..removeWhere((key, value) => value == null); // Remove null values
  }

  String get formattedReading => '$systolic/$diastolic mmHg';

  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');

    if (difference.inDays == 0) {
      return 'Today ${timeFormat.format(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${timeFormat.format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return dateFormat.format(timestamp);
    }
  }

  String getStatusDescription() {
    return BPReadingConstants.statusDescriptions[status] ?? 'Blood pressure status unknown.';
  }

  // Helper method to calculate BP status based on systolic and diastolic values
  static String calculateStatus(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return 'hypertensive_crisis';
    } else if (systolic >= 140 || diastolic >= 90) {
      return 'hypertension_stage2';
    } else if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) {
      return 'hypertension_stage1';
    } else if ((systolic >= 120 && systolic < 130) && diastolic < 80) {
      return 'elevated';
    } else {
      return 'normal';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BPReadingModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              systolic == other.systolic &&
              diastolic == other.diastolic &&
              pulse == other.pulse &&
              status == other.status &&
              timestamp == other.timestamp &&
              notes == other.notes &&
              source == other.source &&
              mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    systolic,
    diastolic,
    pulse,
    status,
    timestamp,
    notes,
    source,
    metadata,
  );
}

