import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pulse_exchange/core/theme/AppConstants.dart';
import 'package:pulse_exchange/data/models/UserModel.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _userType = ''; // 'patient' or 'doctor'

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get userType => _userType;

  // Initialize auth state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Listen to Firebase auth state changes
      _firebaseAuth.authStateChanges().listen((User? user) {
        if (user != null) {
          _loadUserFromFirebase(user);
        }
      });

      // Check if user is already logged in
      final User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _loadUserFromFirebase(firebaseUser);
      } else {
        // Check for existing token in secure storage (backward compatibility)
        final storedToken = await _secureStorage.read(key: AppConstants.authTokenKey);
        if (storedToken != null) {
          _token = storedToken;
          _isAuthenticated = true;

          // Load user data from storage
          final userDataJson = await _secureStorage.read(key: AppConstants.userDataKey);
          final userTypeStr = await _secureStorage.read(key: AppConstants.userTypeKey);

          if (userDataJson != null) {
            _currentUser = UserModel.fromJson(Map<String, dynamic>.from(jsonDecode(userDataJson)));
            _userType = userTypeStr ?? 'patient';
            debugPrint('AuthService: Initialized with stored user: ${_currentUser!.email} (${_userType})');
          }
        }
      }
    } catch (e) {
      debugPrint('AuthService: Error initializing auth: $e');
      _isAuthenticated = false;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserFromFirebase(User firebaseUser) async {
    try {
      _token = await firebaseUser.getIdToken();
      _isAuthenticated = true;

      // Load additional user data from secure storage
      final userDataJson = await _secureStorage.read(key: AppConstants.userDataKey);
      final userTypeStr = await _secureStorage.read(key: AppConstants.userTypeKey);

      if (userDataJson != null) {
        _currentUser = UserModel.fromJson(Map<String, dynamic>.from(jsonDecode(userDataJson)));
        _userType = userTypeStr ?? 'patient';
      } else {
        // Create new user model from Firebase data
        _currentUser = UserModel(
          userId: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          profileImageUrl: firebaseUser.photoURL,
          donatedMedications: [],
          requestedMedications: [],
        );
        _userType = 'patient'; // Default to patient

        // Save user data
        await _saveUserData();
      }
    } catch (e) {
      debugPrint('AuthService: Error loading user from Firebase: $e');
    }
  }

  Future<void> _saveUserData() async {
    if (_currentUser != null && _token != null) {
      await _secureStorage.write(key: AppConstants.authTokenKey, value: _token);
      await _secureStorage.write(
        key: AppConstants.userDataKey,
        value: jsonEncode(_currentUser!.toJson()),
      );
      await _secureStorage.write(key: AppConstants.userTypeKey, value: _userType);
    }
  }

  // Generic login function with user type support
  Future<bool> _loginWithType(String email, String password, String userType) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try Firebase authentication first
      final UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _token = await credential.user!.getIdToken();
        _userType = userType;
        _isAuthenticated = true;

        // Create or update user model
        _currentUser = UserModel(
          userId: credential.user!.uid,
          email: credential.user!.email ?? email,
          name: credential.user!.displayName ?? '',
          phone: credential.user!.phoneNumber ?? '',
          profileImageUrl: credential.user!.photoURL,
          donatedMedications: [],
          requestedMedications: [],
        );

        await _saveUserData();
        debugPrint('AuthService: Login successful for $email as $userType');
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Firebase auth error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Patient-specific login
  Future<bool> patientLogin(String email, String password) async {
    return await _loginWithType(email, password, 'patient');
  }

  // Doctor-specific login
  Future<bool> doctorLogin(String email, String password) async {
    return await _loginWithType(email, password, 'doctor');
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return false; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _token = await userCredential.user!.getIdToken();
        _userType = 'patient'; // Default to patient for social logins
        _isAuthenticated = true;

        _currentUser = UserModel(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? '',
          phone: userCredential.user!.phoneNumber ?? '',
          profileImageUrl: userCredential.user!.photoURL,
          donatedMedications: [],
          requestedMedications: [],
        );

        await _saveUserData();
        debugPrint('AuthService: Google sign-in successful');
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('AuthService: Google sign-in error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register patient
  Future<bool> registerPatient(
      String name,
      String email,
      String password,
      String phoneNumber
      ) async {
    return await _registerWithType(
      name,
      email,
      password,
      phoneNumber,
      'patient',
      null,
      null,
    );
  }

  // Register doctor
  Future<bool> registerDoctor(
      String name,
      String email,
      String password,
      String phoneNumber,
      String specialty,
      String licenseNumber
      ) async {
    return await _registerWithType(
      name,
      email,
      password,
      phoneNumber,
      'doctor',
      specialty,
      licenseNumber,
    );
  }

  // Generic register with user type
  Future<bool> _registerWithType(
      String name,
      String email,
      String password,
      String phoneNumber,
      String userType,
      String? specialty,
      String? licenseNumber
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create user with Firebase
      final UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update user profile
        await credential.user!.updateDisplayName(name);

        _token = await credential.user!.getIdToken();
        _userType = userType;
        _isAuthenticated = true;

        _currentUser = UserModel(
          userId: credential.user!.uid,
          email: email,
          name: name,
          phone: phoneNumber,
          donatedMedications: [],
          requestedMedications: [],
        );

        // Save additional doctor info if needed
        if (userType == 'doctor' && specialty != null && licenseNumber != null) {
          // You might want to store this in Firestore or another database
          await _secureStorage.write(key: 'doctor_specialty', value: specialty);
          await _secureStorage.write(key: 'doctor_license', value: licenseNumber);
        }

        await _saveUserData();
        debugPrint('AuthService: Registration successful for $email as $userType');
        notifyListeners();
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Firebase registration error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AuthService: Registration error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();

      await _secureStorage.delete(key: AppConstants.authTokenKey);
      await _secureStorage.delete(key: AppConstants.userDataKey);
      await _secureStorage.delete(key: AppConstants.userTypeKey);

      _token = null;
      _currentUser = null;
      _isAuthenticated = false;
      _userType = '';
      debugPrint('AuthService: Logout successful');
    } catch (e) {
      debugPrint('AuthService: Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint('AuthService: Password reset email sent for $email');
      return true;
    } catch (e) {
      debugPrint('AuthService: Reset password error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? location,
    String? profileImageUrl,
    String? profileImage,
    String? specialty,
    String? licenseNumber,
  }) async {
    if (_currentUser == null || _token == null) {
      debugPrint('AuthService: Cannot update profile - no user or token');
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Update Firebase user profile if name or photo changed
      final User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        if (name != null && name != firebaseUser.displayName) {
          await firebaseUser.updateDisplayName(name);
        }
        if (profileImageUrl != null && profileImageUrl != firebaseUser.photoURL) {
          await firebaseUser.updatePhotoURL(profileImageUrl);
        }
      }

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phoneNumber ?? _currentUser!.phone,
        location: location ?? _currentUser!.location,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
        updatedAt: DateTime.now(),
      );

      // Update specialty and license for doctors
      if (_userType == 'doctor') {
        if (specialty != null) {
          await _secureStorage.write(key: 'doctor_specialty', value: specialty);
        }
        if (licenseNumber != null) {
          await _secureStorage.write(key: 'doctor_license', value: licenseNumber);
        }
      }

      await _saveUserData();
      debugPrint('AuthService: Profile updated for ${_currentUser!.email}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthService: Update profile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user is a doctor
  bool isDoctor() {
    return _userType == 'doctor';
  }

  // Check if user is a patient
  bool isPatient() {
    return _userType == 'patient';
  }

  // Update doctor profile (maintaining backward compatibility)
  Future<bool> updateDoctorProfile({
    required String name,
    required String phone,
    required String specialty,
    required String bio,
    required String hospital,
    required String experience,
    File? profileImage,
  }) async {
    return await updateProfile(
      name: name,
      phoneNumber: phone,
      specialty: specialty,
      profileImage: profileImage?.path,
    );
  }

  // Check if email is verified (Firebase)
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint('AuthService: Email verification error: $e');
    }
  }
}