import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:pulse_exchange/core/theme/AppRoutes.dart';
import 'package:pulse_exchange/core/theme/AppTheme.dart';
import 'package:pulse_exchange/data/repositories/AuthService.dart';
import 'package:pulse_exchange/data/repositories/BPService.dart';
import 'package:pulse_exchange/data/repositories/AIService.dart';
import 'package:pulse_exchange/data/repositories/chat_service.dart';
import 'package:pulse_exchange/data/repositories/MedicationService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Try to load environment variables, but don't fail if .env file is missing
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded successfully");
  } catch (e) {
    debugPrint("Warning: .env file not found or could not be loaded: $e");
    // Continue without environment variables - services should handle this gracefully
  }

  // Setup orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final authService = AuthService();
  final bpService = BPService();
  final aiService = AIService();
  final chatService = ChatService();
  final medicationService = MedicationService();

  // Initialize services that require async setup
  await Future.wait([
    authService.init(), // Required for loading stored user data
    bpService.init(),   // Initialize BP service
    medicationService.init(), // Initialize Medication service
  ]);

  // Initialize chat service after auth service
  await chatService.init();

  runApp(MyApp(
    authService: authService,
    bpService: bpService,
    aiService: aiService,
    chatService: chatService,
    medicationService: medicationService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final BPService bpService;
  final AIService aiService;
  final ChatService chatService;
  final MedicationService medicationService;

  const MyApp({
    Key? key,
    required this.authService,
    required this.bpService,
    required this.aiService,
    required this.chatService,
    required this.medicationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: bpService),
        ChangeNotifierProvider.value(value: aiService),
        ChangeNotifierProvider.value(value: chatService),
        ChangeNotifierProvider.value(value: medicationService),
        // Add Firebase Auth Stream Provider
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Pulse Exchange',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            initialRoute: _getInitialRoute(auth),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }

  String _getInitialRoute(AuthService auth) {
    // Check if user is authenticated with Firebase
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null || !auth.isAuthenticated) {
      return AppRoutes.splash; // Start with splash screen if not authenticated
    }

    // Since we have only patient users now, always navigate to patient home
    return AppRoutes.home;
  }
}