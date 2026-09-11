import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:connect_call/models/contact_model.dart';

class ContactProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  List<ContactModel> _contacts = [];

  List<ContactModel> get contacts => _contacts;

  // Add contact
  Future<void> addContact({
  required String userId,
  required String name,
  required String phoneNumber,
}) async {
  try {
    print('USER ID: $userId');
    print('NAME: $name');
    print('PHONE: $phoneNumber');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .add({
      'name': name.trim(),
      'phoneNumber': phoneNumber.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('CONTACT ADDED SUCCESSFULLY');

    await loadContacts(userId);
  } catch (e) {
    print('ADD CONTACT ERROR: $e');

    throw Exception(e.toString());
  }
}

  // Load contacts
  Future<void> loadContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .orderBy('name')
          .get();

      _contacts = snapshot.docs.map((doc) {
        return ContactModel.fromMap(
          doc.id,
          doc.data(),
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    }
  }

  // Search contacts
 List<ContactModel> searchContacts(String query) {
  if (query.isEmpty) {
    return _contacts;
  }

  final searchQuery = query.toLowerCase();

  return _contacts.where((contact) {
    return contact.name
            .toLowerCase()
            .contains(searchQuery) ||
        contact.phoneNumber.contains(searchQuery);
  }).toList();
}

  // Delete contact
  Future<void> deleteContact({
    required String userId,
    required String contactId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .delete();

    await loadContacts(userId);
  }
}