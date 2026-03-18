import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../model/BPReadingModel.dart';
import '../../config/AppTheme.dart';
import '../../services/AuthService.dart';
import '../../services/BPService.dart';
import '../../widget/bp/BPStatusIndicator.dart';
import '../../widget/common/CustomButton.dart';

class BPInputScreen extends StatefulWidget {
  const BPInputScreen({Key? key}) : super(key: key);

  @override
  State<BPInputScreen> createState() => _BPInputScreenState();
}

class _BPInputScreenState extends State<BPInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String _source = 'manual';
  String? _statusText;
  Color? _statusColor;

  @override
  void initState() {
    super.initState();
    _pulseController.text = '72';
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateStatus() {
    if (_systolicController.text.isNotEmpty && _diastolicController.text.isNotEmpty) {
      try {
        final systolic = int.parse(_systolicController.text);
        final diastolic = int.parse(_diastolicController.text);

        setState(() {
          _statusText = AppTheme.getBPStatusText(systolic, diastolic);
          _statusColor = AppTheme.getBPStatusColor(systolic, diastolic);
        });
      } catch (e) {
        setState(() {
          _statusText = null;
          _statusColor = null;
        });
      }
    } else {
      setState(() {
        _statusText = null;
        _statusColor = null;
      });
    }
  }

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final bpService = Provider.of<BPService>(context, listen: false);

      if (authService.isAuthenticated && authService.token != null) {
        final systolic = int.parse(_systolicController.text);
        final diastolic = int.parse(_diastolicController.text);
        final pulse = int.parse(_pulseController.text);
        final notes = _notesController.text.isNotEmpty ? _notesController.text : null;

        final success = await bpService.addReading(
          authService.token!,
          systolic: systolic,
          diastolic: diastolic,
          pulse: pulse,
          notes: notes,
          source: _source,
          userId: '',
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reading saved successfully')),
          );

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(bpService.errorMessage ?? 'Failed to save reading')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving reading: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getReadingFromDevice() async {
    final bpService = Provider.of<BPService>(context, listen: false);

    if (bpService.connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device connected. Please connect a device first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _source = bpService.connectedDevice!.name;
    });

    try {
      final reading = await bpService.getReadingFromDevice();

      if (reading != null) {
        setState(() {
          _systolicController.text = reading['systolic'].toString();
          _diastolicController.text = reading['diastolic'].toString();
          _pulseController.text = reading['pulse'].toString();

          _updateStatus();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(bpService.errorMessage ?? 'Failed to get reading from device')),
        );
      }
    } catch (e) {
      debugPrint('Error getting reading from device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bpService = Provider.of<BPService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Blood Pressure Reading'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bpService.connectedDevice != null) ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bluetooth_connected,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Device Connected',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                bpService.connectedDevice!.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomButton(
                          label: 'Get Reading',
                          onPressed: _getReadingFromDevice,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolicController,
                      decoration: const InputDecoration(
                        labelText: 'Systolic',
                        hintText: '120',
                        suffixText: 'mmHg',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final systolic = int.tryParse(value);
                        if (systolic == null) {
                          return 'Invalid number';
                        }
                        if (systolic < 60 || systolic > 250) {
                          return 'Invalid range';
                        }
                        return null;
                      },
                      onChanged: (value) => _updateStatus(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _diastolicController,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic',
                        hintText: '80',
                        suffixText: 'mmHg',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final diastolic = int.tryParse(value);
                        if (diastolic == null) {
                          return 'Invalid number';
                        }
                        if (diastolic < 40 || diastolic > 180) {
                          return 'Invalid range';
                        }
                        return null;
                      },
                      onChanged: (value) => _updateStatus(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pulseController,
                decoration: const InputDecoration(
                  labelText: 'Pulse',
                  hintText: '72',
                  suffixText: 'bpm',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final pulse = int.tryParse(value);
                  if (pulse == null) {
                    return 'Invalid number';
                  }
                  if (pulse < 30 || pulse > 220) {
                    return 'Invalid range';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any observations or context',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_statusText != null && _statusColor != null) ...[
                Center(
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BPStatusIndicator(
                                systolic: int.tryParse(_systolicController.text) ?? 120,
                                diastolic: int.tryParse(_diastolicController.text) ?? 80,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _statusText!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getStatusDescription(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _statusColor!.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Save Reading',
                  onPressed: _saveReading,
                  icon: Icons.save,
                ),
              ),
              if (bpService.connectedDevice == null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('Connect Device'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/bp-connect-device');
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusDescription() {
    if (_systolicController.text.isEmpty || _diastolicController.text.isEmpty) {
      return '';
    }

    try {
      final systolic = int.parse(_systolicController.text);
      final diastolic = int.parse(_diastolicController.text);

      if (systolic >= 180 || diastolic >= 120) {
        return 'Hypertensive Crisis! Seek emergency medical attention immediately!';
      } else if (systolic >= 140 || diastolic >= 90) {
        return 'Stage 2 Hypertension. Please consult a doctor for treatment options.';
      } else if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) {
        return 'Stage 1 Hypertension. Consider lifestyle changes and consult a doctor.';
      } else if ((systolic >= 120 && systolic < 130) && diastolic < 80) {
        return 'Elevated Blood Pressure. Consider heart-healthy lifestyle changes.';
      } else {
        return 'Normal Blood Pressure. Maintain a healthy lifestyle.';
      }
    } catch (e) {
      return '';
    }
  }
}