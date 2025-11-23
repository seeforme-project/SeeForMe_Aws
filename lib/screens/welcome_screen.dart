import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:seeforyou_aws/screens/auth/privacy_terms_screen.dart';
import 'package:seeforyou_aws/screens/blind_home_screen.dart';
import 'package:seeforyou_aws/services/agora_service.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';

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
          // Continue anyway - we can still make the call
        }
      } catch (e) {
        safePrint('Could not create call record (user might not be authenticated): $e');
        // Continue anyway - guest users can still make calls
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
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App logo
              Image.asset(
                'assets/app_logo.png',
                height: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'See for Me',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[850],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your window to the world.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(flex: 3),

              // MAIN BUTTON - Start visual assistance call
              SizedBox(
                width: double.infinity,
                height: 70, // Larger button for accessibility
                child: ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _startVisualAssistanceCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF093B75),
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isConnecting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.videocam, size: 32),
                  label: Text(
                    _isConnecting
                        ? 'Connecting to volunteer...'
                        : 'I need visual assistance',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Helper text for blind users
              if (!_isConnecting)
                Text(
                  'Tap the button above to instantly connect\nwith a volunteer who can help you see',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),

              const SizedBox(height: 32),

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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}