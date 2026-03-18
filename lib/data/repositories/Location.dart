import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart' as loc; // Alias to avoid conflict
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/AppConstants.dart';
import '../model/MedicationModel.dart';

// Custom Location class to match MedicationMapScreen and MapboxLocationPicker
class GeoLocation {
  final double? latitude;
  final double? longitude;

  GeoLocation({this.latitude, this.longitude});
}

class MedicationService extends ChangeNotifier {
  final List<MedicationModel> _availableMedications = [];
  final List<MedicationModel> _myDonations = [];
  final List<MedicationModel> _myRequests = [];
  final List<MedicationModel> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final loc.Location _location = loc.Location(); // Use location package
  GeoLocation? _currentLocation;
  Point? _mapboxPoint;

  // Getters
  List<MedicationModel> get availableMedications => List.unmodifiable(_availableMedications);
  List<MedicationModel> get myDonations => List.unmodifiable(_myDonations);
  List<MedicationModel> get myRequests => List.unmodifiable(_myRequests);
  List<MedicationModel> get recommendations => List.unmodifiable(_recommendations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GeoLocation? get currentLocation => _currentLocation;
  Point? get mapboxPoint => _mapboxPoint;

  // Initialize the service
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

  // Initialize location service
  Future<void> initLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          debugPrint('Location service not enabled');
          return;
        }
      }

      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          debugPrint('Location permission not granted');
          return;
        }
      }

      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        _currentLocation = GeoLocation(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
        );
        _mapboxPoint = Point(
          coordinates: Position(
            locationData.longitude!,
            locationData.latitude!,
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  // Update location with a Mapbox point
  void updateLocationWithMapboxPoint(Point point) {
    _mapboxPoint = point;
    final coords = point.coordinates;
    _currentLocation = GeoLocation(
      latitude: coords.lat.toDouble(), // Convert num to double
      longitude: coords.lng.toDouble(), // Convert num to double
    );
    notifyListeners();
  }

  // Get nearby medications
  List<MedicationModel> getNearbyMedications({double radiusInKm = 5.0}) {
    if (_currentLocation == null || _currentLocation!.latitude == null || _currentLocation!.longitude == null) {
      return [];
    }

    final currentLat = _currentLocation!.latitude!;
    final currentLng = _currentLocation!.longitude!;

    return _availableMedications.where((med) {
      if (med.latitude == null || med.longitude == null) return false;

      final distance = _calculateDistance(
        currentLat,
        currentLng,
        med.latitude!,
        med.longitude!,
      );

      return distance <= radiusInKm;
    }).toList();
  }

  // Calculate distance using Haversine formula
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

  // Load medications from secure storage
  Future<void> _loadMedications() async {
    try {
      // Load available medications
      final storedAvailable = await _secureStorage.read(key: 'available_medications');
      if (storedAvailable != null) {
        final data = jsonDecode(storedAvailable);
        if (data is List) {
          _availableMedications.clear();
          _availableMedications.addAll(data.map((item) => MedicationModel.fromJson(item)));
        }
      }

      // Load donated medications
      final storedDonated = await _secureStorage.read(key: 'donated_medications');
      if (storedDonated != null) {
        final data = jsonDecode(storedDonated);
        if (data is List) {
          _myDonations.clear();
          _myDonations.addAll(data.map((item) => MedicationModel.fromJson(item)));
        }
      }

      // Load requested medications
      final storedRequested = await _secureStorage.read(key: 'requested_medications');
      if (storedRequested != null) {
        final data = jsonDecode(storedRequested);
        if (data is List) {
          _myRequests.clear();
          _myRequests.addAll(data.map((item) => MedicationModel.fromJson(item)));
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading medications: $e';
      debugPrint(_errorMessage);
    }
  }

  // Fetch available medications
  Future<void> fetchAvailableMedications({
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
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      if (_availableMedications.isEmpty) {
        await _populateMockData();
      }

      List<MedicationModel> filteredMedications = List.from(_availableMedications);

      // Filter by query
      if (query != null && query.isNotEmpty) {
        filteredMedications = filteredMedications
            .where((med) => med.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
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

      // Filter by location
      if (nearbyOnly && _currentLocation != null && _currentLocation!.latitude != null && radius != null) {
        filteredMedications = filteredMedications.where((med) {
          if (med.latitude == null || med.longitude == null) return false;
          final distance = _calculateDistance(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
            med.latitude!,
            med.longitude!,
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
            filteredMedications.sort((a, b) => b.expiryDate.compareTo(b.expiryDate));
            break;
          case 'distance':
            if (_currentLocation != null && _currentLocation!.latitude != null) {
              final currentLat = _currentLocation!.latitude!;
              final currentLng = _currentLocation!.longitude!;
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

      _availableMedications.clear();
      _availableMedications.addAll(filteredMedications);
      if (nonExpiredOnly) {
        final now = DateTime.now();
        _availableMedications.removeWhere((med) => med.expiryDate.isBefore(now));
      }

      _availableMedications.sort((a, b) {
        if (a.status == 'available' && b.status != 'available') return -1;
        if (a.status != 'available' && b.status == 'available') return 1;
        return 0;
      });

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

  // Fetch user donations
  Future<void> fetchMyDonations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      if (_myDonations.isEmpty) {
        await _populateMockDonations();
      }
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

  // Fetch user requests
  Future<void> fetchMyRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      if (_myRequests.isEmpty) {
        await _populateMockRequests();
      }
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

  // Get medication details
  Future<MedicationModel> getMedicationDetails(String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      MedicationModel? medication = _availableMedications.firstWhere(
            (m) => m.id == medicationId,
        orElse: () => _myDonations.firstWhere(
              (m) => m.id == medicationId,
          orElse: () => _myRequests.firstWhere(
                (m) => m.id == medicationId,
            orElse: () => throw Exception('Medication not found'),
          ),
        ),
      );
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

  // Donate a medication
  Future<bool> donateMedication({
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
      await Future.delayed(const Duration(seconds: 2));
      List<String> imageUrls = _getMedicationImageUrls(name, type);
      // TODO: Implement image upload logic for 'images' parameter
      double? latitude, longitude;
      if (selectedLocation != null) {
        latitude = selectedLocation.coordinates.lat.toDouble(); // Convert num to double
        longitude = selectedLocation.coordinates.lng.toDouble(); // Convert num to double
      } else if (_currentLocation != null && _currentLocation!.latitude != null) {
        latitude = _currentLocation!.latitude;
        longitude = _currentLocation!.longitude;
      }

      final now = DateTime.now();
      final newMedication = MedicationModel(
        id: 'med_${now.millisecondsSinceEpoch}',
        donorId: 'current_user_id',
        donorName: 'Current User',
        name: name,
        type: type,
        dosage: dosage,
        expiryDate: expiryDate,
        quantity: quantity,
        imageUrls: imageUrls,
        location: location,
        latitude: latitude,
        longitude: longitude,
        description: description,
        status: 'available',
        createdAt: now,
      );

      _availableMedications.add(newMedication);
      _myDonations.add(newMedication);

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
  Future<bool> requestMedication(String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final medicationIndex = _availableMedications.indexWhere((m) => m.id == medicationId);
      if (medicationIndex == -1) {
        throw Exception('Medication not found');
      }

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

      final updatedMedication = medication.copyWith(
        status: 'reserved',
        recipientId: 'current_user_id',
        recipientName: 'Current User',
      );

      _availableMedications[medicationIndex] = updatedMedication;
      _myRequests.add(updatedMedication);

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
  Future<bool> cancelDonation(String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final donationIndex = _myDonations.indexWhere((m) => m.id == medicationId);
      if (donationIndex == -1) {
        throw Exception('Donation not found');
      }

      final donation = _myDonations[donationIndex];
      if (donation.status == 'completed') {
        throw Exception('Cannot cancel a completed donation');
      }

      _myDonations.removeAt(donationIndex);
      final availableIndex = _availableMedications.indexWhere((m) => m.id == medicationId);
      if (availableIndex != -1) {
        _availableMedications.removeAt(availableIndex);
      }

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
  Future<bool> cancelRequest(String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final requestIndex = _myRequests.indexWhere((m) => m.id == medicationId);
      if (requestIndex == -1) {
        throw Exception('Request not found');
      }

      final request = _myRequests[requestIndex];
      if (request.status == 'completed') {
        throw Exception('Cannot cancel a completed request');
      }

      _myRequests.removeAt(requestIndex);
      final availableIndex = _availableMedications.indexWhere((m) => m.id == medicationId);
      if (availableIndex != -1) {
        final updatedMedication = _availableMedications[availableIndex].copyWith(
          status: 'available',
          recipientId: null,
          recipientName: null,
        );
        _availableMedications[availableIndex] = updatedMedication;
      }

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
  Future<bool> completeExchange(String medicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final donationIndex = _myDonations.indexWhere((m) => m.id == medicationId);
      final requestIndex = _myRequests.indexWhere((m) => m.id == medicationId);
      final availableIndex = _availableMedications.indexWhere((m) => m.id == medicationId);

      if (donationIndex == -1 && requestIndex == -1) {
        throw Exception('Medication not found');
      }

      MedicationModel? medication;
      if (donationIndex != -1) {
        medication = _myDonations[donationIndex];
      } else if (requestIndex != -1) {
        medication = _myRequests[requestIndex];
      }

      if (medication == null || medication.status != 'reserved') {
        throw Exception('Only reserved medications can be completed');
      }

      final updatedMedication = medication.copyWith(status: 'completed');

      if (donationIndex != -1) {
        _myDonations[donationIndex] = updatedMedication;
      }
      if (requestIndex != -1) {
        _myRequests[requestIndex] = updatedMedication;
      }
      if (availableIndex != -1) {
        _availableMedications.removeAt(availableIndex);
      }

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

  // Recommendation methods
  List<MedicationModel> getRecommendations(String medicationName, String category) {
    final ingredientRecs = getRecommendationsByIngredient(medicationName);
    if (ingredientRecs.isNotEmpty) {
      return ingredientRecs;
    }
    return getRecommendationsByCategory(category);
  }

  List<MedicationModel> getRecommendationsByIngredient(String medicationName) {
    final List<MedicationModel> recommendations = [];
    final nameParts = medicationName.toLowerCase().split(' ');
    if (nameParts.isEmpty) return recommendations;
    final potentialIngredient = nameParts[0];

    for (final med in _availableMedications) {
      if (med.name.toLowerCase().startsWith(potentialIngredient) &&
          med.name.toLowerCase() != medicationName.toLowerCase() &&
          med.status == 'available' &&
          !med.isExpired) {
        recommendations.add(med);
        if (recommendations.length >= 5) break;
      }
    }
    return recommendations;
  }

  List<MedicationModel> getRecommendationsByName(String medicationName) {
    final List<MedicationModel> recommendations = getRecommendationsByIngredient(medicationName);
    if (recommendations.isNotEmpty) {
      return recommendations;
    }

    for (final med in _availableMedications) {
      if (med.name.toLowerCase().contains(medicationName.toLowerCase()) &&
          med.status == 'available' &&
          !med.isExpired) {
        recommendations.add(med);
        if (recommendations.length >= 5) break;
      }
    }

    if (recommendations.isEmpty) {
      final availableMeds = _availableMedications
          .where((med) => med.status == 'available' && !med.isExpired)
          .toList();
      if (availableMeds.isNotEmpty) {
        availableMeds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        recommendations.addAll(availableMeds.take(5));
      }
    }
    return recommendations;
  }

  List<MedicationModel> getRecommendationsByCategory(String category) {
    final List<MedicationModel> recommendations = [];
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

  // Image handling
  Map<String, List<String>> _getMedicationImagesMap() {
    return {
      // Blood Pressure Medications
      'Lisinopril': [
        'https://via.placeholder.com/150',
        'https://via.placeholder.com/150',
      ],
      'Amlodipine': [
        'https://via.placeholder.com/150',
        'https://via.placeholder.com/150',
      ],
      // Add other medications with placeholder URLs
      'default': [
        'https://via.placeholder.com/150',
        'https://via.placeholder.com/150',
      ],
    };
  }

  List<String> _getMedicationImageUrls(String medicationName, String category) {
    final imageMap = _getMedicationImagesMap();
    if (imageMap.containsKey(medicationName)) {
      return imageMap[medicationName]!;
    }
    final lowerName = medicationName.toLowerCase();
    for (final name in imageMap.keys) {
      if (lowerName.contains(name.toLowerCase()) || name.toLowerCase().contains(lowerName)) {
        return imageMap[name]!;
      }
    }
    return imageMap['default']!;
  }

  // Mock data population
  Future<void> _populateMockData() async {
    final List<MedicationModel> mockMedications = [];
    final now = DateTime.now();
    final categories = AppConstants.medicationCategories;

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      for (int j = 0; j < 10; j++) {
        String medName = '';
        String dosage = '';
        switch (category) {
          case 'Blood Pressure':
            final bpMeds = [
              'Lisinopril',
              'Amlodipine',
              'Losartan',
              'Metoprolol',
              'Hydrochlorothiazide',
              'Valsartan',
              'Propranolol',
              'Atenolol',
              'Diltiazem',
              'Nifedipine'
            ];
            final doses = ['5mg', '10mg', '25mg', '50mg', '100mg'];
            medName = bpMeds[j % bpMeds.length];
            dosage = doses[j % doses.length];
            break;
          case 'Diabetes':
            final diabetesMeds = [
              'Metformin',
              'Glimepiride',
              'Sitagliptin',
              'Insulin Glargine',
              'Empagliflozin',
              'Liraglutide',
              'Glyburide',
              'Pioglitazone',
              'Exenatide',
              'Dulaglutide'
            ];
            final doses = ['500mg', '850mg', '1000mg', '50 units/ml', '25mg'];
            medName = diabetesMeds[j % diabetesMeds.length];
            dosage = doses[j % doses.length];
            break;
          case 'Heart':
            final heartMeds = [
              'Atorvastatin',
              'Aspirin',
              'Clopidogrel',
              'Warfarin',
              'Digoxin',
              'Furosemide',
              'Spironolactone',
              'Carvedilol',
              'Amiodarone',
              'Isosorbide'
            ];
            final doses = ['10mg', '20mg', '40mg', '75mg', '81mg', '5mg'];
            medName = heartMeds[j % heartMeds.length];
            dosage = doses[j % doses.length];
            break;
          case 'Pain Relief':
            final painMeds = [
              'Paracetamol',
              'Ibuprofen',
              'Naproxen',
              'Diclofenac',
              'Celecoxib',
              'Tramadol',
              'Gabapentin',
              'Pregabalin',
              'Meloxicam',
              'Acetaminophen'
            ];
            final doses = ['500mg', '400mg', '600mg', '250mg', '75mg', '100mg'];
            medName = painMeds[j % painMeds.length];
            dosage = doses[j % doses.length];
            break;
          case 'Antibiotics':
            final antibiotics = [
              'Amoxicillin',
              'Azithromycin',
              'Ciprofloxacin',
              'Doxycycline',
              'Cephalexin',
              'Metronidazole',
              'Clindamycin',
              'Trimethoprim',
              'Clarithromycin',
              'Ceftriaxone'
            ];
            final doses = ['250mg', '500mg', '875mg', '100mg', '200mg'];
            medName = antibiotics[j % antibiotics.length];
            dosage = doses[j % doses.length];
            break;
          default:
            final otherMeds = [
              'Vitamin D',
              'Omeprazole',
              'Loratadine',
              'Fluticasone',
              'Levothyroxine',
              'Albuterol',
              'Montelukast',
              'Ranitidine',
              'Cetirizine',
              'Fluoxetine'
            ];
            final doses = ['10mg', '20mg', '50mcg', '100mcg', '10mcg', '5mg'];
            medName = otherMeds[j % otherMeds.length];
            dosage = doses[j % doses.length];
            break;
        }

        final expiryDate = DateTime(
          now.year + (j % 3),
          ((now.month + j) % 12) + 1,
          (now.day + j) % 28 + 1,
        );

        final creationDate = DateTime(
          now.year,
          ((now.month - (j % 6) - 1) % 12) + 1,
          (now.day - j) % 28 + 1,
        );

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
          recipientId = 'user_recipient_$j';
          recipientName = 'Recipient User $j';
        } else {
          status = 'completed';
          recipientId = 'user_recipient_$j';
          recipientName = 'Recipient User $j';
        }

        final List<String> cities = ['Cairo', 'Alexandria', 'Giza', 'Aswan', 'Luxor'];
        final city = cities[j % cities.length];
        final Map<String, List<double>> cityCoordinates = {
          'Cairo': [31.2357, 30.0444],
          'Alexandria': [29.9187, 31.2001],
          'Giza': [31.1348, 29.9767],
          'Aswan': [32.8995, 24.0889],
          'Luxor': [32.6396, 25.6872],
        };
        final baseCoords = cityCoordinates[city] ?? [31.2357, 30.0444];
        final longitude = baseCoords[0] + ((j * 3) % 10) * 0.01;
        final latitude = baseCoords[1] + ((j * 7) % 10) * 0.01;

        final imageUrls = _getMedicationImageUrls(medName, category);
        final medication = MedicationModel(
          id: 'med_${category.substring(0, 3).toLowerCase()}_$j',
          donorId: 'user_donor_$j',
          donorName: 'Donor User $j',
          recipientId: recipientId,
          recipientName: recipientName,
          name: medName,
          type: category,
          dosage: dosage,
          expiryDate: expiryDate,
          quantity: (j + 1) * 5,
          imageUrls: imageUrls,
          location: city,
          latitude: latitude,
          longitude: longitude,
          description: 'This is $medName $dosage for ${category.toLowerCase()} treatment.',
          status: status,
          createdAt: creationDate,
        );

        mockMedications.add(medication);
      }
    }

    _availableMedications.clear();
    _availableMedications.addAll(mockMedications.where((med) => med.status == 'available'));
    await _secureStorage.write(
      key: 'available_medications',
      value: jsonEncode(_availableMedications.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _populateMockDonations() async {
    final List<MedicationModel> mockDonations = [];
    final now = DateTime.now();

    for (int i = 0; i < 10; i++) {
      final category = AppConstants.medicationCategories[i % AppConstants.medicationCategories.length];
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
          medName = 'Medication ${i + 1}';
          dosage = '${(i + 1) * 10}mg';
          break;
      }

      final expiryDate = DateTime(
        now.year + (i % 3),
        ((now.month + i) % 12) + 1,
        (now.day + i) % 28 + 1,
      );

      final creationDate = DateTime(
        now.year,
        ((now.month - (i % 3) - 1) % 12) + 1,
        (now.day - i) % 28 + 1,
      );

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
        recipientId = 'user_recipient_$i';
        recipientName = 'Recipient User $i';
      } else {
        status = 'completed';
        recipientId = 'user_recipient_$i';
        recipientName = 'Recipient User $i';
      }

      final latitude = 30.0444 + (i * 0.005);
      final longitude = 31.2357 + (i * 0.005);
      final imageUrls = _getMedicationImageUrls(medName, category);
      final medication = MedicationModel(
        id: 'mydon_$i',
        donorId: 'current_user_id',
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
        description: 'This is my donated $medName $dosage for ${category.toLowerCase()} treatment.',
        status: status,
        createdAt: creationDate,
      );

      mockDonations.add(medication);
    }

    _myDonations.clear();
    _myDonations.addAll(mockDonations);
    await _secureStorage.write(
      key: 'donated_medications',
      value: jsonEncode(_myDonations.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _populateMockRequests() async {
    final List<MedicationModel> mockRequests = [];
    final now = DateTime.now();

    for (int i = 0; i < 8; i++) {
      final category = AppConstants.medicationCategories[i % AppConstants.medicationCategories.length];
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
          medName = 'Requested Med ${i + 1}';
          dosage = '${(i + 1) * 5}mg';
          break;
      }

      final expiryDate = DateTime(
        now.year + (i % 3),
        ((now.month + i) % 12) + 1,
        (now.day + i) % 28 + 1,
      );

      final creationDate = DateTime(
        now.year,
        ((now.month - (i % 3) - 1) % 12) + 1,
        (now.day - i) % 28 + 1,
      );

      final status = (i % 10) < 7 ? 'reserved' : 'completed';
      final List<String> cities = ['Cairo', 'Alexandria', 'Giza', 'Aswan', 'Luxor'];
      final city = cities[i % cities.length];
      final Map<String, List<double>> cityCoordinates = {
        'Cairo': [31.2357, 30.0444],
        'Alexandria': [29.9187, 31.2001],
        'Giza': [31.1348, 29.9767],
        'Aswan': [32.8995, 24.0889],
        'Luxor': [32.6396, 25.6872],
      };
      final baseCoords = cityCoordinates[city] ?? [31.2357, 30.0444];
      final longitude = baseCoords[0] + ((i * 5) % 10) * 0.01;
      final latitude = baseCoords[1] + ((i * 3) % 10) * 0.01;

      final imageUrls = _getMedicationImageUrls(medName, category);
      final medication = MedicationModel(
        id: 'myreq_$i',
        donorId: 'user_donor_$i',
        donorName: 'Donor User $i',
        recipientId: 'current_user_id',
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
        description: 'This is $medName $dosage for ${category.toLowerCase()} treatment that I requested.',
        status: status,
        createdAt: creationDate,
      );

      mockRequests.add(medication);
    }

    _myRequests.clear();
    _myRequests.addAll(mockRequests);
    await _secureStorage.write(
      key: 'requested_medications',
      value: jsonEncode(_myRequests.map((m) => m.toJson()).toList()),
    );
  }
}