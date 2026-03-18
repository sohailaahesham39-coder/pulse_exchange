import 'package:flutter/material.dart';

// Import screens
import 'package:pulse_exchange/screens/auth/LoginScreen.dart';
import 'package:pulse_exchange/screens/auth/RegisterScreen.dart';
import 'package:pulse_exchange/screens/auth/forgot_password_screen.dart';
import 'package:pulse_exchange/screens/bp/BP dashboard screen.dart';
import 'package:pulse_exchange/screens/bp/BPInputScreen.dart';
import 'package:pulse_exchange/screens/bp/bp_connect_device_screen.dart';
import 'package:pulse_exchange/screens/bp/bp_history_screen.dart';
import 'package:pulse_exchange/screens/chat/user_chat_screen.dart';
import 'package:pulse_exchange/screens/chat/CombinedChatScreen.dart'; // Import the new combined chat screen
import 'package:pulse_exchange/screens/home/home.dart';
import 'package:pulse_exchange/screens/home/profile_screen.dart';
import 'package:pulse_exchange/screens/home/settings_screen.dart';
import 'package:pulse_exchange/screens/medicine/med_dashboard_screen.dart';
import 'package:pulse_exchange/screens/medicine/med_details_screen.dart';
import 'package:pulse_exchange/screens/medicine/med_donate_screen.dart';
import 'package:pulse_exchange/screens/medicine/med_request_screen.dart';
import 'package:pulse_exchange/screens/medicine/med_search_screen.dart';
import 'package:pulse_exchange/screens/onbording/OnboardingScreen.dart';
import 'package:pulse_exchange/screens/onbording/SplashScreen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String bpDashboard = '/bp-dashboard';
  static const String bpHistory = '/bp-history';
  static const String bpInput = '/bp-input';
  static const String bpConnectDevice = '/bp-connect-device';
  static const String medDashboard = '/med-dashboard';
  static const String medSearch = '/med-search';
  static const String medDonate = '/med-donate';
  static const String medRequest = '/med-request';
  static const String medDetails = '/med-details';

  // Existing chat routes
  static const String chatbot = '/chatbot';
  static const String userChat = '/user-chat';

  // New combined chat routes
  static const String chat = '/chat'; // Main combined chat screen
  static const String chatAI = '/chat/ai'; // Direct to AI assistant tab
  static const String chatUser = '/chat/user'; // Direct to user chat tab

  // Route generator
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    // Extract arguments if any
    final args = routeSettings.arguments as Map<String, dynamic>?;

    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case bpDashboard:
        return MaterialPageRoute(builder: (_) => const BPDashboardScreen());
      case bpHistory:
        return MaterialPageRoute(builder: (_) => const BPHistoryScreen());
      case bpInput:
        return MaterialPageRoute(builder: (_) => const BPInputScreen());
      case bpConnectDevice:
        return MaterialPageRoute(builder: (_) => const BPConnectDeviceScreen());
      case medDashboard:
        return MaterialPageRoute(builder: (_) => const MedDashboardScreen());
      case medSearch:
        return MaterialPageRoute(builder: (_) => const MedSearchScreen());
      case medDonate:
        return MaterialPageRoute(builder: (_) => const MedDonateScreen());
      case medRequest:
        return MaterialPageRoute(builder: (_) => const MedRequestScreen());
      case medDetails:
        final medicationId = args?['medicationId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => MedDetailsScreen(medicationId: medicationId),
        );

    // Original chat routes - kept for backward compatibility
      case chatbot:
        return MaterialPageRoute(
          builder: (_) => CombinedChatScreen(),
        );
      case userChat:
        final userId = args?['userId'] as String? ?? '';
        final userName = args?['userName'] as String? ?? '';
        final threadId = args?['threadId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => UserChatScreen(
            userId: userId,
            userName: userName,
            threadId: threadId,
          ),
        );

    // New combined chat routes
      case chat:
      // Main combined chat screen with no specific thread
        return MaterialPageRoute(builder: (_) => const CombinedChatScreen());
      case chatAI:
      // Navigate directly to AI chat tab (index 0)
        return MaterialPageRoute(
          builder: (_) => const CombinedChatScreen(initialTabIndex: 0),
        );
      case chatUser:
      // Navigate to user chat with specific thread (index 1)
        final userId = args?['userId'] as String?;
        final userName = args?['userName'] as String?;
        final threadId = args?['threadId'] as String?;
        return MaterialPageRoute(
          builder: (_) => CombinedChatScreen(
            initialTabIndex: 1,
            userId: userId,
            userName: userName,
            threadId: threadId,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
            ),
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}