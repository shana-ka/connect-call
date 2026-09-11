
import 'package:connect_call/core/theme/app_theme.dart';
import 'package:connect_call/firebase_options.dart';
import 'package:connect_call/providers/auth_provider.dart';
import 'package:connect_call/providers/contact_provider.dart';
import 'package:connect_call/screens/splash.dart';
import 'package:connect_call/screens/webrtc_sccreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ContactProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ConnectCall',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      // home: const WebRTCTestScreen(),
    );
  }
}
