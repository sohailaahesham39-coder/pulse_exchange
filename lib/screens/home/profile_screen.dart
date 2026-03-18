import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/AppRoutes.dart';
import '../../services/AuthService.dart';
import '../../widget/common/CustomButton.dart';

// Constants for UI strings (for maintainability and localization, consistent with MedDetailsScreen)
class AppStrings {
  static const String medicationDetails = 'Medication Details';
  static const String errorLoadingMedication = 'Error Loading Medication';
  static const String medicationNotFound = 'Medication not found';
  static const String requestMedication = 'Request Medication';
  static const String cancel = 'Cancel';
  static const String request = 'Request';
  static const String medicationRequested = 'Medication requested successfully';
  static const String failedToRequest = 'Failed to request medication';
  static const String error = 'Error: %s';
  static const String medicationInformation = 'Medication Information';
  static const String quantity = 'Quantity';
  static const String expiryDate = 'Expiry Date';
  static const String expired = 'This medication has expired';
  static const String expiresIn = 'Expires in %d days';
  static const String dateListed = 'Date Listed';
  static const String donorInformation = 'Donor Information';
  static const String donor = 'Donor';
  static const String location = 'Location';
  static const String viewOnMap = 'View on Map';
  static const String description = 'Description';
  static const String contactDonor = 'Contact Donor';
  static const String cancelRequest = 'Cancel Request';
  static const String messageDonor = 'Message Donor';
  static const String disclaimer =
      'Disclaimer: Please verify the medication with the donor before use. This platform facilitates medication exchange but does not guarantee medication safety or efficacy. Always consult a healthcare professional before taking any medication.';
  static const String locationNotAvailable = 'Location coordinates not available';
  static const String failedToOpenMaps = 'Could not open maps application';
  static const String failedToStartChat = 'Failed to start chat';
  static const String tryAgain = 'Try Again';
  static const String unknownDonor = 'Unknown Donor';
  static const String myProfile = 'My Profile';
  static const String pleaseLogin = 'Please log in to view your profile';
  static const String login = 'Login';
  static const String profileUpdated = 'Profile updated successfully';
  static const String failedToUpdateProfile = 'Failed to update profile';
  static const String contactInformation = 'Contact Information';
  static const String accountInformation = 'Account Information';
  static const String activity = 'Activity';
  static const String saveProfile = 'Save Profile';
  static const String fullName = 'Full Name';
  static const String email = 'Email';
  static const String phoneNumber = 'Phone Number';
  static const String accountStatus = 'Account Status';
  static const String memberSince = 'Member Since';
  static const String bpReadings = 'BP Readings';
  static const String donated = 'Donated';
  static const String requested = 'Requested';
  static const String doctor = 'Doctor';
  static const String patient = 'Patient';
  static const String verified = 'Verified';
  static const String notVerified = 'Not Verified';
  static const String enterName = 'Please enter your name';
  static const String enterPhone = 'Please enter your phone number';
  static const String enterLocation = 'Please enter your location';
  static const String errorPickingImage = 'Error picking image';
}

// Constants for UI spacing (consistent with MedDetailsScreen)
class AppSpacing {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  XFile? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _locationController.text = user.location ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        setState(() {
          _profileImage = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.errorPickingImage)),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.isAuthenticated && authService.token != null) {
        String? profileImageUrl;
        if (_profileImage != null) {
          // Simulate image upload (replace with actual upload logic)
          await Future.delayed(const Duration(seconds: 1));
          profileImageUrl = 'https://example.com/images/profile.jpg';
        }

        final success = await authService.updateProfile(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          location: _locationController.text,
          profileImage: profileImageUrl,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.profileUpdated)),
          );
          setState(() {
            _isEditing = false;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.failedToUpdateProfile)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
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
    final user = Provider.of<AuthService>(context).currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(AppStrings.pleaseLogin),
              const SizedBox(height: AppSpacing.medium),
              CustomButton(
                label: AppStrings.login,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myProfile),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserProfile(); // Reset form fields
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImage != null
                      ? FileImage(File(_profileImage!.path))
                      : user.profileImageUrl != null &&
                      user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                  as ImageProvider
                      : const AssetImage('assets/images/default_avatar.png'),
                ),
                if (_isEditing)
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.small),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),

            // User name and role badge
            if (!_isEditing) ...[
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small),
                decoration: BoxDecoration(
                  color: user.role == 'doctor'
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  user.role == 'doctor'
                      ? AppStrings.doctor
                      : AppStrings.patient,
                  style: TextStyle(
                    color: user.role == 'doctor'
                        ? Colors.blue.shade800
                        : Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              // Contact info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.contactInformation,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const Divider(),
                      _buildInfoRow(
                          Icons.email, AppStrings.email, user.email),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                          Icons.phone,
                          AppStrings.phoneNumber,
                          user.phone?? 'Not provided'),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                          Icons.location_on,
                          AppStrings.location,
                          user.location ?? 'Not provided'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Account info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.accountInformation,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const Divider(),
                      _buildInfoRow(
                        Icons.verified,
                        AppStrings.accountStatus,
                        user.isVerified
                            ? AppStrings.verified
                            : AppStrings.notVerified,
                        user.isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _buildInfoRow(
                        Icons.calendar_today,
                        AppStrings.memberSince,
                        _formatDate(user.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Activity stats card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.activity,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            AppStrings.bpReadings,
                            '28', // Replace with actual data
                            Icons.favorite,
                            Colors.red,
                          ),
                          _buildStatColumn(
                            AppStrings.donated,
                            user.donatedMedications?.length.toString() ??
                                '0',
                            Icons.volunteer_activism,
                            Colors.green,
                          ),
                          _buildStatColumn(
                            AppStrings.requested,
                            user.requestedMedications?.length.toString() ??
                                '0',
                            Icons.request_page,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Edit profile form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.fullName,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.enterName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Email field (read-only)
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.email,
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.phoneNumber,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.enterPhone;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Location field
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.location,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.enterLocation;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.large),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: AppStrings.saveProfile,
                        onPressed: _updateProfile,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? color]) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: AppSpacing.medium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}