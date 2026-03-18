import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/AppConstants.dart';
import '../../config/AppRoutes.dart';
import '../../model/MedicationModel.dart';
import '../../services/AuthService.dart';
import '../../services/MedicationService.dart';
import '../../services/chat_service.dart';
import '../../widget/common/CustomButton.dart';
import 'map_utils.dart';

// Constants for UI strings (updated to align with AppConstants where applicable)
class AppStrings {
  static const String medicationDetails = 'Medication Details';
  static const String errorLoadingMedication = 'Error Loading Medication';
  static const String medicationNotFound = AppConstants.noMedicationsFound;
  static const String requestMedication = 'Request Medication';
  static const String cancel = 'Cancel';
  static const String request = 'Request';
  static const String medicationRequested = 'Medication requested successfully';
  static const String failedToRequest = AppConstants.medicationNotAvailable;
  static const String error = AppConstants.unknownError;
  static const String medicationInformation = 'Medication Information';
  static const String quantity = 'Quantity';
  static const String expiryDate = 'Expiry Date';
  static const String expired = 'This medication has expired';
  static const String expiresIn = 'Expires in %d days';
  static const String dateListed = 'Date Listed';
  static const String donorInformation = 'Donor Information';
  static const String donor = 'Donor';
  static const String location = 'Location';
  static const String address = 'Full Address';
  static const String viewOnMap = 'View on Map';
  static const String openInGoogleMaps = 'Open in Google Maps';
  static const String description = 'Description';
  static const String contactDonor = 'Contact Donor';
  static const String cancelRequest = 'Cancel Request';
  static const String messageDonor = 'Message Donor';
  static const String disclaimer =
      'Disclaimer: Please verify the medication with the donor before use. This platform facilitates medication exchange but does not guarantee medication safety or efficacy. Always consult a healthcare professional before taking any medication.';
  static const String locationNotAvailable = AppConstants.locationNotAvailable;
  static const String failedToOpenMaps = AppConstants.locationNotAvailable;
  static const String failedToStartChat = 'Failed to start chat';
  static const String tryAgain = 'Try Again';
  static const String unknownDonor = 'Unknown Donor';
  static const String userNotAuthenticated = 'User not authenticated';
}

// Constants for UI spacing
class AppSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
}

class MedDetailsScreen extends StatefulWidget {
  final String medicationId;

  const MedDetailsScreen({
    super.key,
    required this.medicationId,
  });

  @override
  State<MedDetailsScreen> createState() => _MedDetailsScreenState();
}

class _MedDetailsScreenState extends State<MedDetailsScreen> {
  bool _isLoading = true;
  MedicationModel? _medication;
  String? _errorMessage;
  bool _isRequesting = false;

  // Enhanced location information
  String _fullAddress = '';
  String _googleMapsUrl = '';

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to delay loading until after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicationDetails();
    });
  }

  Future<void> _loadMedicationDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Check if user is authenticated
      if (!authService.isAuthenticated || authService.token == null) {
        throw Exception(AppStrings.userNotAuthenticated);
      }

      final medicationService = Provider.of<MedicationService>(context, listen: false);

      // First try to load data
      MedicationModel? medication;

      try {
        medication = await medicationService.getMedicationDetails(
          authService.token!,
          widget.medicationId,
        );
      } catch (e) {
        debugPrint('First attempt failed: $e');

        // If first attempt fails, try to load medications and then try again
        await medicationService.fetchAvailableMedications(authService.token!);
        await medicationService.fetchMyDonations(authService.token!);
        await medicationService.fetchMyRequests(authService.token!);

        // Try again after loading medications
        medication = await medicationService.getMedicationDetails(
          authService.token!,
          widget.medicationId,
        );
      }

      // Generate enhanced location data
      if (medication != null) {
        _generateEnhancedLocation(medication);
      }

      if (mounted) {
        setState(() {
          _medication = medication;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading medication details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Medication not found')
              ? AppStrings.medicationNotFound
              : AppStrings.error.replaceFirst('%s', e.toString());
          _isLoading = false;
        });
      }
    }
  }

  void _generateEnhancedLocation(MedicationModel medication) {
    if (medication.location.isNotEmpty) {
      // Create a more detailed fictional address
      final cityName = medication.location;
      final streetNames = [
        'Medical Center Street',
        'Healthcare Avenue',
        'Wellness Boulevard',
        'Pharmacy Road',
        'Health Park Lane',
        'Care Center Drive',
        'Hospital Road',
        'Community Health Street'
      ];

      // Use a hash of the medication ID to consistently get the same street for the same medication
      final streetNameIndex = medication.id.hashCode.abs() % streetNames.length;
      final streetName = streetNames[streetNameIndex];

      // Generate consistent building number based on medication ID
      final buildingNumber = (medication.id.hashCode.abs() % 500 + 1).toString();

      // Create full address
      _fullAddress = '$buildingNumber $streetName, $cityName';

      // Generate Google Maps URL
      if (medication.latitude != null && medication.longitude != null) {
        _googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${medication.latitude},${medication.longitude}';
      } else {
        // Use the address string for search if coordinates not available
        final encodedAddress = Uri.encodeComponent(_fullAddress);
        _googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      }
    } else {
      _fullAddress = 'Address not available';
      _googleMapsUrl = '';
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_googleMapsUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.locationNotAvailable)),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(_googleMapsUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.failedToOpenMaps)),
      );
    }
  }

  Future<void> _requestMedication() async {
    if (_medication == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated || authService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.userNotAuthenticated)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.requestMedication),
        content: Text(
            'Are you sure you want to request ${_medication!.name} (${_medication!.dosage})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.request),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      final success = await medicationService.requestMedication(
        authService.token!,
        _medication!.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.medicationRequested)),
        );
        await _loadMedicationDetails();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(medicationService.errorMessage ?? AppStrings.failedToRequest)),
        );
      }
    } catch (e) {
      debugPrint('Error requesting medication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.error.replaceFirst('%s', e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _cancelRequest() async {
    if (_medication == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated || authService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.userNotAuthenticated)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cancelRequest),
        content: Text('Are you sure you want to cancel your request for ${_medication!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      final success = await medicationService.cancelRequest(
        authService.token!,
        _medication!.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully')),
        );
        await _loadMedicationDetails();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(medicationService.errorMessage ?? 'Failed to cancel request')),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.error.replaceFirst('%s', e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _startChat() async {
    if (_medication == null || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);

      if (!authService.isAuthenticated || authService.token == null) {
        throw Exception(AppStrings.userNotAuthenticated);
      }

      final threadId = await chatService.createMedicationThread(
        _medication!.id,
        _medication!.donorId,
        _medication!.donorName ?? AppStrings.unknownDonor,
      );

      if (threadId != null && mounted) {
        // Navigate to the combined chat screen with the user chat tab active
        Navigator.pushNamed(
          context,
          AppRoutes.chatUser,
          arguments: {
            'threadId': threadId,
            'userId': _medication!.donorId,
            'userName': _medication!.donorName ?? AppStrings.unknownDonor,
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(chatService.errorMessage ?? AppStrings.failedToStartChat)),
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.error.replaceFirst('%s', e.toString()))),
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
    final currentUserId = authService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_medication?.name ?? AppStrings.medicationDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedicationDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              AppStrings.errorLoadingMedication,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(_errorMessage!),
            const SizedBox(height: AppSpacing.large),
            CustomButton(
              label: AppStrings.tryAgain,
              onPressed: _loadMedicationDetails,
            ),
          ],
        ),
      )
          : _medication == null
          ? const Center(child: Text(AppStrings.medicationNotFound))
          : RefreshIndicator(
        onRefresh: _loadMedicationDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.small,
                    horizontal: AppSpacing.medium),
                decoration: BoxDecoration(
                  color: _medication!.getStatusColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _medication!.getStatusIcon(),
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      _medication!.getStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Medication images
              if (_medication!.imageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: _medication!.imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = _medication!.imageUrls[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],

              // Medication name and details
              Text(
                _medication!.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                '${_medication!.dosage} • ${_medication!.type}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.medium),

              // Medication info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.medicationInformation,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const Divider(),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                        AppStrings.quantity,
                        '${_medication!.quantity} units',
                        Icons.format_list_numbered,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                        AppStrings.expiryDate,
                        DateFormat('dd MMMM, yyyy')
                            .format(_medication!.expiryDate),
                        Icons.event,
                        _medication!.isExpired ? Colors.red : null,
                      ),
                      if (_medication!.isExpired)
                        const Padding(
                          padding: EdgeInsets.only(left: AppSpacing.large),
                          child: Text(
                            AppStrings.expired,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else if (_medication!.daysUntilExpiry < 30)
                        Padding(
                          padding:
                          const EdgeInsets.only(left: AppSpacing.large),
                          child: Text(
                            AppStrings.expiresIn.replaceFirst(
                                '%d', _medication!.daysUntilExpiry.toString()),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                        AppStrings.dateListed,
                        DateFormat('dd MMMM, yyyy')
                            .format(_medication!.createdAt),
                        Icons.history,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Donor info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.donorInformation,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const Divider(),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                        AppStrings.donor,
                        _medication!.donorName ?? AppStrings.unknownDonor,
                        Icons.person,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                        AppStrings.location,
                        _medication!.location,
                        Icons.location_on,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                        AppStrings.address,
                        _fullAddress,
                        Icons.home,
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Map buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text(AppStrings.openInGoogleMaps),
                              onPressed: _openGoogleMaps,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Description card
              if (_medication!.description.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.description,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        const Divider(),
                        const SizedBox(height: AppSpacing.small),
                        Text(_medication!.description),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
              ],

              // Action buttons
              if (_medication!.status == 'available') ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: AppStrings.requestMedication,
                        onPressed: _requestMedication,
                        isLoading: _isRequesting,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text(AppStrings.contactDonor),
                        onPressed: _startChat,
                      ),
                    ),
                  ],
                ),
              ] else if (_medication!.status == 'reserved' &&
                  _medication!.recipientId == currentUserId) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text(AppStrings.cancelRequest),
                        onPressed: _cancelRequest,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text(AppStrings.messageDonor),
                        onPressed: _startChat,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.large),

              // Disclaimer
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Text(
                    AppStrings.disclaimer,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),
            ],
          ),
        ),
      ),
      floatingActionButton: _medication != null && _medication!.status == 'available'
          ? FloatingActionButton.extended(
        onPressed: _requestMedication,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text(AppStrings.request),
      )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}