import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seeforyou_aws/screens/auth/privacy_terms_screen.dart';
import 'package:seeforyou_aws/services/agora_service.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
import 'package:seeforyou_aws/logic/blind_live_screen.dart';
import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isConnecting = false;
  final FlutterTts _flutterTts = FlutterTts();

  // Variables for Gesture Detection
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _tapTimer?.cancel();
    super.dispose();
  }

  // 1. Initialize Voice Guidance
  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Speak the welcome message
    await _flutterTts.speak(
        "Welcome to See for Me app. "
            "If you need visual assistance help, tap twice on the screen anywhere to start a video call with a volunteer, "
            "and tap three times to get AI assistance."
    );
  }

  // 2. Handle Screen Taps
  void _handleScreenTaps() {
    setState(() {
      _tapCount++;
    });

    if (_tapTimer != null) {
      _tapTimer!.cancel();
    }

    _tapTimer = Timer(const Duration(milliseconds: 600), () {
      if (_tapCount == 2) {
        _flutterTts.speak("Starting video call with volunteer");
        _startVisualAssistanceCall();
      } else if (_tapCount == 3) {
        _flutterTts.speak("Opening AI Assistant");
        _openAI();
      }
      _tapCount = 0; // Reset counter
    });
  }

  void _openAI() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BlindLiveScreen()),
    );
  }

  // Start video call for blind users (guest mode - no auth required)
  Future<void> _startVisualAssistanceCall() async {
    // Stop any ongoing speech so it doesn't overlap
    _flutterTts.stop();

    setState(() {
      _isConnecting = true;
    });

    try {
      // Generate unique channel name
      final channelName = AgoraService.generateChannelName();
      final guestName = 'Blind User ${DateTime.now().millisecondsSinceEpoch % 10000}';

      safePrint('Creating call channel: $channelName for guest: $guestName');

      // Create call record in database (so volunteers ca n see it)
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
        // Optionally speak again when they return
        _flutterTts.speak("Call ended. Tap twice for volunteer, three times for AI.");
      });
    } catch (e) {
      safePrint('Error starting visual assistance: $e');
      _flutterTts.speak("An error occurred starting the call.");
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
      // 3. WRAP BODY IN GESTURE DETECTOR
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleScreenTaps,
        child: SafeArea(
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
                  'Double tap anywhere for Volunteer\nTriple tap for AI',
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
                  subtitle: "Tap here or Double Tap screen",
                  color: const Color(0xFF093B75),
                  isLoading: _isConnecting,
                  onTap: _isConnecting ? null : _startVisualAssistanceCall,
                ),

                const SizedBox(height: 20),

                // --- BUTTON 2: AI ASSISTANT ---
                _buildLargeButton(
                  icon: Icons.auto_awesome,
                  title: "Ask AI",
                  subtitle: "Tap here or Triple Tap screen",
                  color: const Color(0xFF6A0DAD), // Purple for AI
                  isLoading: false,
                  onTap: _openAI,
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
      ),
    );
  }

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
      height: 140,
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