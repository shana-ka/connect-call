import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String status;
  final String? profileImage;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.status = 'Offline',
    this.profileImage,
    this.isOnline = false,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return UserModel(
      uid: data['uid'] ?? document.id,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      phone: data['phone'],
      status: data['status'] ?? 'Offline',
      profileImage: data['profileImage'],
      isOnline: data['isOnline'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'profileImage': profileImage,
      'isOnline': isOnline,
    };
  }
}