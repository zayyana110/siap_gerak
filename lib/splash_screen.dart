import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Royal Blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              "SiapGerak",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Slogan / Subtitle
            Text(
              "Kelola Misimu, Capai Targetmu",
              style: TextStyle(fontSize: 16, color: Colors.blue.shade100),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
