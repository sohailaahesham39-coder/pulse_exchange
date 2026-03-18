import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/AppConstants.dart';
import '../../config/AppRoutes.dart';

import '../../services/AuthService.dart';

import '../../widget/common/CustomButton.dart';


class MedRequestScreen extends StatefulWidget {
  const MedRequestScreen({Key? key}) : super(key: key);

  @override
  State<MedRequestScreen> createState() => _MedRequestScreenState();
}

class _MedRequestScreenState extends State<MedRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _detailsController = TextEditingController();

  String _selectedType = 'Blood Pressure';
  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // In a real app, this would call the medication service to create a request
      // For now we'll just simulate success
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication request submitted successfully')),
      );

      // Navigate to the search screen to see available medications
      Navigator.pushReplacementNamed(context, AppRoutes.medSearch, arguments: {
        'searchQuery': _medicationNameController.text,
        'medicationType': _selectedType,
      });
    } catch (e) {
      debugPrint('Error submitting request: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Medication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info section
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      Text(
                        'Request a Medication',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fill in the details of the medication you need. Our system will match your request with available donations or notify potential donors in your area.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Medication information section
              const Text(
                'Medication Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Medication name
              TextFormField(
                controller: _medicationNameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  hintText: 'E.g., Lisinopril, Metformin, etc.',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Medication type dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Medication Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                items: AppConstants.medicationCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (Optional)',
                  hintText: 'E.g., 10mg, 500mg, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity Needed',
                  hintText: 'Number of pills/tablets/units',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Urgency
              SwitchListTile(
                title: const Text('Urgent Request'),
                subtitle: const Text('Mark if you need this medication urgently'),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Additional details
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Additional Details (Optional)',
                  hintText: 'Any specific requirements or information',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: const [
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'By submitting this request, you acknowledge that medication exchanges should only be conducted for non-controlled, legally transferable medications. Always consult your healthcare provider before taking any medication.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Submit Request',
                  onPressed: _submitRequest,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 16),

              // Search existing donations
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.medSearch);
                  },
                  child: const Text('Search Available Medications Instead'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}