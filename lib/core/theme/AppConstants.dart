import 'package:flutter/material.dart';

class AppConstants {
  // ===============================
  // App Information
  // ===============================
  static const String appName = 'BP Monitor & Med Exchange';
  static const String appVersion = '1.0.0';

  // ===============================
  // API Configuration
  // ===============================
  /// Base URL for API requests (update with production URL)
  static const String baseUrl = 'https://api.mediconnect.example.com'; // Updated placeholder
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String userEndpoint = '/user';
  static const String bpReadingsEndpoint = '/bp-readings';
  static const String chatEndpoint = '/chat';
  static const String medicationsEndpoint = '/medications';

  // ===============================
  // External API Keys
  // ===============================
  /// Use environment variables or .env file for security
  static const String openAIApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');

  // ===============================
  // Mapbox Settings
  // ===============================
  static const String mapboxStyle = 'mapbox://styles/mapbox/streets-v12';
  static const double defaultMapZoom = 12.0;
  static const double defaultSearchRadius = 5.0; // in kilometers
  static const int mapCameraAnimationMs = 1000;
  static const int mapMarkerAnimationMs = 500;

  // ===============================
  // Storage Keys
  // ===============================
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String userIdKey = 'user_id';
  static const String bpReadingsKey = 'bp_readings';
  static const String chatThreadsKey = 'chat_threads';
  static const String chatMessagesPrefix = 'chat_messages_';
  static const String deviceIdKey = 'device_id';
  static const String themePreferenceKey = 'theme_preference';
  static const String languagePreferenceKey = 'language_preference';
  static const String lastSyncTimeKey = 'last_sync_time';
  static const String lastKnownLocationKey = 'last_known_location';
  static const String availableMedicationsKey = 'available_medications';
  static const String donatedMedicationsKey = 'donated_medications';
  static const String requestedMedicationsKey = 'requested_medications';
  static const String userTypeKey = 'user_type';

  // ===============================
  // BP Status Ranges
  // ===============================
  static const Map<String, Map<String, int>> bpClassification = {
    'normal': {
      'systolicMax': 119,
      'diastolicMax': 79,
    },
    'elevated': {
      'systolicMin': 120,
      'systolicMax': 129,
      'diastolicMax': 79,
    },
    'hypertensionStage1': {
      'systolicMin': 130,
      'systolicMax': 139,
      'diastolicMin': 80,
      'diastolicMax': 89,
    },
    'hypertensionStage2': {
      'systolicMin': 140,
      'systolicMax': 180,
      'diastolicMin': 90,
      'diastolicMax': 120,
    },
    'hypertensiveCrisis': {
      'systolicMin': 181,
      'diastolicMin': 121,
    },
  };

  // ===============================
  // Medication Configuration
  // ===============================
  static const List<String> medicationCategories = [
    'Blood Pressure',
    'Diabetes',
    'Heart',
    'Pain Relief',
    'Antibiotics',
    'Allergy',
    'Respiratory',
    'Gastrointestinal',
    'Vitamins & Supplements',
    'Other',
  ];

  // ===============================
  // Chat Configuration
  // ===============================
  /// Valid message types for ChatMessage
  static const List<String> validMessageTypes = [
    'text',
    'image',
    'medication_request',
    'system',
  ];

  /// Polling interval for chat message updates (in seconds)
  static const int defaultPollingInterval = 5;

  // ===============================
  // Time Intervals
  // ===============================
  static const List<String> timeIntervals = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  // ===============================
  // Navigation Configuration
  // ===============================
  /// Bottom navigation pages
  static const List<String> bottomNavPages = [
    'Home',
    'BP Monitor',
    'Medicine',
    'Chat',
    'Profile',
  ];

  /// Bottom navigation icons (aligned with HomeScreen)
  static const List<IconData> bottomNavIcons = [
    Icons.home,
    Icons.favorite,
    Icons.medication,
    Icons.chat,
    Icons.person,
  ];

  /// App route names (aligned with AppRoutes)
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeBPMonitor = '/bp-monitor';
  static const String routeBPDashboard = '/bp-dashboard';
  static const String routeBPInput = '/bp-input';
  static const String routeBPHistory = '/bp-history';
  static const String routeMedDashboard = '/med-dashboard';
  static const String routeMedSearch = '/med-search';
  static const String routeMedDonate = '/med-donate';
  static const String routeMedRequest = '/med-request';
  static const String routeChat = '/chat';
  static const String routeChatAI = '/chat-ai';
  static const String routeProfile = '/profile';

  // ===============================
  // Default Settings
  // ===============================
  static const String defaultLanguage = 'en';
  static const String defaultTheme = 'system';
  static const int defaultSyncInterval = 15; // minutes

  // ===============================
  // Default Map Locations (Egypt)
  // ===============================
  static const Map<String, Map<String, double>> defaultLocations = {
    'Cairo': {'latitude': 30.0444, 'longitude': 31.2357},
    'Alexandria': {'latitude': 31.2001, 'longitude': 29.9187},
    'Giza': {'latitude': 29.9767, 'longitude': 31.1348},
    'Aswan': {'latitude': 24.0889, 'longitude': 32.8995},
    'Luxor': {'latitude': 25.6872, 'longitude': 32.6396},
  };

  // ===============================
  // Error Messages
  // ===============================
  static const String networkError = 'Network error. Please check your connection.';
  static const String authError = 'Authentication error. Please login again.';
  static const String unknownError = 'AnIndication error occurred. Please try again.';
  static const String bluetoothPermissionError =
      'Bluetooth and location permissions are required to scan for devices';
  static const String bluetoothNotAvailable = 'Bluetooth is not available on this device';
  static const String bluetoothNotEnabled = 'Please turn on Bluetooth and try again';
  static const String locationPermissionError =
      'Location permission is required to show medications near you';
  static const String locationServiceDisabled =
      'Location services are disabled. Please enable them to use this feature';
  static const String locationNotAvailable = 'Unable to determine your location. Please try again later';
  static const String noMedicationsFound = 'No medications found for the selected criteria';
  static const String medicationNotAvailable = 'This medication is no longer available';
  static const String chatGptApiError = 'Unable to reach ChatGPT API. Please try again later.';
  static const String chatGptTimeoutError = 'Request to ChatGPT timed out. Please try again.';

  // ===============================
  // Time Constants
  // ===============================
  static const int sessionTimeoutMinutes = 30;
  static const int autoRefreshSeconds = 60;

  // ===============================
  // Animation Durations
  // ===============================
  static const int shortAnimationDurationMs = 300;
  static const int mediumAnimationDurationMs = 500;
  static const int longAnimationDurationMs = 800;

  // ===============================
  // AI Chat Settings
  // ===============================
  static const String chatGptModel = 'gpt-3.5-turbo';
  static const double chatGptTemperature = 0.7;
  static const int chatGptMaxTokens = 500;
  static const String aiSystemPrompt =
      'You are a helpful health assistant specializing in blood pressure management, '
      'cardiovascular health, and medication exchange coordination. Provide accurate, '
      'concise information and personalized recommendations based on user health data '
      'when available. Assist with medication exchange logistics, such as coordinating '
      'pickup details, when relevant. Always be supportive, avoid causing unnecessary '
      'concern, and suggest consulting a healthcare professional when appropriate.';
}