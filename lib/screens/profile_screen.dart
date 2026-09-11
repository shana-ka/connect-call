import 'package:connect_call/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect_call/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  bool _editing = false;
  bool _loading = true;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;

    final data = await _userService.getUser(user!.uid);

    if (data != null) {
      _nameController.text = data.name;
      _phoneController.text = data.phone ?? '';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    try {
      await _userService.updateProfile(
        uid: user!.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      await user!.updateDisplayName(
        _nameController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _editing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
        ),
      );
    }
  }
  Future<void> _logout() async {
  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          const SizedBox(height: 20),

          const CircleAvatar(
            radius: 60,
            backgroundColor:
                Color.fromARGB(255, 18, 108, 136),
            child: Icon(
              Icons.person,
              size: 70,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            user?.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            user?.email ?? '',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 6),
          Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    ),
    const SizedBox(width: 6),
    const Text(
      'Online',
      style: TextStyle(
        color: Colors.green,
        fontSize: 14,
      ),
    ),
    
  ],
),
SizedBox(height: 20,),
         TextField(
  controller: _nameController,
  enabled: _editing,
  style: TextStyle(
    color: _editing ? Colors.black : const Color.fromARGB(248, 104, 102, 102),
  ),
  decoration: const InputDecoration(
    labelText: 'Name',
    prefixIcon: Icon(Icons.person),
    border: OutlineInputBorder(),
  ),
),

          const SizedBox(height: 15),

         TextField(
  controller: _phoneController,
  enabled: _editing,
  keyboardType: TextInputType.phone,
  style: TextStyle(
    color: _editing ? Colors.black : const Color.fromARGB(248, 104, 102, 102),
  ),
  decoration: const InputDecoration(
    labelText: 'Phone',
    prefixIcon: Icon(Icons.phone),
    border: OutlineInputBorder(),
  ),
),

          const SizedBox(height: 25),

         if (_editing)
  Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveProfile,
          child: const Text('Save Changes'),
        ),
      ),

      const SizedBox(height: 10),

      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _editing = false;
            });
          },
          child: const Text('Cancel'),
        ),
      ),
    ],
  )
else
  Column(
    children: [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _editing = true;
            });
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
        ),
      ),

      const SizedBox(height: 15),

      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(
            Icons.logout,
            color: Color.fromARGB(199, 180, 38, 28),
          ),
          label: const Text(
            'Logout',
            style: TextStyle(
              color: Color.fromARGB(199, 180, 38, 28),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color.fromARGB(199, 180, 38, 28),
            ),
          ),
        ),
      ),
    ],
  ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}