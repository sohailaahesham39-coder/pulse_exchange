import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CustomBluetoothService {
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  String? _errorMessage;

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;

  /// Scans for available Bluetooth devices.
  Future<void> scanForDevices() async {
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    } catch (e) {
      _errorMessage = 'Failed to scan for devices: $e';
    }
  }

  /// Connects to a Bluetooth device.
  Future<void> connectToDevice(BluetoothDevice device) async {
    _isConnecting = true;
    try {
      await device.connect();
      _connectedDevice = device;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to connect: $e';
    } finally {
      _isConnecting = false;
    }
  }

  /// Disconnects from the connected device.
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  /// Retrieves a blood pressure reading from the connected device.
  Future<Map<String, int>?> getBPReading() async {
    if (_connectedDevice == null) {
      _errorMessage = 'No device connected';
      return null;
    }

    try {
      // Example: Discover services and characteristics
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      // Replace with actual service and characteristic UUIDs for your BP device
      BluetoothService? bpService = services.firstWhere(
            (s) => s.uuid.toString() == 'YOUR_BP_SERVICE_UUID',
        orElse: () => throw Exception('BP service not found'),
      );

      BluetoothCharacteristic? bpCharacteristic = bpService.characteristics.firstWhere(
            (c) => c.uuid.toString() == 'YOUR_BP_CHARACTERISTIC_UUID',
        orElse: () => throw Exception('BP characteristic not found'),
      );

      // Read or subscribe to the characteristic
      List<int> value = await bpCharacteristic.read();
      // Parse the value according to your device's protocol
      // This is a placeholder; adjust based on your device's data format
      return {
        'systolic': value[0], // Example parsing
        'diastolic': value[1],
        'pulse': value[2],
      };
    } catch (e) {
      _errorMessage = 'Failed to read BP data: $e';
      return null;
    }
  }
}