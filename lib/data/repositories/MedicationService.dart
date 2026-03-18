import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:pulse_exchange/core/theme/AppConstants.dart';
import 'package:pulse_exchange/data/models/MedicationModel.dart';

class MedicationService extends ChangeNotifier {
  final List<MedicationModel> _availableMedications = [];
  final List<MedicationModel> _myDonations = [];
  final List<MedicationModel> _myRequests = [];
  final List<MedicationModel> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Location _location = Location();
  LocationData? _currentLocation;
  Point? _mapboxPoint;

  // Getters
  List<MedicationModel> get availableMedications => List.unmodifiable(_availableMedications);
  List<MedicationModel> get myDonations => List.unmodifiable(_myDonations);
  List<MedicationModel> get myRequests => List.unmodifiable(_myRequests);
  List<MedicationModel> get recommendations => List.unmodifiable(_recommendations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LocationData? get currentLocation => _currentLocation;
  Point? get mapboxPoint => _mapboxPoint;

  // Initialize the service by loading stored data
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadMedications();
      await initLocation();
    } catch (e) {
      _errorMessage = 'Error initializing medication service: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize location service and Mapbox point
  Future<void> initLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      _currentLocation = await _location.getLocation();

      // Create Mapbox Point from location data
      if (_currentLocation != null) {
        _mapboxPoint = Point(
            coordinates: Position(
                _currentLocation!.longitude ?? 31.2357,
                _currentLocation!.latitude ?? 30.0444
            )
        );
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  // Update location with a Mapbox point
  void updateLocationWithMapboxPoint(Point point) {
    _mapboxPoint = point;
    final coords = point.coordinates;
    _currentLocation = LocationData.fromMap({
      'latitude': coords.lat,
      'longitude': coords.lng,
      'accuracy': 0.0,
      'altitude': 0.0,
      'speed': 0.0,
      'speed_accuracy': 0.0,
      'heading': 0.0,
      'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
    });
    notifyListeners();
  }

  // Get nearby medications based on current location
  List<MedicationModel> getNearbyMedications({double radiusInKm = 5.0}) {
    if (_currentLocation == null) return [];

    final currentLat = _currentLocation!.latitude ?? 0.0;
    final currentLng = _currentLocation!.longitude ?? 0.0;

    return _availableMedications.where((med) {
      if (med.latitude == null || med.longitude == null) return false;

      // Calculate distance using Haversine formula
      final distance = _calculateDistance(
          currentLat, currentLng,
          med.latitude!, med.longitude!
      );

      return distance <= radiusInKm;
    }).toList();
  }

  // Calculate distance between two coordinates using Haversine formula

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // distance in km
  }

// Helper function to convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
  // Convert degrees to radians

  // Load medications from secure storage
  Future<void> _loadMedications() async {
    try {
      // Load available medications
      final storedAvailable = await _secureStorage.read(key: 'available_medications');
      if (storedAvailable != null) {
        final data = jsonDecode(storedAvailable) as List;
        _availableMedications.clear();
        _availableMedications.addAll(data.map((item) => MedicationModel.fromJson(item)));
      }

      // Load donated medications
      final storedDonated = await _secureStorage.read(key: 'donated_medications');
      if (storedDonated != null) {
        final data = jsonDecode(storedDonated) as List;
        _myDonations.clear();
        _myDonations.addAll(data.map((item) => MedicationModel.fromJson(item)));
      }

      // Load requested medications
      final storedRequested = await _secureStorage.read(key: 'requested_medications');
      if (storedRequested != null) {
        final data = jsonDecode(storedRequested) as List;
        _myRequests.clear();
        _myRequests.addAll(data.map((item) => MedicationModel.fromJson(item)));
      }
    } catch (e) {
      _errorMessage = 'Error loading medications: $e';
      debugPrint(_errorMessage);
    }
  }

  // Fetch available medications with filtering options
  Future<void> fetchAvailableMedications(
      String token, {
        String? query,
        String? type,
        double? radius,
        bool nearbyOnly = false,
        bool nonExpiredOnly = true,
        String? sortBy,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    _recommendations.clear();
    notifyListeners();

    try {
      // In a real app, this would call an API
      // For this example, we'll simulate with mock data
      await Future.delayed(const Duration(seconds: 1));

      // First, populate with mock data if the list is empty
      if (_availableMedications.isEmpty) {
        await _populateMockData();
      }

      // Apply filters
      List<MedicationModel> filteredMedications = List.from(_availableMedications);

      // Filter by query (medication name)
      if (query != null && query.isNotEmpty) {
        filteredMedications = filteredMedications
            .where((med) => med.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        // Generate recommendations if query is provided
        if (filteredMedications.isNotEmpty) {
          _recommendations.addAll(getRecommendations(query, filteredMedications.first.type));
        } else {
          _recommendations.addAll(getRecommendationsByName(query));
        }
      }

      // Filter by type
      if (type != null && type.isNotEmpty) {
        filteredMedications = filteredMedications
            .where((med) => med.type.toLowerCase() == type.toLowerCase())
            .toList();
      }

      // Filter by expiry
      if (nonExpiredOnly) {
        filteredMedications = filteredMedications.where((med) => !med.isExpired).toList();
      }

      // Filter by location (if nearby only and we have current location)
      if (nearbyOnly && _currentLocation != null && radius != null) {
        // Use location-based filtering with actual distance calculation
        final currentLat = _currentLocation!.latitude ?? 0.0;
        final currentLng = _currentLocation!.longitude ?? 0.0;

        filteredMedications = filteredMedications.where((med) {
          if (med.latitude == null || med.longitude == null) return false;

          // Calculate distance using Haversine formula
          final distance = _calculateDistance(
              currentLat, currentLng,
              med.latitude!, med.longitude!
          );

          return distance <= radius;
        }).toList();
      }

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'createdAtDesc':
            filteredMedications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case 'createdAtAsc':
            filteredMedications.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            break;
          case 'expiryDateAsc':
            filteredMedications.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
            break;
          case 'expiryDateDesc':
            filteredMedications.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
            break;
          case 'distance':
            if (_currentLocation != null) {
              final currentLat = _currentLocation!.latitude ?? 0.0;
              final currentLng = _currentLocation!.longitude ?? 0.0;

              filteredMedications.sort((a, b) {
                double distA = double.infinity;
                double distB = double.infinity;

                if (a.latitude != null && a.longitude != null) {
                  distA = _calculateDistance(currentLat, currentLng, a.latitude!, a.longitude!);
                }

                if (b.latitude != null && b.longitude != null) {
                  distB = _calculateDistance(currentLat, currentLng, b.latitude!, b.longitude!);
                }

                return distA.compareTo(distB);
              });
            }
            break;
        }
      }

      // Update the list
      _availableMedications.clear();
      _availableMedications.addAll(filteredMedications);

      // Ensure no expired medications are shown if nonExpiredOnly is true
      if (nonExpiredOnly) {
        final now = DateTime.now();
        _availableMedications.removeWhere((med) => med.expiryDate.isBefore(now));
      }

      // Sort medications by status (available first)
      _availableMedications.sort((a, b) {
        if (a.status == 'available' && b.status != 'available') return -1;
        if (a.status != 'available' && b.status == 'available') return 1;
        return 0;
      });

      // Save to secure storage
      await _secureStorage.write(
        key: 'available_medications',
        value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      _errorMessage = 'Error fetching medications: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch donations made by the current user
  Future<void> fetchMyDonations(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real app, this would call an API
      // For this example, we'll simulate with mock data
      await Future.delayed(const Duration(seconds: 1));

      // If empty, populate with mock data
      if (_myDonations.isEmpty) {
        await _populateMockDonations();
      }

      // Save to secure storage
      await _secureStorage.write(
        key: 'donated_medications',
        value: jsonEncode(_myDonations.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      _errorMessage = 'Error fetching donations: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch requests made by the current user
  Future<void> fetchMyRequests(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real app, this would call an API
      // For this example, we'll simulate with mock data
      await Future.delayed(const Duration(seconds: 1));

      // If empty, populate with mock data
      if (_myRequests.isEmpty) {
        await _populateMockRequests();
      }

      // Save to secure storage
      await _secureStorage.write(
        key: 'requested_medications',
        value: jsonEncode(_myRequests.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      _errorMessage = 'Error fetching requests: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get details of a specific medication
  Future<MedicationModel> getMedicationDetails(String token, String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Search in all lists
      MedicationModel? medication = _availableMedications.firstWhere(
            (m) => m.id == medicationId,
        orElse: () => _myDonations.firstWhere(
              (m) => m.id == medicationId,
          orElse: () => _myRequests.firstWhere(
                (m) => m.id == medicationId,
            orElse: () {
              throw Exception('Medication not found');
            },
          ),
        ),
      );

      // In a real app, if not found locally, you would fetch from API
      return medication;
    } catch (e) {
      _errorMessage = 'Error getting medication details: $e';
      debugPrint(_errorMessage);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Donate a new medication
  Future<bool> donateMedication(
      String token, {
        required String name,
        required String type,
        required String dosage,
        required DateTime expiryDate,
        required int quantity,
        required String location,
        required String description,
        Point? selectedLocation,
        List<XFile>? images,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real app, you would upload images and send data to API
      // For this example, we'll create a local object

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Get appropriate image URLs for this medication
      List<String> imageUrls = _getMedicationImageUrls(name, type);

      // Use either the selected location point or current location
      double? latitude, longitude;
      if (selectedLocation != null) {
        latitude = selectedLocation.coordinates.lat as double?;
        longitude = selectedLocation.coordinates.lng as double?;
      } else if (_currentLocation != null) {
        latitude = _currentLocation!.latitude;
        longitude = _currentLocation!.longitude;
      }

      final now = DateTime.now();
      final newMedication = MedicationModel(
        id: 'med_${now.millisecondsSinceEpoch}',
        donorId: 'current_user_id', // In a real app, this would be the actual user ID
        donorName: 'Current User',   // In a real app, this would be the actual user name
        name: name,
        type: type,
        dosage: dosage,
        expiryDate: expiryDate,
        quantity: quantity,
        imageUrls: imageUrls, // Using real image URLs
        location: location,
        latitude: latitude,
        longitude: longitude,
        description: description,
        status: 'available',
        createdAt: now,
      );

      // Add to both available medications and my donations
      _availableMedications.add(newMedication);
      _myDonations.add(newMedication);

      // Save to secure storage
      await _secureStorage.write(
        key: 'available_medications',
        value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
      );
      await _secureStorage.write(
        key: 'donated_medications',
        value: jsonEncode(_myDonations.map((m) => m.toJson()).toList()),
      );

      return true;
    } catch (e) {
      _errorMessage = 'Error donating medication: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request a medication
  Future<bool> requestMedication(String token, String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the medication
      final medicationIndex = _availableMedications.indexWhere((m) => m.id == medicationId);
      if (medicationIndex == -1) {
        throw Exception('Medication not found');
      }

      // Check if it can be requested
      final medication = _availableMedications[medicationIndex];
      if (medication.status != 'available') {
        throw Exception('Medication is not available');
      }
      if (medication.isExpired) {
        throw Exception('Cannot request expired medication');
      }
      if (medication.quantity <= 0) {
        throw Exception('Medication is out of stock');
      }

      // Update the medication status
      final updatedMedication = medication.copyWith(
        status: 'reserved',
        recipientId: 'current_user_id', // In a real app, this would be the actual user ID
        recipientName: 'Current User',   // In a real app, this would be the actual user name
      );

      // Update in available medications list
      _availableMedications[medicationIndex] = updatedMedication;

      // Add to my requests
      _myRequests.add(updatedMedication);

      // Save to secure storage
      await _secureStorage.write(
        key: 'available_medications',
        value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
      );
      await _secureStorage.write(
        key: 'requested_medications',
        value: jsonEncode(_myRequests.map((m) => m.toJson()).toList()),
      );

      return true;
    } catch (e) {
      _errorMessage = 'Error requesting medication: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel a donation
  Future<bool> cancelDonation(String token, String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the medication in donations
      final donationIndex = _myDonations.indexWhere((m) => m.id == medicationId);
      if (donationIndex == -1) {
        throw Exception('Donation not found');
      }

      // Check if it can be canceled
      final donation = _myDonations[donationIndex];
      if (donation.status == 'completed') {
        throw Exception('Cannot cancel a completed donation');
      }

      // Remove from my donations
      _myDonations.removeAt(donationIndex);

      // Also remove from available medications if it exists there
      final availableIndex = _availableMedications.indexWhere((m) => m.id == medicationId);
      if (availableIndex != -1) {
        _availableMedications.removeAt(availableIndex);
      }

      // Save to secure storage
      await _secureStorage.write(
        key: 'donated_medications',
        value: jsonEncode(_myDonations.map((m) => m.toJson()).toList()),
      );
      await _secureStorage.write(
        key: 'available_medications',
        value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
      );

      return true;
    } catch (e) {
      _errorMessage = 'Error canceling donation: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel a request
  Future<bool> cancelRequest(String token, String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the medication in requests
      final requestIndex = _myRequests.indexWhere((m) => m.id == medicationId);
      if (requestIndex == -1) {
        throw Exception('Request not found');
      }

      // Get the request
      final request = _myRequests[requestIndex];
      if (request.status == 'completed') {
        throw Exception('Cannot cancel a completed request');
      }

      // Remove from my requests
      _myRequests.removeAt(requestIndex);

      // Update the status in available medications if it exists there
      final availableIndex = _availableMedications.indexWhere((m) => m.id == medicationId);
      if (availableIndex != -1) {
        final updatedMedication = _availableMedications[availableIndex].copyWith(
          status: 'available',
          recipientId: null,
          recipientName: null,
        );
        _availableMedications[availableIndex] = updatedMedication;
      }

      // Save to secure storage
      await _secureStorage.write(
        key: 'requested_medications',
        value: jsonEncode(_myRequests.map((m) => m.toJson()).toList()),
      );
      await _secureStorage.write(
        key: 'available_medications',
        value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
      );

      return true;
    } catch (e) {
      _errorMessage = 'Error canceling request: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete an exchange
  Future<bool> completeExchange(String token, String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the medication in both lists
      final donationIndex = _myDonations.indexWhere((m) => m.id == medicationId);
      final requestIndex = _myRequests.indexWhere((m) => m.id == medicationId);
      final availableIndex = _availableMedications.indexWhere((m) => m.id == medicationId);

      // Check if medication exists in either list
      if (donationIndex == -1 && requestIndex == -1) {
        throw Exception('Medication not found');
      }

      // Get the medication
      MedicationModel? medication;
      if (donationIndex != -1) {
        medication = _myDonations[donationIndex];
      } else if (requestIndex != -1) {
        medication = _myRequests[requestIndex];
      }

      if (medication == null) {
        throw Exception('Medication not found');
      }

      // Check if it can be completed
      if (medication.status != 'reserved') {
        throw Exception('Only reserved medications can be completed');
      }

      // Update the status
      final updatedMedication = medication.copyWith(
        status: 'completed',
      );

      // Update in respective lists
      if (donationIndex != -1) {
        _myDonations[donationIndex] = updatedMedication;
      }
      if (requestIndex != -1) {
        _myRequests[requestIndex] = updatedMedication;
      }
      if (availableIndex != -1) {
        _availableMedications.removeAt(availableIndex); // Remove from available
      }

      // Save to secure storage
      await _secureStorage.write(
        key: 'donated_medications',
        value: jsonEncode(_myDonations.map((m) => m.toJson()).toList()),
      );
      await _secureStorage.write(
        key: 'requested_medications',
        value: jsonEncode(_myRequests.map((m) => m.toJson()).toList()),
      );
      await _secureStorage.write(
        key: 'available_medications',
        value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
      );

      return true;
    } catch (e) {
      _errorMessage = 'Error completing exchange: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // MEDICATION RECOMMENDATION SYSTEM

  // Generate recommendations based on medication name and disease/category
  List<MedicationModel> getRecommendations(String medicationName, String category) {
    // First try to get recommendations by active ingredient
    final ingredientRecs = getRecommendationsByIngredient(medicationName);
    if (ingredientRecs.isNotEmpty) {
      return ingredientRecs;
    }

    // If no ingredient-based recommendations, try by disease/category
    return getRecommendationsByCategory(category);
  }

  // Get recommendations based on medication name (searching by active ingredient)
  List<MedicationModel> getRecommendationsByIngredient(String medicationName) {
    final List<MedicationModel> recommendations = [];

    // Extract potential active ingredient (first word as simple heuristic)
    final nameParts = medicationName.toLowerCase().split(' ');
    if (nameParts.isEmpty) return recommendations;

    final potentialIngredient = nameParts[0];

    // Find medications with similar active ingredient
    for (final med in _availableMedications) {
      if (med.name.toLowerCase().startsWith(potentialIngredient) &&
          med.name.toLowerCase() != medicationName.toLowerCase() &&
          med.status == 'available' &&
          !med.isExpired) {
        recommendations.add(med);
        if (recommendations.length >= 5) break; // Limit to 5 recommendations
      }
    }

    return recommendations;
  }


  // Get recommendations based on medication name only
  List<MedicationModel> getRecommendationsByName(String medicationName) {
    // Extract potential active ingredient (first word as simple heuristic)
    final List<MedicationModel> recommendations = [];

    // First try by ingredient
    recommendations.addAll(getRecommendationsByIngredient(medicationName));

    // If we have recommendations by ingredient, return them
    if (recommendations.isNotEmpty) {
      return recommendations;
    }

    // Otherwise, try to find medications with partial name match
    for (final med in _availableMedications) {
      if (med.name.toLowerCase().contains(medicationName.toLowerCase()) &&
          med.status == 'available' &&
          !med.isExpired) {
        recommendations.add(med);
        if (recommendations.length >= 5) break;
      }
    }

    // If still no recommendations, return some random available medications
    if (recommendations.isEmpty) {
      final availableMeds = _availableMedications
          .where((med) => med.status == 'available' && !med.isExpired)
          .toList();

      if (availableMeds.isNotEmpty) {
        // Sort by newest first
        availableMeds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        recommendations.addAll(availableMeds.take(5));
      }
    }

    return recommendations;
  }

  // Get recommendations based on medication category/disease
  List<MedicationModel> getRecommendationsByCategory(String category) {
    final List<MedicationModel> recommendations = [];

    // Find available medications in the same category
    for (final med in _availableMedications) {
      if (med.type.toLowerCase() == category.toLowerCase() &&
          med.status == 'available' &&
          !med.isExpired) {
        recommendations.add(med);
        if (recommendations.length >= 5) break;
      }
    }

    return recommendations;
  }

  // Helper function to get mapping of medication names to image URLs
  Map<String, List<String>> _getMedicationImagesMap() {
    return {
      // Blood Pressure Medications
      'Lisinopril': [
        'https://www.healthsoul.com/wp-content/uploads/2021/11/Lisinopril.jpg',
        'https://medicaladvise.com/wp-content/uploads/2019/08/Lisinopril.jpg'
      ],
      'Amlodipine': [
        'https://www.empr.com/wp-content/uploads/sites/7/2018/12/amlodipine_405011.jpg',
        'https://img.medscapestatic.com/pi/features/drugdirectory/octupdate/KRN04270.jpg'
      ],
      'Losartan': [
        'https://www.healthline.com/hlcmsresource/images/topic_centers/2018-10/766x415_HEADER_Losartan_Potassium.jpg',
        'https://cdn.mdedge.com/files/s3fs-public/Document/October-2016/031050091.jpg'
      ],
      'Metoprolol': [
        'https://www.singlecare.com/blog/wp-content/uploads/2020/02/metoprolol-1024x535.png',
        'https://img.medscapestatic.com/pi/features/drugdirectory/octupdate/MYL61550.jpg'
      ],
      'Hydrochlorothiazide': [
        'https://www.singlecare.com/blog/wp-content/uploads/2020/12/Hydrochlorothiazide_HCTZ.png',
        'https://www.drugs.com/images/pills/mtm/hydrochlorothiazide-25-mg-mylan.jpg'
      ],
      'Valsartan': [
        'https://img.medscapestatic.com/pi/features/drugdirectory/octupdate/TEV01420.jpg',
        'https://www.drugs.com/images/pills/fio/TEV01430.JPG'
      ],

      // Diabetes Medications
      'Metformin': [
        'https://www.medicalnewstoday.com/content/images/articles/323/323128/metformin-tablets.jpg',
        'https://post.medicalnewstoday.com/wp-content/uploads/sites/3/2020/06/GettyImages-1257429069_thumb-732x549.jpg'
      ],
      'Glimepiride': [
        'https://www.drugs.com/images/pills/nlm/006035423.jpg',
        'https://www.singlecare.com/blog/wp-content/uploads/2021/08/Glimepiride.png'
      ],
      'Insulin': [
        'https://media.istockphoto.com/id/1338398563/photo/insulin-pen-and-blood-glucose-meter.jpg?s=612x612&w=0&k=20&c=6_0SPlXMr-Nxal21iNVZ-Zks7CyWk4ZCYAb-4cj8nTk=',
        'https://cdn.pixabay.com/photo/2017/10/12/20/12/medicines-2845708_960_720.jpg'
      ],

      // Heart Medications
      'Aspirin': [
        'https://media.istockphoto.com/id/1300036753/photo/aspirin-pills-in-blister-pack-isolated-on-white.jpg?s=612x612&w=0&k=20&c=9MKRLjcVxhwVPLIvMjwKdYzV0V7ZjGxwYUZzDvXTCnE=',
        'https://media.istockphoto.com/id/171139552/photo/three-aspirin-tablets-on-white.jpg?s=612x612&w=0&k=20&c=NwX9jm-4Po4EF5Y2R-kfRbxCQXvZWxLMTwD9jCULMZ4='
      ],
      'Atorvastatin': [
        'https://img.medscapestatic.com/pi/features/drugdirectory/octupdate/PFR01670.jpg',
        'https://www.drugs.com/images/pills/fio/PFR01670.JPG'
      ],
      'Warfarin': [
        'https://www.singlecare.com/blog/wp-content/uploads/2019/10/blog-warfarin-e1678120780851.png',
        'https://www.drugs.com/images/pills/fio/BAR02550.JPG'
      ],

      // Pain Relief Medications
      'Paracetamol': [
        'https://media.istockphoto.com/id/1334511308/photo/paracetamol-tablets-and-box-on-the-table-paracetamol-is-a-medicine-used-to-treat-fever-and.jpg?s=612x612&w=0&k=20&c=VJqOfdllhNhBZ7kNprhHF9mjOidhV56jNNNyvKFfT14=',
        'https://media.istockphoto.com/id/1211644583/photo/paracetamol-pills-on-white-background.jpg?s=612x612&w=0&k=20&c=svENDmB3MmzlSPIZyubT-xNhfYaWPYWozCPlnjlJUKI='
      ],
      'Ibuprofen': [
        'https://media.istockphoto.com/id/1414400143/photo/new-full-dose-ibuprofen-pack-brown-pain-relief-capsule-pills-and-tablets-on-white-background.jpg?s=612x612&w=0&k=20&c=nf-EXlTwGQfIh2SzA_DY6P4Q2m0b9Kl-k7ofQPEWP2o=',
        'https://media.istockphoto.com/id/1386446438/photo/ibuprofen-painkiller-tablets-pills-medicine-health-care-medical-tablet.jpg?s=612x612&w=0&k=20&c=n2MQY2y5MXqXsXgYh2a9l7EtHk2v9naxLq7YMy0aeOY='
      ],
      'Naproxen': [
        'https://media.istockphoto.com/id/1340253472/photo/naproxen-tablets-laid-out-on-the-table-naproxen-is-an-anti-inflammatory-drug-nsaid-to-treat.jpg?s=612x612&w=0&k=20&c=7Z9ooNOAyUZWyJ_0kMVz5r3nJKqfXXWHbDmLyfWmwts=',
        'https://www.singlecare.com/blog/wp-content/uploads/2020/12/Naproxen.png'
      ],
      'Diclofenac': [
        'https://blink-health.imgix.net/images/1609939200000_Diclofenac_Sodium_DR_75_mg_tablet.png?w=1120&h=1120&auto=format',
        'https://img.medscapestatic.com/pi/features/drugdirectory/octupdate/TCV05920.jpg'
      ],

      // Antibiotics
      'Amoxicillin': [
        'https://media.istockphoto.com/id/1402252995/photo/amoxicillin-capsules-antibiotics-drug-pills-in-blister-packaging-on-white-background.jpg?s=612x612&w=0&k=20&c=9EyGLg4NEE0p2Lp2IpqC2TPpLXRKk9YeNrxKhH8Cx4g=',
        'https://media.istockphoto.com/id/1320141266/photo/amoxicillin-antibiotics-capsule-pills-in-blister-pack-with-box-package.jpg?s=612x612&w=0&k=20&c=RvvB8cxGQ43qIOVbVRYDQ47e9NZ34-dOQXO-NXe2OCk='
      ],
      'Azithromycin': [
        'https://media.istockphoto.com/id/1217589225/photo/packaged-azithromycin-tablet-on-white-background.jpg?s=612x612&w=0&k=20&c=bCdcTpYmWqRcftRJcJK6GYqkWWcJaNmwjYeLdmOD2KQ=',
        'https://img.medscapestatic.com/pi/features/drugdirectory/octupdate/ROR01190.jpg'
      ],
      'Ciprofloxacin': [
        'https://www.singlecare.com/blog/wp-content/uploads/2021/03/Ciprofloxacin.png',
        'https://www.empr.com/wp-content/uploads/sites/7/2018/12/cipro_405042.jpg'
      ],
      'Doxycycline': [
        'https://img.medscapestatic.com/pi/features/drugdirectory/octupdate/WTS01110.jpg',
        'https://www.singlecare.com/blog/wp-content/uploads/2020/12/Doxycycline.png'
      ],

      // Default/Generic
      'default': [
        'https://media.istockphoto.com/id/865061578/photo/medicine-pills-or-capsules-in-containers-on-white-background.jpg?s=612x612&w=0&k=20&c=tGG4qJfCZyYKMFbRvnAcsF11F6ZKz-9u35ojBCFkVww=',
        'https://media.istockphoto.com/id/1293982070/photo/various-pharmaceuticals-and-medicines.jpg?s=612x612&w=0&k=20&c=bDGgxFHZwBYw92TPDzYheRaypVVJTlXGGUZT3DFz16U='
      ]
    };
  }

  // Function to get image URLs for a specific medication
  List<String> _getMedicationImageUrls(String medicationName, String category) {
    final imageMap = _getMedicationImagesMap();

    // Try to find images specific to the medication name
    if (imageMap.containsKey(medicationName)) {
      return imageMap[medicationName]!;
    }

    // If not found, try to find images for similar medications
    final lowerName = medicationName.toLowerCase();

    for (final name in imageMap.keys) {
      if (lowerName.contains(name.toLowerCase()) || name.toLowerCase().contains(lowerName)) {
        return imageMap[name]!;
      }
    }

    // If still not found, return category-based generic images
    switch (category) {
      case 'Blood Pressure':
        return imageMap['Lisinopril']!;
      case 'Diabetes':
        return imageMap['Metformin']!;
      case 'Heart':
        return imageMap['Atorvastatin']!;
      case 'Pain Relief':
        return imageMap['Paracetamol']!;
      case 'Antibiotics':
        return imageMap['Amoxicillin']!;
      default:
        return imageMap['default']!;
    }
  }

  // Populate mock data for available medications
  Future<void> _populateMockData() async {
    // Get data from our CSV database
    final List<MedicationModel> mockMedications = [];
    final now = DateTime.now();

    // Categories from AppConstants
    final categories = AppConstants.medicationCategories;

    // Create 10 medications for each category
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];

      // Create medications with relevant names based on category
      for (int j = 0; j < 10; j++) {
        // Generate medication name based on category
        String medName = '';
        String dosage = '';

        switch (category) {
          case 'Blood Pressure':
            final bpMeds = ['Lisinopril', 'Amlodipine', 'Losartan', 'Metoprolol', 'Hydrochlorothiazide',
              'Valsartan', 'Propranolol', 'Atenolol', 'Diltiazem', 'Nifedipine'];
            final doses = ['5mg', '10mg', '25mg', '50mg', '100mg'];
            medName = bpMeds[j % bpMeds.length];
            dosage = doses[j % doses.length];
            break;

          case 'Diabetes':
            final diabetesMeds = ['Metformin', 'Glimepiride', 'Sitagliptin', 'Insulin Glargine', 'Empagliflozin',
              'Liraglutide', 'Glyburide', 'Pioglitazone', 'Exenatide', 'Dulaglutide'];
            final doses = ['500mg', '850mg', '1000mg', '50 units/ml', '25mg'];
            medName = diabetesMeds[j % diabetesMeds.length];
            dosage = doses[j % doses.length];
            break;

          case 'Heart':
            final heartMeds = ['Atorvastatin', 'Aspirin', 'Clopidogrel', 'Warfarin', 'Digoxin',
              'Furosemide', 'Spironolactone', 'Carvedilol', 'Amiodarone', 'Isosorbide'];
            final doses = ['10mg', '20mg', '40mg', '75mg', '81mg', '5mg'];
            medName = heartMeds[j % heartMeds.length];
            dosage = doses[j % doses.length];
            break;

          case 'Pain Relief':
            final painMeds = ['Paracetamol', 'Ibuprofen', 'Naproxen', 'Diclofenac', 'Celecoxib',
              'Tramadol', 'Gabapentin', 'Pregabalin', 'Meloxicam', 'Acetaminophen'];
            final doses = ['500mg', '400mg', '600mg', '250mg', '75mg', '100mg'];
            medName = painMeds[j % painMeds.length];
            dosage = doses[j % doses.length];
            break;

          case 'Antibiotics':
            final antibiotics = ['Amoxicillin', 'Azithromycin', 'Ciprofloxacin', 'Doxycycline', 'Cephalexin',
              'Metronidazole', 'Clindamycin', 'Trimethoprim', 'Clarithromycin', 'Ceftriaxone'];
            final doses = ['250mg', '500mg', '875mg', '100mg', '200mg'];
            medName = antibiotics[j % antibiotics.length];
            dosage = doses[j % doses.length];
            break;

          default:
            final otherMeds = ['Vitamin D', 'Omeprazole', 'Loratadine', 'Fluticasone', 'Levothyroxine',
              'Albuterol', 'Montelukast', 'Ranitidine', 'Cetirizine', 'Fluoxetine'];
            final doses = ['10mg', '20mg', '50mcg', '100mcg', '10mcg', '5mg'];
            medName = otherMeds[j % otherMeds.length];
            dosage = doses[j % doses.length];
            break;
        }

        // Random expiry date (0-3 years in the future)
        final expiryDate = DateTime(
          now.year + (j % 3),
          ((now.month + j) % 12) + 1,
          (now.day + j) % 28 + 1,
        );

        // Random creation date (0-6 months in the past)
        final creationDate = DateTime(
          now.year,
          ((now.month - (j % 6) - 1) % 12) + 1,
          (now.day - j) % 28 + 1,
        );

        // Random status (80% available, 10% reserved, 10% completed)
        String status;
        String? recipientId;
        String? recipientName;

        final random = j % 10;
        if (random < 8) {
          status = 'available';
          recipientId = null;
          recipientName = null;
        } else if (random < 9) {
          status = 'reserved';
          recipientId = 'user_recipient_${j}';
          recipientName = 'Recipient User ${j}';
        } else {
          status = 'completed';
          recipientId = 'user_recipient_${j}';
          recipientName = 'Recipient User ${j}';
        }

        // Generate random location for Mapbox
        final List<String> cities = ['Cairo', 'Alexandria', 'Giza', 'Aswan', 'Luxor'];
        final city = cities[j % cities.length];

        // Base coordinates - approximate center points for Egyptian cities
        Map<String, List<double>> cityCoordinates = {
          'Cairo': [31.2357, 30.0444],      // Cairo
          'Alexandria': [29.9187, 31.2001], // Alexandria
          'Giza': [31.1348, 29.9767],       // Giza
          'Aswan': [32.8995, 24.0889],      // Aswan
          'Luxor': [32.6396, 25.6872],      // Luxor
        };

        // Add some randomness to the coordinates to spread medications around the city
        final baseCoords = cityCoordinates[city] ?? [31.2357, 30.0444]; // Default to Cairo if not found
        final longitude = baseCoords[0] + ((j * 3) % 10) * 0.01;  // Spread within ~1km
        final latitude = baseCoords[1] + ((j * 7) % 10) * 0.01;   // Spread within ~1km

        // Get appropriate image URLs for this medication
        List<String> imageUrls = _getMedicationImageUrls(medName, category);

        // Create the medication model
        final medication = MedicationModel(
          id: 'med_${category.substring(0, 3).toLowerCase()}_${j}',
          donorId: 'user_donor_${j}',
          donorName: 'Donor User ${j}',
          recipientId: recipientId,
          recipientName: recipientName,
          name: medName,
          type: category,
          dosage: dosage,
          expiryDate: expiryDate,
          quantity: (j + 1) * 5, // 5, 10, 15, etc.
          imageUrls: imageUrls,
          location: city,
          latitude: latitude,
          longitude: longitude,
          description: 'This is ${medName} ${dosage} for ${category.toLowerCase()} treatment.',
          status: status,
          createdAt: creationDate,
        );

        mockMedications.add(medication);
      }
    }

    // Add to available medications list
    _availableMedications.clear();
    _availableMedications.addAll(mockMedications.where((med) => med.status == 'available'));

    // Save to secure storage
    await _secureStorage.write(
      key: 'available_medications',
      value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
    );
  }

  // Populate mock data for user's donations
  Future<void> _populateMockDonations() async {
    // Create some mock donations by the current user
    final List<MedicationModel> mockDonations = [];
    final now = DateTime.now();

    // Create 10 random donations
    for (int i = 0; i < 10; i++) {
      final categories = AppConstants.medicationCategories;
      final category = categories[i % categories.length];

      // Generate medication name based on category
      String medName = '';
      String dosage = '';

      switch (category) {
        case 'Blood Pressure':
          medName = ['Lisinopril', 'Amlodipine', 'Losartan'][i % 3];
          dosage = ['5mg', '10mg', '25mg'][i % 3];
          break;
        case 'Diabetes':
          medName = ['Metformin', 'Glimepiride', 'Insulin'][i % 3];
          dosage = ['500mg', '850mg', '1000mg'][i % 3];
          break;
        default:
          medName = 'Medication ${i+1}';
          dosage = '${(i+1) * 10}mg';
          break;
      }

      // Random expiry date
      final expiryDate = DateTime(
        now.year + (i % 3),
        ((now.month + i) % 12) + 1,
        (now.day + i) % 28 + 1,
      );

      // Random creation date
      final creationDate = DateTime(
        now.year,
        ((now.month - (i % 3) - 1) % 12) + 1,
        (now.day - i) % 28 + 1,
      );

      // Random status (50% available, 30% reserved, 20% completed)
      String status;
      String? recipientId;
      String? recipientName;

      final random = i % 10;
      if (random < 5) {
        status = 'available';
        recipientId = null;
        recipientName = null;
      } else if (random < 8) {
        status = 'reserved';
        recipientId = 'user_recipient_${i}';
        recipientName = 'Recipient User ${i}';
      } else {
        status = 'completed';
        recipientId = 'user_recipient_${i}';
        recipientName = 'Recipient User ${i}';
      }

      // Default user location - Cairo
      final latitude = 30.0444 + (i * 0.005);   // Small spread around Cairo
      final longitude = 31.2357 + (i * 0.005);  // Small spread around Cairo

      // Get appropriate image URLs for this medication
      List<String> imageUrls = _getMedicationImageUrls(medName, category);

      // Create the medication model
      final medication = MedicationModel(
        id: 'mydon_${i}',
        donorId: 'current_user_id', // Current user as donor
        donorName: 'Current User',
        recipientId: recipientId,
        recipientName: recipientName,
        name: medName,
        type: category,
        dosage: dosage,
        expiryDate: expiryDate,
        quantity: (i + 1) * 5,
        imageUrls: imageUrls,
        location: 'Cairo',
        latitude: latitude,
        longitude: longitude,
        description: 'This is my donated ${medName} ${dosage} for ${category.toLowerCase()} treatment.',
        status: status,
        createdAt: creationDate,
      );

      mockDonations.add(medication);
    }

    // Add to my donations list
    _myDonations.clear();
    _myDonations.addAll(mockDonations);

    // Save to secure storage
    await _secureStorage.write(
      key: 'donated_medications',
      value: jsonEncode(_myDonations.map((m) => m.toJson()).toList()),
    );
  }

  // Populate mock data for user's requests
  Future<void> _populateMockRequests() async {
    // Create some mock requests by the current user
    final List<MedicationModel> mockRequests = [];
    final now = DateTime.now();

    // Create 8 random requests
    for (int i = 0; i < 8; i++) {
      final categories = AppConstants.medicationCategories;
      final category = categories[i % categories.length];

      // Generate medication name based on category
      String medName = '';
      String dosage = '';

      switch (category) {
        case 'Blood Pressure':
          medName = ['Valsartan', 'Propranolol', 'Atenolol'][i % 3];
          dosage = ['80mg', '40mg', '50mg'][i % 3];
          break;
        case 'Diabetes':
          medName = ['Sitagliptin', 'Empagliflozin', 'Liraglutide'][i % 3];
          dosage = ['50mg', '25mg', '6mg/ml'][i % 3];
          break;
        default:
          medName = 'Requested Med ${i+1}';
          dosage = '${(i+1) * 5}mg';
          break;
      }

      // Random expiry date
      final expiryDate = DateTime(
        now.year + (i % 3),
        ((now.month + i) % 12) + 1,
        (now.day + i) % 28 + 1,
      );

      // Random creation date
      final creationDate = DateTime(
        now.year,
        ((now.month - (i % 3) - 1) % 12) + 1,
        (now.day - i) % 28 + 1,
      );

      // Random status (70% reserved, 30% completed)
      String status = (i % 10) < 7 ? 'reserved' : 'completed';

      // Generate random location for donor
      final List<String> cities = ['Cairo', 'Alexandria', 'Giza', 'Aswan', 'Luxor'];
      final city = cities[i % cities.length];

      // Base coordinates for cities
      Map<String, List<double>> cityCoordinates = {
        'Cairo': [31.2357, 30.0444],
        'Alexandria': [29.9187, 31.2001],
        'Giza': [31.1348, 29.9767],
        'Aswan': [32.8995, 24.0889],
        'Luxor': [32.6396, 25.6872],
      };

      final baseCoords = cityCoordinates[city] ?? [31.2357, 30.0444];
      final longitude = baseCoords[0] + ((i * 5) % 10) * 0.01;
      final latitude = baseCoords[1] + ((i * 3) % 10) * 0.01;

      // Get appropriate image URLs for this medication
      List<String> imageUrls = _getMedicationImageUrls(medName, category);

      // Create the medication model
      final medication = MedicationModel(
        id: 'myreq_${i}',
        donorId: 'user_donor_${i}',
        donorName: 'Donor User ${i}',
        recipientId: 'current_user_id', // Current user as recipient
        recipientName: 'Current User',
        name: medName,
        type: category,
        dosage: dosage,
        expiryDate: expiryDate,
        quantity: (i + 1) * 3,
        imageUrls: imageUrls,
        location: city,
        latitude: latitude,
        longitude: longitude,
        description: 'This is ${medName} ${dosage} for ${category.toLowerCase()} treatment that I requested.',
        status: status,
        createdAt: creationDate,
      );

      mockRequests.add(medication);
    }

    // Add to my requests list
    _myRequests.clear();
    _myRequests.addAll(mockRequests);

    // Save to secure storage
    await _secureStorage.write(
      key: 'requested_medications',
      value: jsonEncode(_myRequests.map((m) => m.toJson()).toList()),
    );
  }
}

// Extension to add toRadians method to double
extension MathExtensions on double {
  double toRadians() => this * (3.14159265359 / 180);

  double toDegrees() => this * (180 / 3.14159265359);
}