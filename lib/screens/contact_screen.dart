import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_call/models/user_model.dart';
import 'package:connect_call/screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_call/providers/auth_provider.dart';
import 'package:connect_call/providers/contact_provider.dart';
import 'package:connect_call/screens/add_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;

      if (user != null) {
        context.read<ContactProvider>().loadContacts(user.uid);
      }
    });
  }

  Future<void> _startCall(String phoneNumber, String callType) async {
  try {
    final normalizedPhone = normalizePhone(phoneNumber);

    debugPrint('Original contact phone: $phoneNumber');
    debugPrint('Normalized phone: $normalizedPhone');

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This contact is not registered on Connect Call\n'
            'Number searched: $normalizedPhone',
          ),
        ),
      );

      return;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    debugPrint('Connect Call user found: ${doc.id}');
    debugPrint('User phone: ${data['phone']}');

    final user = UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      status: data['status'] ?? '',
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          user: user,
          callType: callType,
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to start call: $e'),
      ),
    );
  }
}
  String normalizePhone(String phone) {
  String normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');

  // Remove India's country code
  if (normalized.startsWith('91') && normalized.length == 12) {
    normalized = normalized.substring(2);
  }

  return normalized;
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();

    final contacts = contactProvider.searchContacts(_searchQuery);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: contacts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color.fromARGB(
                                255,
                                18,
                                108,
                                136,
                              ),
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            title: Text(
                              contact.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contact.phoneNumber),
                                const SizedBox(height: 4),
                                _buildOnlineStatus(contact.phoneNumber),
                              ],
                            ),

                            // CALL BUTTONS
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Audio Call
                                IconButton(
                                  icon: const Icon(
                                    Icons.call,
                                    color: Colors.green,
                                  ),
                                  tooltip: 'Audio Call',
                                  onPressed: () {
                                    _startCall(contact.phoneNumber, 'audio');
                                  },
                                ),

                                // Video Call
                                IconButton(
                                  icon: const Icon(
                                    Icons.videocam,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Video Call',
                                  onPressed: () {
                                    _startCall(contact.phoneNumber, 'video');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Add Contact button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );

          if (!mounted) return;

          final user = context.read<AuthProvider>().currentUser;

          if (user != null) {
            await context.read<ContactProvider>().loadContacts(user.uid);
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

 
// Online / Offline status
Widget _buildOnlineStatus(String phoneNumber) {
  final normalizedPhone = normalizePhone(phoneNumber);

  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .snapshots(),
    builder: (context, snapshot) {
      // Loading
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text(
          'Checking...',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        );
      }

      // Contact not registered
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: Colors.red,
            ),
            SizedBox(width: 5),
            Text(
              'Offline',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }

      // Get registered user's Firestore data
      final data = snapshot.data!.docs.first.data();

      final bool isOnline = data['isOnline'] == true;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    },
  );
}


// -----------------------------------
Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          const Text(
            'No contacts found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a contact to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }}