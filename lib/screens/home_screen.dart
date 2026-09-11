
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_call/models/user_model.dart';
import 'package:connect_call/screens/call_screen.dart';
import 'package:connect_call/providers/auth_provider.dart';
import 'package:connect_call/screens/add_contact_screen.dart';
import 'package:connect_call/screens/contact_screen.dart';
import 'package:connect_call/screens/history_screen.dart';
import 'package:connect_call/screens/login_screen.dart';
import 'package:connect_call/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final TextEditingController _searchController =
      TextEditingController();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _incomingCallSubscription;

  String? _lastIncomingCallId;

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  void _searchContacts() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a name or phone number',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = 1;
    });
  }

  // ------------------------------------------------------------
  // INCOMING CALL LISTENER
  // ------------------------------------------------------------

  void _listenForIncomingCalls(String uid) {
  _incomingCallSubscription?.cancel();

  debugPrint(
    'LISTENING FOR INCOMING CALLS FOR USER: $uid',
  );

  _incomingCallSubscription = FirebaseFirestore.instance
      .collection('calls')
      .where('receiverId', isEqualTo: uid)
      .where('status', isEqualTo: 'ringing')
      .snapshots()
      .listen(
    (snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) {
          continue;
        }

        final doc = change.doc;
        final data = doc.data();

        if (data == null) {
          continue;
        }

        final callerId = data['callerId'];

        // IMPORTANT:
        // Never show an incoming dialog for our own call.
        if (callerId == uid) {
          debugPrint(
            'IGNORING OWN CALL: ${doc.id}',
          );
          continue;
        }

        // Prevent the same call from opening again.
        if (_lastIncomingCallId == doc.id) {
          continue;
        }

        _lastIncomingCallId = doc.id;

        debugPrint(
          'INCOMING CALL FOUND: ${doc.id}',
        );

        debugPrint(
          'CALLER: ${data['callerName']}',
        );

        debugPrint(
          'CALLER ID: ${data['callerId']}',
        );

        debugPrint(
          'RECEIVER ID: ${data['receiverId']}',
        );

        _showIncomingCallDialog(
          callId: doc.id,
          data: data,
        );
      }
    },
    onError: (error) {
      debugPrint(
        'INCOMING CALL LISTENER ERROR: $error',
      );
    },
  );
}

  // ------------------------------------------------------------
  // INCOMING CALL DIALOG
  // ------------------------------------------------------------

  void _showIncomingCallDialog({
    required String callId,
    required Map<String, dynamic> data,
  }) {
    if (!mounted) return;

    final callerName =
        data['callerName'] ?? 'Unknown';

    final callType =
        data['type'] ?? 'audio';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            callType == 'video'
                ? 'Incoming Video Call'
                : 'Incoming Audio Call',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 35,
                child: Icon(
                  Icons.person,
                  size: 35,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                callerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                callType == 'video'
                    ? 'is calling you with video'
                    : 'is calling you',
              ),
            ],
          ),

          actions: [
            // --------------------------------------------------
            // DECLINE
            // --------------------------------------------------

            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  await FirebaseFirestore.instance
                      .collection('calls')
                      .doc(callId)
                      .update({
                    'status': 'rejected',
                  });

                  debugPrint(
                    'CALL REJECTED: $callId',
                  );
                } catch (e) {
                  debugPrint(
                    'REJECT CALL ERROR: $e',
                  );
                }
              },
              child: const Text(
                'Decline',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),

            // --------------------------------------------------
            // ACCEPT
            // --------------------------------------------------

            ElevatedButton(
              onPressed: () async {
  Navigator.pop(dialogContext);

  try {
    // Immediately stop HomeScreen from treating
    // this as a new ringing call.
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .update({
      'status': 'connecting',
    });

    debugPrint(
      'CALL ACCEPTED: $callId',
    );

    final caller = UserModel(
      uid: data['callerId'] ?? '',
      name: data['callerName'] ?? '',
      phone: '',
      email: '',
      status: '',
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          user: caller,
          callType: callType,
          incomingCallId: callId,
        ),
      ),
    );
  } catch (e) {
    debugPrint(
      'ACCEPT CALL ERROR: $e',
    );
  }
},
              child: const Text(
                'Accept',
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // INIT STATE
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;

        final authProvider =
            context.read<AuthProvider>();

        final user = authProvider.currentUser;

        if (user != null) {
          _listenForIncomingCalls(user.uid);
        }
      },
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    final user = authProvider.currentUser;

    final List<Widget> pages = [
      _buildHome(user),
      ContactsScreen(),
      HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 5.0),
          child: IconButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
            icon: const Icon(
              Icons.account_circle_sharp,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),

      ),

      body: pages[_selectedIndex],

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,

        selectedItemColor:
            const Color.fromARGB(
          255,
          18,
          108,
          136,
        ),

        unselectedItemColor:
            Colors.grey,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.contacts_outlined,
            ),
            activeIcon: Icon(
              Icons.contacts,
            ),
            label: 'Contacts',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.call_outlined,
            ),
            activeIcon: Icon(
              Icons.call,
            ),
            label: 'Calls',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HOME PAGE
  // ------------------------------------------------------------

  Widget _buildHome(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const SizedBox(height: 10),

          const Text(
            'Connect with your contacts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Make audio and video calls easily.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 25),

          // SEARCH BUTTON

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },

              icon: const Icon(
                Icons.search,
              ),

              label: const Text(
                'Search Contacts Here',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(
                  188,
                  63,
                  149,
                  175,
                ),

                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.contacts,
                  title: 'Contacts',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _actionCard(
                  icon: Icons.person_add,
                  title: 'Add Contact',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddContactScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.call,
                  title: 'Call History',
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: SizedBox(),
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTION CARD
  // ------------------------------------------------------------

  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(15),

      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color:
                    const Color.fromARGB(
                  255,
                  18,
                  108,
                  136,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
