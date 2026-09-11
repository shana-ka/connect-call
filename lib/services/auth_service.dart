
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Normalize phone number
  String normalizePhone(String phone) {
    String normalized =
        phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Remove India country code
    if (normalized.startsWith('91') &&
        normalized.length == 12) {
      normalized = normalized.substring(2);
    }

    return normalized;
  }

  // Login
  Future<UserCredential> login(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register
  Future<UserCredential> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    // Normalize phone before saving
    final normalizedPhone = normalizePhone(phone);

    // Make sure phone has 10 digits
    if (normalizedPhone.length != 10) {
      throw Exception(
        'Please enter a valid 10-digit phone number.',
      );
    }

    // Create Firebase Authentication account
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User user = credential.user!;

    // Update Firebase Auth display name
    await user.updateDisplayName(name);

    // Save user details in Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'name': name,
      'email': email,
      'phone': normalizedPhone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Current user
  User? get currentUser => _auth.currentUser;
}

