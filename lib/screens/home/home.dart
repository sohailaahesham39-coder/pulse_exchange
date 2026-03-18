import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulse_exchange/core/theme/AppRoutes.dart';
import 'package:pulse_exchange/data/repositories/AuthService.dart';
import 'package:pulse_exchange/data/repositories/BPService.dart';
import 'package:pulse_exchange/data/repositories/MedicationService.dart';
import 'package:pulse_exchange/widgets/bp/BPStatusIndicator.dart';
import 'package:pulse_exchange/widgets/common/CustomButton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isBPLoading = true;
  bool _isMedicationLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isBPLoading = true;
      _isMedicationLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated || authService.token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to continue')),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }

      final userId = authService.currentUser?.id ?? 'mock_user';

      final bpService = Provider.of<BPService>(context, listen: false);
      final medicationService = Provider.of<MedicationService>(context, listen: false);

      // Parallelize independent service calls
      await Future.wait([
        bpService.fetchReadings(authService.token!, userId).then((_) {
          if (mounted) setState(() => _isBPLoading = false);
        }),
        Future.wait([
          medicationService.fetchAvailableMedications(authService.token!),
          medicationService.fetchMyDonations(authService.token!),
          medicationService.fetchMyRequests(authService.token!),
        ]).then((_) {
          if (mounted) setState(() => _isMedicationLoading = false);
        }),
      ]);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
      debugPrint('Error loading data: $e');
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
    final authService = Provider.of<AuthService>(context);

    if (!authService.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to continue'),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Login',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      );
    }

    return _buildPatientHomeScreen();
  }

  Widget _buildPatientHomeScreen() {
    final bpService = Provider.of<BPService>(context);
    final medicationService = Provider.of<MedicationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse Exchange - Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
            tooltip: 'View Profile',
          ),
        ],
      ),
      body: _isLoading && (_isBPLoading && _isMedicationLoading)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _selectedIndex == 0
              ? _buildHomeTab(bpService, medicationService)
              : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 1:
              Navigator.pushNamed(context, AppRoutes.bpDashboard);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.medDashboard);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.chat);
              break;
            case 4:
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'BP Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BPService bpService, MedicationService medicationService) {
    final authService = Provider.of<AuthService>(context);
    final latestReading = bpService.readings.isNotEmpty ? bpService.readings.first : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${authService.currentUser?.name ?? 'User'}!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Blood Pressure',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.bpInput);
                        },
                        tooltip: 'Add BP Reading',
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _isBPLoading
                      ? const Center(child: CircularProgressIndicator())
                      : latestReading != null
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BPStatusIndicator(
                            systolic: latestReading.systolic,
                            diastolic: latestReading.diastolic,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestReading.formattedReading,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                'Pulse: ${latestReading.pulse} bpm',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                latestReading.formattedTimestamp,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        latestReading.getStatusDescription(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      const Center(
                        child: Text('No blood pressure readings recorded yet'),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: CustomButton(
                          label: 'Add First Reading',
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.bpInput);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.bpHistory);
                    },
                    child: const Text('View All Readings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medicine Exchange',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.medSearch);
                        },
                        tooltip: 'Search Medications',
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _isMedicationLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        title: 'Available',
                        value: medicationService.availableMedications.length.toString(),
                        icon: Icons.medication_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.medDashboard);
                        },
                      ),
                      _buildStatCard(
                        title: 'My Donations',
                        value: medicationService.myDonations.length.toString(),
                        icon: Icons.volunteer_activism,
                        color: Theme.of(context).colorScheme.secondary,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.medDashboard);
                        },
                      ),
                      _buildStatCard(
                        title: 'My Requests',
                        value: medicationService.myRequests.length.toString(),
                        icon: Icons.request_page,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.medDashboard);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Donate',
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.medDonate);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          label: 'Request',
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.medRequest);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Assistant',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Have questions about your health or medications?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Chat with Health Assistant',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.chatAI);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}