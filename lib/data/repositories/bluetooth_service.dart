import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Constants for BLE UUIDs and error messages
class BluetoothConstants {
  static Guid bpServiceUuid = Guid('00001810-0000-1000-8000-00805f9b34fb'); // Standard BP Service UUID
  static Guid bpMeasurementCharUuid = Guid('00002a35-0000-1000-8000-00805f9b34fb'); // BP Measurement Characteristic UUID

  static const String bluetoothOff = 'Bluetooth is turned off. Please enable Bluetooth.';
  static const String permissionsDenied = 'Bluetooth and location permissions are required.';
  static const String scanError = 'Scan error: %s';
  static const String scanFailed = 'Failed to start scan: %s';
  static const String connectFailed = 'Failed to connect: %s';
  static const String disconnectFailed = 'Failed to disconnect: %s';
  static const String noDeviceConnected = 'No device connected';
  static const String bpServiceNotFound = 'Blood pressure service not found on device';
  static const String bpCharNotFound = 'Blood pressure measurement characteristic not found';
  static const String bpReadNotSupported = 'Device does not support reading blood pressure';
  static const String bpReadError = 'Error reading from device: %s';
  static const String bpParseError = 'Failed to parse blood pressure data: %s';
  static const String bpTimeout = 'Timeout waiting for blood pressure measurement';
}

class BluetoothService extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isDisposed = false;
  String? _errorMessage;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothDeviceState>? _deviceStateSubscription;

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectedDevice != null;
  bool get mounted => !_isDisposed;

  /// Checks Bluetooth permissions and state before scanning.
  Future<bool> _checkPermissionsAndState() async {
    // Check Bluetooth state
    if (!await FlutterBluePlus.isOn) {
      _errorMessage = BluetoothConstants.bluetoothOff;
      notifyListeners();
      return false;
    }

    // Check permissions (platform-specific)
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // Required for Android BLE scanning
    ];

    final statuses = await permissions.request();
    if (statuses.values.any((status) => !status.isGranted)) {
      _errorMessage = BluetoothConstants.permissionsDenied;
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Starts scanning for BLE devices (broad scan, filter post-discovery).
  Future<void> startScan() async {
    if (_isScanning) {
      await stopScan();
    }

    _scanResults = [];
    _errorMessage = null;
    _isScanning = true;
    notifyListeners();

    try {
      if (!await _checkPermissionsAndState()) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      _scanSubscription = FlutterBluePlus.scanResults.listen(
            (results) {
          if (!mounted) return;
          // Filter for devices with BP Service or unknown advertisement
          _scanResults = results.where((result) {
            final advServices = result.advertisementData.serviceUuids;
            return advServices.isEmpty || // Include devices with no advertised services
                advServices.contains(BluetoothConstants.bpServiceUuid);
          }).toList();
          notifyListeners();
        },
        onError: (error) {
          if (!mounted) return;
          _errorMessage = BluetoothConstants.scanError.replaceFirst('%s', error.toString());
          _isScanning = false;
          notifyListeners();
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
      );
    } catch (e) {
      if (!mounted) return;
      _errorMessage = BluetoothConstants.scanFailed.replaceFirst('%s', e.toString());
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stops the current BLE scan and cleans up resources.
  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await _scanSubscription?.cancel();
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _errorMessage = 'Failed to stop scan: $e';
    } finally {
      if (mounted) {
        _scanSubscription = null;
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  /// Connects to a specified BLE device and verifies BP service.
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_connectedDevice != null) {
      await disconnectDevice();
    }

    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
      final services = await device.discoverServices();
      final hasBPService = services.any((service) => service.uuid == BluetoothConstants.bpServiceUuid);

      if (!hasBPService) {
        await device.disconnect();
        _errorMessage = BluetoothConstants.bpServiceNotFound;
        notifyListeners();
        return false;
      }

      _connectedDevice = device;

      _deviceStateSubscription = device.state.listen((state) {
        if (!mounted) return;
        if (state == BluetoothDeviceState.disconnected) {
          _connectedDevice = null;
          _deviceStateSubscription?.cancel();
          _deviceStateSubscription = null;
          notifyListeners();
        }
      }) as StreamSubscription<BluetoothDeviceState>?;

      return true;
    } catch (e) {
      if (!mounted) return false;
      _errorMessage = BluetoothConstants.connectFailed.replaceFirst('%s', e.toString());
      notifyListeners();
      return false;
    } finally {
      if (mounted) {
        _isConnecting = false;
        notifyListeners();
      }
    }
  }

  /// Disconnects from the currently connected device.
  Future<void> disconnectDevice() async {
    if (_connectedDevice == null) return;

    try {
      await _deviceStateSubscription?.cancel();
      await _connectedDevice!.disconnect();
    } catch (e) {
      _errorMessage = BluetoothConstants.disconnectFailed.replaceFirst('%s', e.toString());
    } finally {
      if (mounted) {
        _connectedDevice = null;
        _deviceStateSubscription = null;
        notifyListeners();
      }
    }
  }

  /// Retrieves a blood pressure reading from the connected device.
  Future<Map<String, dynamic>?> getBPReading() async {
    if (_connectedDevice == null) {
      _errorMessage = BluetoothConstants.noDeviceConnected;
      notifyListeners();
      return null;
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      final bpService = services.firstWhere(
            (service) => service.uuid == BluetoothConstants.bpServiceUuid,
        orElse: () => throw Exception(BluetoothConstants.bpServiceNotFound),
      );

      final bpChar = bpService.characteristics.firstWhere(
            (char) => char.uuid == BluetoothConstants.bpMeasurementCharUuid,
        orElse: () => throw Exception(BluetoothConstants.bpCharNotFound),
      );

      if (bpChar.properties.notify) {
        await bpChar.setNotifyValue(true);
        final completer = Completer<List<int>>();
        final subscription = bpChar.onValueReceived.listen((value) {
          if (!completer.isCompleted && value.isNotEmpty) {
            completer.complete(value);
          }
        });

        try {
          final value = await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              _errorMessage = BluetoothConstants.bpTimeout;
              notifyListeners();
              throw TimeoutException(BluetoothConstants.bpTimeout);
            },
          );

          subscription.cancel();
          return _parseBPMeasurement(value);
        } finally {
          subscription.cancel();
          await bpChar.setNotifyValue(false);
        }
      } else if (bpChar.properties.read) {
        final value = await bpChar.read();
        return _parseBPMeasurement(value);
      } else {
        _errorMessage = BluetoothConstants.bpReadNotSupported;
        notifyListeners();
        return null;
      }
    } catch (e) {
      if (!mounted) return null;
      _errorMessage = BluetoothConstants.bpReadError.replaceFirst('%s', e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Parses blood pressure measurement data based on Bluetooth SIG specification.
  Map<String, dynamic>? _parseBPMeasurement(List<int> data) {
    try {
      if (data.length < 7) {
        throw Exception('Data too short for BP measurement');
      }

      // Parse flags (first byte)
      final flags = data[0];
      final isMmHg = (flags & 0x01) == 0; // 0 = mmHg, 1 = kPa
      final hasTimestamp = (flags & 0x02) != 0;
      final hasPulseRate = (flags & 0x04) != 0;

      // Parse systolic, diastolic, and mean arterial pressure (float format, 2 bytes each)
      int offset = 1;
      final systolic = _decodeSfloat(data[offset], data[offset + 1]);
      offset += 2;
      final diastolic = _decodeSfloat(data[offset], data[offset + 1]);
      offset += 2;
      final meanArterial = _decodeSfloat(data[offset], data[offset + 1]);
      offset += 2;

      // Parse pulse rate if present
      double? pulseRate;
      if (hasPulseRate) {
        if (data.length < offset + 2) {
          throw Exception('Data too short for pulse rate');
        }
        pulseRate = _decodeSfloat(data[offset], data[offset + 1]);
        offset += 2;
      }

      // Parse timestamp if present
      DateTime? timestamp;
      if (hasTimestamp) {
        if (data.length < offset + 7) {
          throw Exception('Data too short for timestamp');
        }
        timestamp = _decodeTimestamp(
          data[offset],
          data[offset + 1],
          data[offset + 2],
          data[offset + 3],
          data[offset + 4],
          data[offset + 5],
          data[offset + 6],
        );
        offset += 7;
      } else {
        timestamp = DateTime.now();
      }

      return {
        'systolic': systolic,
        'diastolic': diastolic,
        'mean_arterial': meanArterial,
        'pulse': pulseRate,
        'timestamp': timestamp.toIso8601String(),
        'unit': isMmHg ? 'mmHg' : 'kPa',
      };
    } catch (e) {
      if (!mounted) return null;
      _errorMessage = BluetoothConstants.bpParseError.replaceFirst('%s', e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Decodes SFLOAT format (16-bit, IEEE 11073-20601).
  double _decodeSfloat(int byte1, int byte2) {
    final mantissa = ((byte2 & 0x0F) << 8) | (byte1 & 0xFF);
    final exponent = (byte2 >> 4) > 7 ? (byte2 >> 4) - 16 : (byte2 >> 4);
    return mantissa * (10.0 * exponent);
  }

  /// Decodes timestamp (7 bytes: year, month, day, hour, minute, second).
  DateTime _decodeTimestamp(int yearLow, int yearHigh, int month, int day, int hour, int minute, int second) {
    final year = (yearHigh << 8) | yearLow;
    return DateTime(year, month, day, hour, minute, second);
  }

  /// Clears scan results.
  void _clearScanResults() {
    _scanResults = [];
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Cleans up resources when the service is disposed.
  @override
  void dispose() {
    _scanSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    disconnectDevice();
    _scanSubscription = null;
    _deviceStateSubscription = null;
    _isDisposed = true;
    super.dispose();
  }
}