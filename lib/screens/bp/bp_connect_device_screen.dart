import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../../config/AppRoutes.dart';
import '../../services/BPService.dart';
import '../../widget/common/CustomButton.dart';

class BPConnectDeviceScreen extends StatefulWidget {
  const BPConnectDeviceScreen({Key? key}) : super(key: key);

  @override
  State<BPConnectDeviceScreen> createState() => _BPConnectDeviceScreenState();
}

class _BPConnectDeviceScreenState extends State<BPConnectDeviceScreen> {
  bool _isScanning = false;
  bool _isCheckingPermissions = false;
  List<ScanResult> _scanResults = [];
  String? _errorMessage;
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _initializeAndCheckPermissions();
  }

  Future<void> _initializeAndCheckPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
      _errorMessage = null;
    });

    try {
      // First check if Bluetooth is supported
      if (!(await FlutterBluePlus.isSupported)) {
        setState(() {
          _errorMessage = 'Bluetooth is not supported on this device';
          _isCheckingPermissions = false;
        });
        return;
      }

      // Check if Bluetooth is turned on
      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        setState(() {
          _errorMessage = 'Please turn on Bluetooth to connect to your device';
          _isCheckingPermissions = false;
        });
        return;
      }

      // Check and request permissions based on Android version
      if (Platform.isAndroid) {
        // Get Android SDK version
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 31) { // Android 12+
          // Request the new Bluetooth permissions
          Map<Permission, PermissionStatus> statuses = await [
            Permission.bluetooth,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse,
          ].request();

          // Check if all permissions are granted
          final allGranted = statuses.values.every((status) => status.isGranted);

          if (!allGranted) {
            // Check if any permission is permanently denied
            final anyPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

            if (anyPermanentlyDenied && mounted) {
              _showPermissionDeniedDialog(true);
            } else if (mounted) {
              _showPermissionDeniedDialog(false);
            }

            setState(() {
              _errorMessage = 'Bluetooth and location permissions are required to scan for devices';
              _isCheckingPermissions = false;
            });
            return;
          }
        } else { // Android 6-11
          // For older Android versions, just need location permission for BLE
          final locationStatus = await Permission.locationWhenInUse.request();

          if (!locationStatus.isGranted) {
            if (locationStatus.isPermanentlyDenied && mounted) {
              _showPermissionDeniedDialog(true);
            } else if (mounted) {
              _showPermissionDeniedDialog(false);
            }

            setState(() {
              _errorMessage = 'Location permission is required for Bluetooth scanning';
              _isCheckingPermissions = false;
            });
            return;
          }
        }
      }

      setState(() {
        _isCheckingPermissions = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking permissions: $e';
          _isCheckingPermissions = false;
        });
      }
    }
  }

  void _showPermissionDeniedDialog(bool isPermanent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text(
          isPermanent
              ? 'Bluetooth and location permissions are permanently denied. Please enable them in app settings to use this feature.'
              : 'Bluetooth and location permissions are required to scan for and connect to your BP monitor.',
        ),
        actions: [
          if (isPermanent)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          if (!isPermanent)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeAndCheckPermissions();
              },
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    // Check permissions first
    await _initializeAndCheckPermissions();

    // If there's an error message, it means permissions weren't granted
    if (_errorMessage != null) {
      return;
    }

    // Check if Bluetooth is on again (user might have turned it off)
    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      setState(() {
        _errorMessage = 'Please turn on Bluetooth to connect to your device';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _scanResults = [];
    });

    try {
      // Listen for scan results
      FlutterBluePlus.scanResults.listen(
            (results) {
          if (mounted) {
            setState(() {
              _scanResults = results;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isScanning = false;
              _errorMessage = 'Scan error: $error';
            });
          }
        },
      );

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      // The scan will automatically stop after the timeout
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Failed to start scan: $e';
        });
      }
    }
  }

  Future<void> _stopScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _selectedDevice = device;
      _errorMessage = null;
    });

    final bpService = Provider.of<BPService>(context, listen: false);

    try {
      final success = await bpService.connectToDevice(device);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name.isNotEmpty ? device.name : 'Unknown Device'}')),
        );

        // Navigate to input screen
        Navigator.pushReplacementNamed(context, AppRoutes.bpInput);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = bpService.errorMessage ?? 'Failed to connect to device';
            _selectedDevice = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _selectedDevice = null;
        });
      }
    }
  }

  Widget _buildDeviceItem(ScanResult result) {
    final device = result.device;
    final rssi = result.rssi;

    // RSSI signal strength indicator
    Icon signalIcon;
    if (rssi >= -60) {
      signalIcon = const Icon(Icons.signal_cellular_4_bar, color: Colors.green);
    } else if (rssi >= -70) {
      signalIcon = const Icon(Icons.signal_cellular_alt, color: Colors.orange);
    } else if (rssi >= -80) {
      signalIcon = const Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: Colors.orange);
    } else {
      signalIcon = const Icon(Icons.signal_cellular_0_bar, color: Colors.red);
    }

    final isConnecting = _selectedDevice != null && _selectedDevice!.id == device.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.bluetooth_searching),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(device.id.id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            signalIcon,
            const SizedBox(width: 8),
            if (isConnecting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              ElevatedButton(
                onPressed: () => _connectToDevice(device),
                child: const Text('Connect'),
              ),
          ],
        ),
        onTap: isConnecting ? null : () => _connectToDevice(device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bpService = Provider.of<BPService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect BP Monitor'),
      ),
      body: _isCheckingPermissions
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking permissions...'),
          ],
        ),
      )
          : Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Your Blood Pressure Monitor',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Make sure your device is turned on and in pairing mode.',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: _isScanning ? 'Scanning...' : 'Scan for Devices',
                    onPressed: _isScanning ? _stopScan : _startScan,
                    isLoading: _isScanning,
                    icon: _isScanning ? null : Icons.search,
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Connected device info
          if (bpService.connectedDevice != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_connected, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connected Device',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              bpService.connectedDevice!.name.isNotEmpty
                                  ? bpService.connectedDevice!.name
                                  : 'Unknown Device',
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await bpService.disconnectDevice();
                        },
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.bpInput);
                      },
                      child: const Text('Take Reading'),
                    ),
                  ),
                ],
              ),
            ),

          // Devices list
          Expanded(
            child: _isScanning && _scanResults.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Scanning for devices...'),
                ],
              ),
            )
                : _scanResults.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_searching,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No devices found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure your device is turned on and in pairing mode',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                return _buildDeviceItem(result);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }
}