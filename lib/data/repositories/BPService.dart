import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/BPReadingModel.dart';

// Constants for error messages and validation
class BPConstants {
  static const String fetchFailed = 'Failed to fetch readings';
  static const String addFailed = 'Failed to add reading';
  static const String deleteFailed = 'Failed to delete reading';
  static const String error = 'Error: %s';
  static const String invalidSystolic = 'Systolic must be between 50 and 250 mmHg';
  static const String invalidDiastolic = 'Diastolic must be between 30 and 150 mmHg';
  static const String invalidPulse = 'Pulse must be between 30 and 200 bpm';
  static const String deviceReadFailed = 'Failed to read from device';
}

// Mock CustomBluetoothService for testing without a real device
class CustomBluetoothService {
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  String? _errorMessage;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;

  Future<void> scanForDevices() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('CustomBluetoothService: Simulated device scan');
    } catch (e) {
      _errorMessage = 'Failed to scan for devices: $e';
      debugPrint('CustomBluetoothService: $e');
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    _isConnecting = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      _connectedDevice = device;
      _errorMessage = null;
      debugPrint('CustomBluetoothService: Connected to device: ${device.deviceName}');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to connect: $e';
      debugPrint('CustomBluetoothService: $e');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await Future.delayed(const Duration(seconds: 1));
      _connectedDevice = null;
      debugPrint('CustomBluetoothService: Disconnected');
    }
  }

  Future<Map<String, int>?> getBPReading() async {
    if (_connectedDevice == null) {
      _errorMessage = 'No device connected';
      debugPrint('CustomBluetoothService: $_errorMessage');
      return null;
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'systolic': 120 + (DateTime.now().millisecond % 20),
        'diastolic': 80 + (DateTime.now().millisecond % 10),
        'pulse': 70 + (DateTime.now().millisecond % 20),
      };
    } catch (e) {
      _errorMessage = 'Failed to read BP data: $e';
      debugPrint('CustomBluetoothService: $e');
      return null;
    }
  }
}

extension on BluetoothDevice {
  get deviceName => null;
}

class BPService extends ChangeNotifier {
  final List<BPReadingModel> _readings = [];
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  final CustomBluetoothService _bluetoothService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  BPService({CustomBluetoothService? bluetoothService})
      : _bluetoothService = bluetoothService ?? CustomBluetoothService();

  List<BPReadingModel> get readings => List.unmodifiable(_readings);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BluetoothDevice? get connectedDevice => _bluetoothService.connectedDevice;
  bool get isConnecting => _bluetoothService.isConnecting;
  bool get mounted => !_isDisposed;
  CustomBluetoothService get bluetoothService => _bluetoothService;

  /// Initializes the service by loading stored readings or adding mock data
  Future<void> init() async {
    if (!mounted) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final storedReadings = await _secureStorage.read(key: 'bp_readings');
      if (storedReadings != null) {
        final data = jsonDecode(storedReadings) as List;
        _readings.clear();
        _readings.addAll(data.map((item) => BPReadingModel.fromJson(item)));
        debugPrint('BPService: Loaded ${_readings.length} readings from storage');
      } else {
        // Add mock readings for testing, tied to patient IDs
        final now = DateTime.now();
        _readings.addAll([
          BPReadingModel(
            id: '1',
            userId: '1', // John Doe
            systolic: 128,
            diastolic: 85,
            pulse: 72,
            status: BPReadingModel.calculateStatus(128, 85),
            timestamp: now.subtract(const Duration(days: 1)),
            source: 'device',
          ),
          BPReadingModel(
            id: '2',
            userId: '1', // John Doe
            systolic: 135,
            diastolic: 90,
            pulse: 75,
            status: BPReadingModel.calculateStatus(135, 90),
            timestamp: now.subtract(const Duration(days: 3)),
            source: 'manual',
            notes: 'After morning walk',
          ),
          BPReadingModel(
            id: '3',
            userId: '2', // Jane Smith
            systolic: 145,
            diastolic: 95,
            pulse: 80,
            status: BPReadingModel.calculateStatus(145, 95),
            timestamp: now.subtract(const Duration(days: 2)),
            source: 'device',
          ),
          BPReadingModel(
            id: '4',
            userId: '3', // Robert Johnson
            systolic: 160,
            diastolic: 100,
            pulse: 78,
            status: BPReadingModel.calculateStatus(160, 100),
            timestamp: now.subtract(const Duration(days: 4)),
            source: 'device',
          ),
          BPReadingModel(
            id: '5',
            userId: '4', // Mary Williams
            systolic: 130,
            diastolic: 88,
            pulse: 70,
            status: BPReadingModel.calculateStatus(130, 88),
            timestamp: now.subtract(const Duration(days: 5)),
            source: 'manual',
          ),
        ]);

        // Save mock readings to secure storage
        await _secureStorage.write(
          key: 'bp_readings',
          value: jsonEncode(_readings.map((r) => r.toJson()).toList()),
        );
        debugPrint('BPService: Initialized with ${_readings.length} mock readings');
      }
    } catch (e) {
      _errorMessage = BPConstants.error.replaceFirst('%s', e.toString());
      debugPrint('BPService: Error initializing: $e');
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Connects to a Bluetooth device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (!mounted) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _bluetoothService.connectToDevice(device);
      if (success) {
        debugPrint('BPService: Connected to device');
        notifyListeners();
        return true;
      } else {
        _errorMessage = _bluetoothService.errorMessage ?? 'Failed to connect to device';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error connecting to device: $e';
      debugPrint('BPService: Error connecting to device: $e');
      return false;
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Disconnects from the connected Bluetooth device
  Future<void> disconnectDevice() async {
    if (!mounted) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bluetoothService.disconnect();
      debugPrint('BPService: Disconnected from device');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error disconnecting from device: $e';
      debugPrint('BPService: Error disconnecting from device: $e');
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Fetches blood pressure readings for a specific user
  Future<List<BPReadingModel>> fetchReadings(
      String token,
      String userId, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    if (!mounted) return [];

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      final filteredReadings = _readings.where((reading) {
        if (reading.userId != userId) return false;
        if (startDate != null && reading.timestamp.isBefore(startDate)) return false;
        if (endDate != null && reading.timestamp.isAfter(endDate)) return false;
        return true;
      }).toList();

      debugPrint('BPService: Fetched ${filteredReadings.length} readings for userId: $userId');
      return filteredReadings; // Fixed: Return the filtered readings
    } catch (e) {
      _errorMessage = BPConstants.error.replaceFirst('%s', e.toString());
      debugPrint('BPService: Error fetching readings: $e');
      return [];
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Adds a new blood pressure reading
  Future<bool> addReading(
      String token, {
        required int systolic,
        required int diastolic,
        required int pulse,
        required String userId,
        String? notes,
        String source = 'manual',
      }) async {
    if (!mounted) return false;

    if (systolic < 50 || systolic > 250) {
      _errorMessage = BPConstants.invalidSystolic;
      notifyListeners();
      return false;
    }
    if (diastolic < 30 || diastolic > 150) {
      _errorMessage = BPConstants.invalidDiastolic;
      notifyListeners();
      return false;
    }
    if (pulse < 30 || pulse > 200) {
      _errorMessage = BPConstants.invalidPulse;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      final status = BPReadingModel.calculateStatus(systolic, diastolic);
      final newReading = BPReadingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        status: status,
        notes: notes,
        source: source,
        timestamp: DateTime.now(),
      );

      _readings.insert(0, newReading);

      await _secureStorage.write(
        key: 'bp_readings',
        value: jsonEncode(_readings.map((r) => r.toJson()).toList()),
      );

      debugPrint('BPService: Added reading: $systolic/$diastolic, pulse: $pulse for userId: $userId');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = BPConstants.error.replaceFirst('%s', e.toString());
      debugPrint('BPService: Error adding reading: $e');
      return false;
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Deletes a blood pressure reading
  Future<bool> deleteReading(String token, String readingId) async {
    if (!mounted) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _readings.removeWhere((reading) => reading.id == readingId);

      await _secureStorage.write(
        key: 'bp_readings',
        value: jsonEncode(_readings.map((r) => r.toJson()).toList()),
      );

      debugPrint('BPService: Deleted reading: $readingId');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = BPConstants.error.replaceFirst('%s', e.toString());
      debugPrint('BPService: Error deleting reading: $e');
      return false;
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Calculates statistics for blood pressure readings
  Map<String, dynamic> getStatistics({String period = 'week', String? userId}) {
    final filteredReadings = _readings.where((reading) {
      if (userId != null && reading.userId != userId) return false;
      final now = DateTime.now();
      switch (period) {
        case 'day':
          return reading.timestamp.year == now.year &&
              reading.timestamp.month == now.month &&
              reading.timestamp.day == now.day;
        case 'week':
          return reading.timestamp.isAfter(now.subtract(const Duration(days: 7)));
        case 'month':
          return reading.timestamp.year == now.year && reading.timestamp.month == now.month;
        case 'year':
          return reading.timestamp.year == now.year;
        default:
          return true;
      }
    }).toList();

    if (filteredReadings.isEmpty) {
      return {'average': null, 'min': null, 'max': null, 'trend': null};
    }

    final systolicStats = filteredReadings.fold<Map<String, int>>(
      {'sum': 0, 'min': filteredReadings.first.systolic, 'max': filteredReadings.first.systolic},
          (stats, reading) => {
        'sum': stats['sum']! + reading.systolic,
        'min': stats['min']! < reading.systolic ? stats['min']! : reading.systolic,
        'max': stats['max']! > reading.systolic ? stats['max']! : reading.systolic,
      },
    );

    final diastolicStats = filteredReadings.fold<Map<String, int>>(
      {
        'sum': 0,
        'min': filteredReadings.first.diastolic,
        'max': filteredReadings.first.diastolic,
      },
          (stats, reading) => {
        'sum': stats['sum']! + reading.diastolic,
        'min': stats['min']! < reading.diastolic ? stats['min']! : reading.diastolic,
        'max': stats['max']! > reading.diastolic ? stats['max']! : reading.diastolic,
      },
    );

    final avgSystolic = systolicStats['sum']! / filteredReadings.length;
    final avgDiastolic = diastolicStats['sum']! / filteredReadings.length;

    String trend = 'stable';
    if (filteredReadings.length > 1) {
      filteredReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final firstHalf = filteredReadings.sublist(0, filteredReadings.length ~/ 2);
      final secondHalf = filteredReadings.sublist(filteredReadings.length ~/ 2);

      final firstHalfAvg = firstHalf.fold<int>(0, (sum, r) => sum + r.systolic) / firstHalf.length;
      final secondHalfAvg = secondHalf.fold<int>(0, (sum, r) => sum + r.systolic) / secondHalf.length;
      final percentChange = ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100;

      trend = percentChange < -5
          ? 'improving'
          : percentChange > 5
          ? 'worsening'
          : 'stable';
    }

    return {
      'average': {'systolic': avgSystolic.round(), 'diastolic': avgDiastolic.round()},
      'min': {'systolic': systolicStats['min'], 'diastolic': diastolicStats['min']},
      'max': {'systolic': systolicStats['max'], 'diastolic': diastolicStats['max']},
      'trend': trend,
    };
  }

  /// Retrieves a blood pressure reading from the connected Bluetooth device
  Future<Map<String, int>?> getReadingFromDevice() async {
    if (!mounted) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reading = await _bluetoothService.getBPReading();
      if (reading == null) {
        _errorMessage = _bluetoothService.errorMessage ?? BPConstants.deviceReadFailed;
        return null;
      }

      debugPrint('BPService: Read from device: ${reading['systolic']}/${reading['diastolic']}, pulse: ${reading['pulse']}');
      return {
        'systolic': reading['systolic'] as int,
        'diastolic': reading['diastolic'] as int,
        'pulse': reading['pulse'] as int,
      };
    } catch (e) {
      _errorMessage = BPConstants.error.replaceFirst('%s', e.toString());
      debugPrint('BPService: Error reading from device: $e');
      return null;
    } finally {
      if (mounted) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Clears the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}