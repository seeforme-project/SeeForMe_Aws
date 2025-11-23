import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:seeforyou_aws/screens/auth/privacy_terms_screen.dart';
import 'package:seeforyou_aws/screens/blind_home_screen.dart';
import 'package:seeforyou_aws/services/agora_service.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
// 👇 IMPORT THE NEW LIVE SCREEN
import 'package:seeforyou_aws/logic/blind_live_screen.dart';
import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';

import '../logic/blind_live_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isConnecting = false;

  // Start video call for blind users (guest mode - no auth required)
  Future<void> _startVisualAssistanceCall() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      // Generate unique channel name
      final channelName = AgoraService.generateChannelName();
      final guestName = 'Blind User ${DateTime.now().millisecondsSinceEpoch % 10000}';

      safePrint('Creating call channel: $channelName for guest: $guestName');

      // Create call record in database (so volunteers can see it)
      const createCallMutation = r'''
        mutation CreateCall($input: CreateCallInput!) {
          createCall(input: $input) {
            id
            blindUserId
            blindUserName
            status
            meetingId
            createdAt
          }
        }
      ''';

      try {
        final createRequest = GraphQLRequest<String>(
          document: createCallMutation,
          variables: {
            'input': {
              'blindUserId': 'guest_${DateTime.now().millisecondsSinceEpoch}',
              'blindUserName': guestName,
              'status': 'PENDING',
              'meetingId': channelName,
            }
          },
          authorizationMode: APIAuthorizationType.apiKey,
        );

        final createResponse = await Amplify.API.mutate(request: createRequest).response;
        safePrint('Create call response: ${createResponse.data}');

        if (createResponse.hasErrors) {
          safePrint('Error creating call record: ${createResponse.errors}');
        }
      } catch (e) {
        safePrint('Could not create call record (user might not be authenticated): $e');
      }

      if (!mounted) return;

      // Navigate directly to video call
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            channelName: channelName,
            userName: guestName,
            isBlindUser: true,
          ),
        ),
      ).then((_) {
        // Call ended - back to welcome screen
        setState(() {
          _isConnecting = false;
        });
      });
    } catch (e) {
      safePrint('Error starting visual assistance: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to start call: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // App logo
              Image.asset(
                'assets/app_logo.png',
                height: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'See for Me',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[850],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How can we help you today?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const Spacer(flex: 1),

              // --- BUTTON 1: VIDEO CALL ---
              _buildLargeButton(
                icon: Icons.videocam,
                title: "Call Volunteer",
                subtitle: "Video call a human helper",
                color: const Color(0xFF093B75), // Deep Blue
                isLoading: _isConnecting,
                onTap: _isConnecting ? null : _startVisualAssistanceCall,
              ),

              const SizedBox(height: 20),

              // --- BUTTON 2: AI ASSISTANT ---
              _buildLargeButton(
                icon: Icons.auto_awesome,
                title: "Ask AI",
                subtitle: "Chat with AI Assistant",
                color: const Color(0xFF6A0DAD), // Purple for AI
                isLoading: false,
                onTap: () {
                  // Navigate to the new BlindLiveScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlindLiveScreen()),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Secondary button - Volunteer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyTermsScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF093B75), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "I'd like to volunteer",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: const Color(0xFF093B75),
                      fontWeight: FontWeight.w600,
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

  // Helper widget to make consistent, large accessibility buttons
  Widget _buildLargeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 140, // Large height for easy tapping
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}