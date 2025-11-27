import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:seeforyou_aws/services/agora_service.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/blind_user_service.dart';

class BlindHomeScreen extends StatefulWidget {
  const BlindHomeScreen({super.key});

  @override
  State<BlindHomeScreen> createState() => _BlindHomeScreenState();
}

class _BlindHomeScreenState extends State<BlindHomeScreen> {
  bool _isSearchingVolunteer = false;
  String? _currentCallId;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // UPDATED: Added [checkStatus] parameter to avoid the loop
  Future<void> _requestVisualAssistance({bool checkStatus = true}) async {
    setState(() {
      _isSearchingVolunteer = true;
    });

    try {
      final user = await Amplify.Auth.getCurrentUser();

      // Only check status if we haven't just acknowledged a warning
      if (checkStatus) {
        // 1. CHECK USER STATUS
        final status = await BlindUserService.checkUserStatus();

        // A. Check Ban
        if (status['isBanned'] == true) {
          _speak("You have been banned from using this service.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Account Banned"), backgroundColor: Colors.red),
            );
          }
          setState(() => _isSearchingVolunteer = false);
          return;
        }

        // B. Check Warning
        String? warningMsg = status['adminWarningMessage'];
        // Use ?? false so null becomes false
        bool isAcknowledged = status['adminWarningAcknowledged'] ?? false;

        // LOGIC: If message exists AND is NOT acknowledged, show screen
        if (warningMsg != null && warningMsg.isNotEmpty && !isAcknowledged) {
          // Stop loading
          setState(() => _isSearchingVolunteer = false);
          // Show blocking dialog
          await _showWarningDialog(warningMsg);
          return; // STOP execution here
        }
      }

      // 2. PROCEED TO CALL (If no warning or checkStatus is false)
      final channelName = AgoraService.generateChannelName();

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

      final createRequest = GraphQLRequest<String>(
        document: createCallMutation,
        variables: {
          'input': {
            'blindUserId': user.userId,
            'blindUserName': user.username,
            'status': 'PENDING',
            'meetingId': channelName,
          }
        },
      );

      final createResponse = await Amplify.API.mutate(request: createRequest).response;

      if (createResponse.hasErrors) {
        throw Exception(createResponse.errors.first.message);
      }

      final callData = jsonDecode(createResponse.data!)['createCall'];
      _currentCallId = callData['id'];

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            channelName: channelName,
            userName: user.username,
            isBlindUser: true,
            callId: _currentCallId!,
          ),
        ),
      );
    } catch (e) {
      safePrint('Error requesting assistance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingVolunteer = false;
        });
      }
    }
  }

  Future<void> _showWarningDialog(String message) async {
    _speak("Warning. $message. Double tap 'I Understand' to continue.");

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Text("⚠️ Administrative Warning",
            style: TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 1. Send update to DB
              await BlindUserService.clearWarningMessage();

              if (mounted) {
                flutterTts.stop();
                Navigator.pop(context); // Close dialog

                // 2. Retry call, but SKIP the DB check this time
                // This breaks the loop because we trust the user just clicked it.
                _requestVisualAssistance(checkStatus: false);
              }
            },
            child: const Text("I Understand",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          )
        ],
      ),
    );
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(text);
  }

  Future<void> _endCall() async {
    if (_currentCallId == null) return;
    try {
      const updateMutation = r'''
        mutation UpdateCall($input: UpdateCallInput!) {
          updateCall(input: $input) {
            id
            status
          }
        }
      ''';
      final request = GraphQLRequest<String>(
        document: updateMutation,
        variables: {
          'input': { 'id': _currentCallId, 'status': 'CANCELLED' }
        },
      );
      await Amplify.API.mutate(request: request).response;
      _currentCallId = null;
    } catch (e) {
      safePrint('Error ending call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visual Assistance')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.visibility, size: 100, color: Color(0xFF007AFF)),
              const SizedBox(height: 32),
              const Text(
                'Need help seeing something?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect with a volunteer who can help you see',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isSearchingVolunteer ? null : () => _requestVisualAssistance(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSearchingVolunteer
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('Connecting...',
                          style: TextStyle(
                              fontSize: 18, color: Colors.white)),
                    ],
                  )
                      : const Text('I Need Visual Assistance',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}