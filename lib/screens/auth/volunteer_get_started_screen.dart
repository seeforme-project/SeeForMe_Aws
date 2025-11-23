// lib/screens/auth/volunteer_get_started_screen.dart
import 'package:flutter/material.dart';
import 'package:seeforyou_aws/screens/auth/login_screen.dart';
import 'package:seeforyou_aws/screens/auth/signup_screen.dart';

class VolunteerGetStartedScreen extends StatelessWidget {
  const VolunteerGetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Get started",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Navigate to the screen that asks for name/email/pass
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF), // Blue button
              ),
              child: const Text("Continue with Email"),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Google Sign-In
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Sign-In coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              // Make sure you have the google logo in your assets folder
              // and have added it to pubspec.yaml
              icon: Image.asset('assets/google_logo.png', height: 24.0),
              label: const Text("Continue with Google"),
            ),

            // ----- ADDED WIDGETS START HERE -----

            const Spacer(), // Pushes the login button to the bottom

            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                'Already have an account? Log In',
                style: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),

            const SizedBox(height: 20), // Adds some space at the bottom

            // ----- ADDED WIDGETS END HERE -----
          ],
        ),
      ),
    );
  }
}