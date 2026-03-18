import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/AppRoutes.dart';
import '../../model/MedicationModel.dart';
import '../../services/AuthService.dart';
import '../../services/MedicationService.dart';
import '../../widget/common/CustomButton.dart';
import '../../widget/medication/MedCard.dart';

class MedDashboardScreen extends StatefulWidget {
  const MedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MedDashboardScreen> createState() => _MedDashboardScreenState();
}

class _MedDashboardScreenState extends State<MedDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final medicationService = Provider.of<MedicationService>(context, listen: false);

      if (authService.isAuthenticated && authService.token != null) {
        // Load medications
        await medicationService.fetchAvailableMedications(
          authService.token!,
          type: _selectedCategory,
        );

        // Load user's donations and requests
        await medicationService.fetchMyDonations(authService.token!);
        await medicationService.fetchMyRequests(authService.token!);
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _filterByCategory(String? category) async {
    if (_selectedCategory == category) {
      setState(() {
        _selectedCategory = null;
      });
    } else {
      setState(() {
        _selectedCategory = category;
      });
    }

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Exchange'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.medSearch);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: ' Donations'),
            Tab(text: ' Requests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableMedicationsTab(),
          _buildMyDonationsTab(),
          _buildMyRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.medDonate);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAvailableMedicationsTab() {
    final medicationService = Provider.of<MedicationService>(context);
    final medications = medicationService.availableMedications;

    return Column(
      children: [
        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (final category in ['Blood Pressure', 'Diabetes', 'Heart', 'Pain Relief', 'Other'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) => _filterByCategory(category),
                  ),
                ),
            ],
          ),
        ),

        // Medications list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: medications.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No medications available'),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Donate Medication',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.medDonate);
                    },
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final medication = medications[index];
                return MedCard(
                  medication: medication,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.medDetails,
                      arguments: {'medicationId': medication.id},
                    );
                  },
                  onRequest: () => _requestMedication(medication),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyDonationsTab() {
    final medicationService = Provider.of<MedicationService>(context);
    final donations = medicationService.myDonations;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: donations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You haven\'t donated any medications yet'),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Donate Medication',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.medDonate);
              },
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: donations.length,
        itemBuilder: (context, index) {
          final medication = donations[index];
          return MedCard(
            medication: medication,
            showDonorInfo: false,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.medDetails,
                arguments: {'medicationId': medication.id},
              );
            },
            onCancel: () => _cancelDonation(medication),
            onComplete: medication.status == 'reserved' ? () => _completeExchange(medication) : null,
          );
        },
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    final medicationService = Provider.of<MedicationService>(context);
    final requests = medicationService.myRequests;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: requests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You haven\'t requested any medications yet'),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Find Medications',
              onPressed: () {
                _tabController.animateTo(0);
              },
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final medication = requests[index];
          return MedCard(
            medication: medication,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.medDetails,
                arguments: {'medicationId': medication.id},
              );
            },
            onCancel: medication.status == 'reserved' ? () => _cancelRequest(medication) : null,
            onComplete: medication.status == 'reserved' ? () => _completeExchange(medication) : null,
          );
        },
      ),
    );
  }

  Future<void> _requestMedication(MedicationModel medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Medication'),
        content: Text('Are you sure you want to request ${medication.name} (${medication.dosage})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final medicationService = Provider.of<MedicationService>(context, listen: false);

        if (authService.isAuthenticated && authService.token != null) {
          final success = await medicationService.requestMedication(
            authService.token!,
            medication.id,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Medication requested successfully')),
            );

            // Switch to My Requests tab
            _tabController.animateTo(2);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(medicationService.errorMessage ?? 'Failed to request medication')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error requesting medication: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _cancelDonation(MedicationModel medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Donation'),
        content: Text('Are you sure you want to cancel your donation of ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final medicationService = Provider.of<MedicationService>(context, listen: false);

        if (authService.isAuthenticated && authService.token != null) {
          final success = await medicationService.cancelDonation(
            authService.token!,
            medication.id,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Donation cancelled successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(medicationService.errorMessage ?? 'Failed to cancel donation')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error cancelling donation: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _loadData();
        }
      }
    }
  }

  Future<void> _cancelRequest(MedicationModel medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Text('Are you sure you want to cancel your request for ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final medicationService = Provider.of<MedicationService>(context, listen: false);

        if (authService.isAuthenticated && authService.token != null) {
          final success = await medicationService.cancelRequest(
            authService.token!,
            medication.id,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request cancelled successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(medicationService.errorMessage ?? 'Failed to cancel request')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error cancelling request: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _loadData();
        }
      }
    }
  }

  Future<void> _completeExchange(MedicationModel medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Exchange'),
        content: Text('Confirm that you have completed the exchange for ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final medicationService = Provider.of<MedicationService>(context, listen: false);

        if (authService.isAuthenticated && authService.token != null) {
          final success = await medicationService.completeExchange(
            authService.token!,
            medication.id,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exchange completed successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(medicationService.errorMessage ?? 'Failed to complete exchange')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error completing exchange: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _loadData();
        }
      }
    }
  }
}