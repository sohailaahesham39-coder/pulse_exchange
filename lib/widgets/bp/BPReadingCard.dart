import 'package:flutter/material.dart';

import '../../model/BPReadingModel.dart';
import '../../config/AppTheme.dart';
import 'BPStatusIndicator.dart';

class BPReadingCard extends StatelessWidget {
  final BPReadingModel reading;
  final VoidCallback? onTap;
  final bool showDetailedStatus;

  const BPReadingCard({
    Key? key,
    required this.reading,
    this.onTap,
    this.showDetailedStatus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              BPStatusIndicator(
                systolic: reading.systolic,
                diastolic: reading.diastolic,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reading.formattedReading,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pulse: ${reading.pulse}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTheme.getBPStatusText(reading.systolic, reading.diastolic),
                      style: TextStyle(
                        color: AppTheme.getBPStatusColor(reading.systolic, reading.diastolic),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (showDetailedStatus) ...[
                      const SizedBox(height: 4),
                      Text(
                        reading.getStatusDescription(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reading.formattedTimestamp,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Source: ${reading.source}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}