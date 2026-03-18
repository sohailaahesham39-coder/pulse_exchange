import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/AppRoutes.dart';
import '../../model/BPReadingModel.dart';
import '../../config/AppTheme.dart';
import '../../services/AuthService.dart';
import '../../services/BPService.dart';
import '../../widget/bp/BPReadingCard.dart';
import '../../widget/bp/BPStatusIndicator.dart';
import '../../widget/common/CustomButton.dart';

class BPDashboardScreen extends StatefulWidget {
  const BPDashboardScreen({Key? key}) : super(key: key);

  @override
  State<BPDashboardScreen> createState() => _BPDashboardScreenState();
}

class _BPDashboardScreenState extends State<BPDashboardScreen> {
  bool _isLoading = false;
  String _selectedPeriod = 'week';

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

        // Load BP readings with date filtering based on selected period
        final now = DateTime.now();
        DateTime? startDate;

        switch (_selectedPeriod) {
          case 'day':
            startDate = DateTime(now.year, now.month, now.day);
            break;
          case 'week':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case 'month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            break;
          case 'year':
            startDate = DateTime(now.year - 1, now.month, now.day);
            break;
        }

        await bpService.fetchReadings(
          authService.token!,
          userId,
          startDate: startDate,
        );
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bpService = Provider.of<BPService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.bpHistory);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.bpInput);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    final bpService = Provider.of<BPService>(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selection Tabs
            _buildPeriodTabs(),
            const SizedBox(height: 24),

            // Statistics Card
            _buildStatisticsCard(),
            const SizedBox(height: 24),

            // Chart Card
            _buildChartCard(),
            const SizedBox(height: 24),

            // Latest Readings
            Text(
              'Latest Readings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildLatestReadings(),
            const SizedBox(height: 24),

            // Actions
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodTab('Day', 'day'),
            _buildPeriodTab('Week', 'week'),
            _buildPeriodTab('Month', 'month'),
            _buildPeriodTab('Year', 'year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, String period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        _loadData();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final bpService = Provider.of<BPService>(context);
    final stats = bpService.getStatistics(period: _selectedPeriod);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),

            if (stats['average'] != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    label: 'Average',
                    value: '${stats['average']['systolic']}/${stats['average']['diastolic']}',
                    subLabel: 'mmHg',
                    icon: Icons.bar_chart,
                    color: AppTheme.getBPStatusColor(
                      stats['average']['systolic'],
                      stats['average']['diastolic'],
                    ),
                  ),
                  _buildStatItem(
                    label: 'Lowest',
                    value: '${stats['min']['systolic']}/${stats['min']['diastolic']}',
                    subLabel: 'mmHg',
                    icon: Icons.arrow_downward,
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    label: 'Highest',
                    value: '${stats['max']['systolic']}/${stats['max']['diastolic']}',
                    subLabel: 'mmHg',
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trend indicator
              if (stats['trend'] != null) ...[
                Row(
                  children: [
                    Icon(
                      stats['trend'] == 'improving'
                          ? Icons.trending_down
                          : stats['trend'] == 'worsening'
                          ? Icons.trending_up
                          : Icons.trending_flat,
                      color: stats['trend'] == 'improving'
                          ? Colors.green
                          : stats['trend'] == 'worsening'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stats['trend'] == 'improving'
                          ? 'Your blood pressure is improving'
                          : stats['trend'] == 'worsening'
                          ? 'Your blood pressure is worsening'
                          : 'Your blood pressure is stable',
                      style: TextStyle(
                        color: stats['trend'] == 'improving'
                            ? Colors.green
                            : stats['trend'] == 'worsening'
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              const Center(
                child: Text('No readings available for this period'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String subLabel,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          subLabel,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    final bpService = Provider.of<BPService>(context);
    final readings = bpService.readings;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blood Pressure Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),

            if (readings.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: LineChart(
                  _createLineChartData(readings),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Systolic', Colors.red),
                  const SizedBox(width: 24),
                  _buildLegendItem('Diastolic', Colors.blue),
                ],
              ),
            ] else ...[
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text('No readings available for this period'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LineChartData _createLineChartData(List<BPReadingModel> readings) {
    // Use only the latest 10 readings for the chart
    final limitedReadings = readings.length > 10
        ? readings.sublist(0, 10).reversed.toList()
        : readings.reversed.toList();

    // Create systolic spots
    final systolicSpots = limitedReadings
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.systolic.toDouble()))
        .toList();

    // Create diastolic spots
    final diastolicSpots = limitedReadings
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.diastolic.toDouble()))
        .toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        horizontalInterval: 20,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xffe7e8ec),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xffe7e8ec),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value % 1 == 0 && value >= 0 && value < limitedReadings.length) {
                final index = value.toInt();
                final reading = limitedReadings[index];
                // Show only even indices to avoid overcrowding
                if (index % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${reading.timestamp.day}/${reading.timestamp.month}',
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  );
                }
              }
              return const SizedBox();
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xffe7e8ec)),
      ),
      minX: 0,
      maxX: limitedReadings.length.toDouble() - 1,
      minY: 40, // Lowest reasonable diastolic
      maxY: 200, // Highest reasonable systolic
      lineBarsData: [
        // Systolic line
        LineChartBarData(
          spots: systolicSpots,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
        // Diastolic line
        LineChartBarData(
          spots: diastolicSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLatestReadings() {
    final bpService = Provider.of<BPService>(context);
    final readings = bpService.readings;

    if (readings.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No readings available'),
          ),
        ),
      );
    }

    // Show latest 5 readings
    final latestReadings = readings.length > 5 ? readings.sublist(0, 5) : readings;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: latestReadings.length,
      itemBuilder: (context, index) {
        final reading = latestReadings[index];
        return BPReadingCard(
          reading: reading,
          onTap: () {
            // Show reading details or option to delete
            _showReadingDetailDialog(reading);
          },
        );
      },
    );
  }

  void _showReadingDetailDialog(BPReadingModel reading) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BPStatusIndicator(
                  systolic: reading.systolic,
                  diastolic: reading.diastolic,
                  size: 50,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading.formattedReading,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pulse: ${reading.pulse} bpm',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppTheme.getBPStatusText(reading.systolic, reading.diastolic),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.getBPStatusColor(reading.systolic, reading.diastolic),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reading.getStatusDescription(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date:'),
                Text(
                  reading.formattedTimestamp,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Source:'),
                Text(
                  reading.source,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (reading.notes != null && reading.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(reading.notes!),
            ],
          ],
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
      }
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: CustomButton(
            label: 'Add Reading',
            icon: Icons.add,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.bpInput);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomButton(
            label: 'Connect Device',
            icon: Icons.bluetooth,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.bpConnectDevice);
            },
          ),
        ),
      ],
    );
  }
}