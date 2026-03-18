import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/AppRoutes.dart';
import '../../config/AppTheme.dart';
import '../../model/BPReadingModel.dart';
import '../../services/AuthService.dart';
import '../../services/BPService.dart';
import '../../widget/bp/BPReadingCard.dart';
import '../../widget/common/CustomButton.dart';

class BPHistoryScreen extends StatefulWidget {
  const BPHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BPHistoryScreen> createState() => _BPHistoryScreenState();
}

class _BPHistoryScreenState extends State<BPHistoryScreen> {
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final bpService = Provider.of<BPService>(context, listen: false);

      if (authService.isAuthenticated && authService.token != null) {
        // Get userId from AuthService
        final userId = authService.currentUser?.userId ?? 'mock_user'; // Fallback to mock_user if null
        if (userId == null) {
          throw Exception('User ID not found. Please log in again.');
        }

        await bpService.fetchReadings(
          authService.token!,
          userId,
          startDate: _startDate,
          endDate: _endDate,
        );
      }
    } catch (e) {
      debugPrint('Error loading BP history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading BP history: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
      _loadData();
    }
  }

  void _filterByCategory(String category) {
    if (_selectedCategory == category) {
      setState(() {
        _selectedCategory = null;
      });
    } else {
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCategory = null;
    });
    _loadData();
  }

  List<BPReadingModel> _getFilteredReadings(List<BPReadingModel> readings) {
    if (_selectedCategory == null) {
      return readings;
    }

    return readings.where((reading) {
      switch (_selectedCategory) {
        case 'Normal':
          return reading.status == 'normal';
        case 'Elevated':
          return reading.status == 'elevated';
        case 'Stage 1':
          return reading.status == 'hypertension_stage1';
        case 'Stage 2':
          return reading.status == 'hypertension_stage2';
        case 'Crisis':
          return reading.status == 'hypertensive_crisis';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bpService = Provider.of<BPService>(context);
    final readings = _getFilteredReadings(bpService.readings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BP History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Date range indicator
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),

          // Category filter chips
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.category, size: 16),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_selectedCategory!),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Readings list
          Expanded(
            child: readings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No blood pressure readings found'),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Add Reading',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.bpInput);
                    },
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                return BPReadingCard(
                  reading: reading,
                  showDetailedStatus: true,
                  onTap: () => _showReadingDetails(reading),
                );
              },
            ),
          ),

          // Stats bar
          if (readings.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Readings',
                    readings.length.toString(),
                    Icons.summarize,
                  ),
                  _buildStatItem(
                    'Average',
                    _calculateAverage(readings),
                    Icons.trending_up,
                  ),
                  _buildStatItem(
                    'Last Reading',
                    _formatLastReadingDate(readings),
                    Icons.access_time,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.bpInput);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _calculateAverage(List<BPReadingModel> readings) {
    if (readings.isEmpty) return '0/0';

    int systolicSum = 0;
    int diastolicSum = 0;

    for (final reading in readings) {
      systolicSum += reading.systolic;
      diastolicSum += reading.diastolic;
    }

    final avgSystolic = (systolicSum / readings.length).round();
    final avgDiastolic = (diastolicSum / readings.length).round();

    return '$avgSystolic/$avgDiastolic';
  }

  String _formatLastReadingDate(List<BPReadingModel> readings) {
    if (readings.isEmpty) return 'N/A';

    final latestReading = readings.first ;
    final now = DateTime.now();
    final difference = now.difference(latestReading.timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(latestReading.timestamp);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Readings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Date range
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              subtitle: Text(
                _startDate != null && _endDate != null
                    ? '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                    : 'All Time',
              ),
              onTap: () {
                Navigator.pop(context);
                _selectDateRange();
              },
            ),

            // BP category
            const ListTile(
              leading: Icon(Icons.category),
              title: Text('BP Category'),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Normal'),
                  selected: _selectedCategory == 'Normal',
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _filterByCategory('Normal');
                  },
                ),
                FilterChip(
                  label: const Text('Elevated'),
                  selected: _selectedCategory == 'Elevated',
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _filterByCategory('Elevated');
                  },
                ),
                FilterChip(
                  label: const Text('Stage 1'),
                  selected: _selectedCategory == 'Stage 1',
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _filterByCategory('Stage 1');
                  },
                ),
                FilterChip(
                  label: const Text('Stage 2'),
                  selected: _selectedCategory == 'Stage 2',
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _filterByCategory('Stage 2');
                  },
                ),
                FilterChip(
                  label: const Text('Crisis'),
                  selected: _selectedCategory == 'Crisis',
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _filterByCategory('Crisis');
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearFilters();
                },
                child: const Text('Clear All Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReadingDetails(BPReadingModel reading) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BP values
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reading.formattedReading,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'mmHg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Text(
                'Pulse: ${reading.pulse} bpm',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.getBPStatusColor(reading.systolic, reading.diastolic).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.getBPStatusColor(reading.systolic, reading.diastolic),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      AppTheme.getBPStatusText(reading.systolic, reading.diastolic),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getBPStatusColor(reading.systolic, reading.diastolic),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reading.getStatusDescription(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date and time
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(DateFormat('EEEE, MMMM d, y').format(reading.timestamp)),
                dense: true,
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(DateFormat('h:mm a').format(reading.timestamp)),
                dense: true,
              ),

              // Source
              ListTile(
                leading: Icon(
                  reading.source == 'manual' ? Icons.edit : Icons.bluetooth,
                ),
                title: const Text('Source'),
                subtitle: Text(reading.source),
                dense: true,
              ),

              // Notes
              if (reading.notes != null && reading.notes!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.note),
                  title: const Text('Notes'),
                  subtitle: Text(reading.notes!),
                  dense: true,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReading(reading);
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReading(BPReadingModel reading) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reading'),
        content: const Text('Are you sure you want to delete this reading?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final bpService = Provider.of<BPService>(context, listen: false);

      if (authService.isAuthenticated && authService.token != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          final success = await bpService.deleteReading(
            authService.token!,
            reading.id,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reading deleted successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(bpService.errorMessage ?? 'Failed to delete reading')),
            );
          }
        } catch (e) {
          debugPrint('Error deleting reading: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred while deleting the reading')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }
}