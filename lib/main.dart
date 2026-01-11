import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'gamification_provider.dart'; // Import Provider Logic
import 'splash_screen.dart'; // Import Splash Screen
import 'login_page.dart';
import 'main_screen.dart';

import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init(); // Initialize Notification Service
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: const SiapGerakApp(),
    ),
  );
}

class SiapGerakApp extends StatelessWidget {
  const SiapGerakApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan Selector agar hanya rebuild jika currentTheme berubah
    return Selector<GamificationProvider, ThemeData>(
      selector: (_, gamification) => gamification.currentTheme,
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SiapGerak',
          theme: theme, // Gunakan tema dari Selector
          themeAnimationDuration: const Duration(
            milliseconds: 500,
          ), // Animasi smooth
          // Gunakan AuthWrapper untuk handle Splash + Auth
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Tampilkan Splash selama 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    // Setelah Splash selesai, cek status login
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Jika masih loading auth (jarang terjadi setelah 3 detik, tapi untuk jaga-jaga)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const LoginPage();
      },
    );
  }
}
