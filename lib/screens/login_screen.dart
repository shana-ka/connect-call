// import 'package:connect_call/screens/home_screen.dart';
// import 'package:connect_call/screens/register_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
// bool _isLoading = false;
//  bool _obscurePassword = true;
//   Future <void> _login() async{
// setState(() {
//   _isLoading = true;

// });

//    try {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const HomeScreen(),
//         ),
//       );
//     } on FirebaseAuthException catch (e) {
//       String message = 'Login failed';

//       if (e.code == 'user-not-found') {
//         message = 'No account found with this email.';
//       } else if (e.code == 'wrong-password') {
//         message = 'Incorrect password.';
//       } else if (e.code == 'invalid-credential') {
//         message = 'Invalid email or password.';
//       } else if (e.code == 'invalid-email') {
//         message = 'Please enter a valid email address.';
//       } else if (e.code == 'too-many-requests') {
//         message = 'Too many attempts. Please try again later.';
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Something went wrong. Please try again.'),
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//     void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 195, 238, 241),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Form(
//               // key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Logo
//                   Image(image: AssetImage('assets/nobglogo.png')),

//                   const Text(
//                     'Welcome Back!',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color.fromARGB(255, 15, 52, 95),
//                       fontSize: 30,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   const Text(
//                     'Login to your ConnectCall account',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color.fromARGB(179, 27, 54, 104),
//                       fontSize: 15,fontWeight: FontWeight.bold,
//                     ),
//                   ),

//                   const SizedBox(height: 35),

//                   // Email
//                   TextFormField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       labelText: 'Email',
//                       prefixIcon: const Icon(Icons.email_outlined),
//                       filled: true,
//                       fillColor: Colors.white,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter your email';
//                       }

//                       if (!value.contains('@')) {
//                         return 'Please enter a valid email';
//                       }

//                       return null;
//                     },
//                   ),

//                   const SizedBox(height: 18),

//                   // Password
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: _obscurePassword,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscurePassword
//                               ? Icons.visibility_off
//                               : Icons.visibility,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscurePassword = !_obscurePassword;
//                           });
//                         },
//                       ),
//                       filled: true,
//                       fillColor: Colors.white,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your password';
//                       }

//                       return null;
//                     },
//                   ),

//                   const SizedBox(height: 25),

//                   // Login button
//                   SizedBox(
//                     height: 55,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _login,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor:
//                             const Color.fromARGB(255, 18, 108, 136),
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                       ),
//                       child: _isLoading
//                           ? const SizedBox(
//                               width: 25,
//                               height: 25,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 3,
//                               ),
//                             )
//                           : const Text(
//                               'Login',
//                               style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Create account
//                   OutlinedButton(
//                     onPressed: _isLoading
//                         ? null
//                         : () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     const RegisterScreen(),
//                               ),
//                             );
//                           },
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: const Color.fromARGB(255, 18, 108, 136),
//                       side: const BorderSide(
//                         color: Color.fromARGB(255, 18, 108, 136),
//                         width: 1.5,
//                       ),
//                       minimumSize: const Size(double.infinity, 55),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                     ),
//                     child: const Text(
//                       'Create Account',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// -------------------------------------------------------------------
import 'package:connect_call/providers/auth_provider.dart';
import 'package:connect_call/screens/home_screen.dart';
import 'package:connect_call/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 238, 241),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/nobglogo.png', width: 30),

               

                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(255, 15, 52, 95),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Login to your ConnectCall account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(179, 27, 54, 104),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
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
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  // Login Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          18,
                          108,
                          136,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Create Account
                  OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 18, 108, 136),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 18, 108, 136),
                        width: 1.5,
                      ),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
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
