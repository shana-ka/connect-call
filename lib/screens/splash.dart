// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import 'login_screen.dart';
// import 'home_screen.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _checkAuthentication();
//   }

//   Future<void> _checkAuthentication() async {
//     // Wait for Firebase to determine the authentication state
//     await Future.delayed(const Duration(seconds: 10));
//     final User? user = await FirebaseAuth.instance.authStateChanges().first;

//     if (!mounted) return;

//     if (user != null) {
//       // User is logged in
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//       );
//     } else {
//       // User is not logged in
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const LoginScreen()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 182, 218, 221),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // App Logo
//             Image(image: AssetImage('assets/nobglogo.png')),
          
//             Center(
//               child: Text(
//                 'Connect with anyone, anywhere.',
//                 style: TextStyle(
//                   color: Color.fromARGB(255, 48, 93, 97),
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),

//             // Loading Indicator
//             const SizedBox(
//               width: 30,
//               height: 30,
//               child: CircularProgressIndicator(
//                 strokeWidth: 3,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ),

//             const SizedBox(height: 15),
//           ],
//         ),
//       ),
//     );
//   }
// }



// ----------------------------------------------------------------
import 'package:connect_call/screens/home_screen.dart';
import 'package:connect_call/screens/login_screen.dart';
import 'package:connect_call/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 238, 241),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          Image.asset(
            'assets/nobglogo.png',
          
          ),
        
          Text(
                'Connect with anyone, anywhere.',
                style: TextStyle(
                  color: Color.fromARGB(255, 48, 93, 97),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ],
      ),
    );
  }
}