import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_call/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _firebaseAuth.currentUser;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);

    // Check if already logged in
    final user = _firebaseAuth.currentUser;

    if (user != null) {
      _setOnlineStatus(true);
    }
  }

  // ==========================================================
  // ONLINE / OFFLINE
  // ==========================================================

  Future<void> _setOnlineStatus(bool isOnline) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      debugPrint('❌ No logged-in Firebase user');
      return;
    }

    try {
      debugPrint(
        'Updating user ${user.uid} to '
        '${isOnline ? "ONLINE" : "OFFLINE"}',
      );

      await _firestore.collection('users').doc(user.uid).set(
        {
          'isOnline': isOnline,
          'status': isOnline ? 'Online' : 'Offline',
        },
        SetOptions(merge: true),
      );

      debugPrint('✅ Online status updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to update online status: $e');
    }
  }

  // ==========================================================
  // APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state: $state');

    if (_firebaseAuth.currentUser == null) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _setOnlineStatus(false);
    }
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<bool> login(
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(
        email.trim(),
        password,
      );

      // IMPORTANT
      await _setOnlineStatus(true);

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? e.code;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // REGISTER
  // ==========================================================

  Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        name.trim(),
        email.trim(),
        password,
        phone.trim(),
      );

      // IMPORTANT
      await _setOnlineStatus(true);

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? e.code;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    // Mark offline before logout
    await _setOnlineStatus(false);

    await _authService.logout();

    notifyListeners();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}