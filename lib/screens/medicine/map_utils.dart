import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/AppConstants.dart';
import '../../model/MedicationModel.dart';

class MapUtils {
  static Future<void> showLocation(
      BuildContext context,
      MedicationModel medication,
      ) async {
    if (medication.latitude == null || medication.longitude == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.locationNotAvailable)),
        );
      }
      return;
    }

    final lat = medication.latitude!;
    final lng = medication.longitude!;

    // Use the location name from the medication model
    final locationName = medication.location;
    Uri mapUri;

    // Determine platform-specific map URL
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Apple Maps URL for iOS - Using location name as the query
      mapUri = Uri.parse('maps://?q=${Uri.encodeComponent(locationName)}&ll=$lat,$lng&z=15');
    } else {
      // Google Maps URL for Android and other platforms
      // Use the location name in the query parameter for better display
      mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationName)}&center=$lat,$lng&zoom=15');
    }

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(
          mapUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to a generic geo URI with location name as label
        final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(locationName)})');
        if (await canLaunchUrl(geoUri)) {
          await launchUrl(
            geoUri,
            mode: LaunchMode.externalApplication,
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.locationNotAvailable)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening map: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppConstants.unknownError)),
        );
      }
    }
  }
}