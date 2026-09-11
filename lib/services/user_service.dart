import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_call/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Get all users
  Stream<List<UserModel>> getUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.uid != currentUserId)
          .toList();
    });
  }

  // Get one user
  Future<UserModel?> getUser(String uid) async {
    final document =
        await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      return null;
    }

    return UserModel.fromFirestore(document);
  }

  // Update online/offline status
  Future<void> updateStatus(
    String uid,
    String status,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'status': status,
    });
  }

  // Update profile
  Future<void> updateProfile({
    required String uid,
    required String name,
    String? phone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
    });
  }
}