import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_call/providers/auth_provider.dart';
import 'package:connect_call/providers/contact_provider.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() =>
      _AddContactScreenState();
}

class _AddContactScreenState
    extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<ContactProvider>().addContact(
            userId: user.uid,
            name: _nameController.text,
            phoneNumber: _phoneController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact added successfully'),
        ),
      );

      Navigator.pop(context);
   } catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Failed to add contact: $e',
      ),
    ),
  );
} finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              const CircleAvatar(
                radius: 45,
                child: Icon(
                  Icons.person_add,
                  size: 45,
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter contact name',
                  prefixIcon:
                      const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter a name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon:
                      const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }

                  if (value.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _addContact,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Save Contact',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}