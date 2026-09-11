
import 'package:connect_call/providers/auth_provider.dart';
import 'package:connect_call/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully!',
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Registration failed',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 195, 238, 241),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/nobglogo.png',
                    height: 130,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(
                        255,
                        15,
                        52,
                        95,
                      ),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Create your ConnectCall account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(
                        179,
                        27,
                        54,
                        104,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon:
                          const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 15,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon:
                          const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }

                      // Remove spaces, +, -, brackets, etc.
                      final digits =
                          value.replaceAll(RegExp(r'\D'), '');

                      if (digits.length < 10) {
                        return 'Please enter a valid phone number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Confirm Password
                  TextFormField(
                    controller:
                        _confirmPasswordController,
                    obscureText:
                        _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value !=
                          _passwordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  // Register Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(
                          255,
                          18,
                          108,
                          136,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Back to Login
                  OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color.fromARGB(
                        255,
                        18,
                        108,
                        136,
                      ),
                      side: const BorderSide(
                        color: Color.fromARGB(
                          255,
                          18,
                          108,
                          136,
                        ),
                        width: 1.5,
                      ),
                      minimumSize:
                          const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
