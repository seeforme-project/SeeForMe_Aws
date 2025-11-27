import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seeforyou_aws/screens/auth/privacy_terms_screen.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
import 'package:seeforyou_aws/logic/blind_live_screen.dart';
import 'package:seeforyou_aws/services/agora_service.dart';
import 'package:seeforyou_aws/services/blind_user_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with WidgetsBindingObserver {
  bool _isConnecting = false;
  String? _activeCallId;
  final FlutterTts _flutterTts = FlutterTts();
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTTS();
    BlindUserService.getDeviceId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
    _tapTimer?.cancel();
    if (_activeCallId != null) {
      _cancelCall(_activeCallId!);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (_activeCallId != null) {
        _cancelCall(_activeCallId!);
      }
    }
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.speak(
        "Welcome to See for Me. "
            "Tap red button for Emergency. "
            "Double tap for volunteer. "
            "Triple tap for AI."
    );
  }

  void _handleScreenTaps() {
    setState(() => _tapCount++);
    if (_tapTimer != null) _tapTimer!.cancel();

    _tapTimer = Timer(const Duration(milliseconds: 600), () async {
      if (_tapCount == 2) {
        await _flutterTts.stop();
        await _flutterTts.speak("Starting video call.");
        _startVisualAssistanceCall();
      } else if (_tapCount == 3) {
        await _flutterTts.stop();
        await _flutterTts.speak("Opening AI.");
        _openAI();
      }
      _tapCount = 0;
    });
  }

  void _openAI() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BlindLiveScreen()));
  }

  Future<void> _triggerEmergency() async {
    await _flutterTts.stop();
    setState(() => _isConnecting = true);

    final trustedVolId = await BlindUserService.findAvailableTrustedVolunteer();

    if (trustedVolId != null) {
      await _flutterTts.speak("Emergency activated, Calling trusted volunteer.");
      _startVisualAssistanceCall(targetVolunteerId: trustedVolId);
    } else {
      await _flutterTts.speak("No trusted volunteers. Connecting to AI.");
      if (mounted) {
        setState(() => _isConnecting = false);
        _openAI();
      }
    }
  }

  Future<bool> _areVolunteersAvailable() async {
    try {
      const String query = r'''
        query ListAvailableVolunteers {
          listVolunteers(filter: {isAvailableNow: {eq: true}}, limit: 1) {
            items { id }
          }
        }
      ''';
      final request = GraphQLRequest<String>(document: query, authorizationMode: APIAuthorizationType.apiKey);
      final response = await Amplify.API.query(request: request).response;
      if (response.data != null) {
        final data = jsonDecode(response.data!);
        return (data['listVolunteers']['items'] as List).isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- UPDATED METHOD: Added [checkStatus] parameter ---
  Future<void> _startVisualAssistanceCall({String? targetVolunteerId, bool checkStatus = true}) async {
    await _flutterTts.stop();
    setState(() => _isConnecting = true);

    // 1. Check Status (Only if checkStatus is true)
    if (checkStatus) {
      final status = await BlindUserService.checkUserStatus();

      // Check Ban
      if (status['isBanned'] == true) {
        setState(() => _isConnecting = false);
        await _speakCriticalMessage(
            "Your account has been suspended due to repeated safety violations. You cannot make calls."
        );
        return; // STOP HERE
      }

      // Check Warning
      String? warningMsg = status['adminWarningMessage'];
      // Handle null safely: default to false
      bool isAcknowledged = status['adminWarningAcknowledged'] ?? false;

      // Logic: If there is a message AND it is NOT acknowledged
      if (warningMsg != null && warningMsg.isNotEmpty && !isAcknowledged) {
        setState(() => _isConnecting = false);

        // Play the warning
        await _speakCriticalMessage(
            "Important message from Support. $warningMsg. "
                "Double tap the screen to acknowledge and continue."
        );

        // Show a blocking dialog that requires interaction
        await _showAcknowledgmentDialog();
        return; // Stop here, user must re-initiate via dialog
      }
    }

    // 2. Proceed with Call Logic (if no warning or checkStatus was false)
    if (targetVolunteerId == null) {
      safePrint("Checking volunteers...");
      bool available = await _areVolunteersAvailable();
      if (!available) {
        await _flutterTts.speak("No volunteers available. Use AI assistance.");
        setState(() => _isConnecting = false);
        return;
      }
    }

    setState(() => _isConnecting = true);

    final channelName = AgoraService.generateChannelName();
    final guestName = 'Blind User ${DateTime.now().millisecondsSinceEpoch % 10000}';
    final blindUserId = await BlindUserService.getDeviceId();

    try {
      const createCallMutation = r'''
        mutation CreateCall($input: CreateCallInput!) {
          createCall(input: $input) {
            id
          }
        }
      ''';

      final createRequest = GraphQLRequest<String>(
        document: createCallMutation,
        variables: {
          'input': {
            'blindUserId': blindUserId,
            'blindUserName': guestName,
            'status': 'PENDING',
            'meetingId': channelName,
          }
        },
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final createResponse = await Amplify.API.mutate(request: createRequest).response;

      if (createResponse.hasErrors) {
        setState(() => _isConnecting = false);
        return;
      }

      final callData = jsonDecode(createResponse.data!)['createCall'];
      _activeCallId = callData['id'];

      if (!mounted) return;

      await _flutterTts.stop();

      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              channelName: channelName,
              userName: guestName,
              isBlindUser: true,
              callId: _activeCallId!,
            ),
          ),
        );
      } catch (e) {
        safePrint("Nav error: $e");
      } finally {
        if (_activeCallId != null) {
          await _cancelCall(_activeCallId!);
        }
        if (mounted) setState(() { _isConnecting = false; _activeCallId = null; });
      }
    } catch (e) {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _speakCriticalMessage(String message) async {
    await _flutterTts.setSpeechRate(0.5); // Speak slowly/clearly
    await _flutterTts.speak(message);
  }

  // --- UPDATED DIALOG: Retries call immediately after success ---
  Future<void> _showAcknowledgmentDialog() async {
    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false, // User MUST tap the screen
      builder: (ctx) => GestureDetector(
        // Make the whole screen a button for blind accessibility
        onDoubleTap: () async {
          // 1. Give Feedback immediately
          await _flutterTts.stop();
          await _flutterTts.speak("Processing acknowledgment. Please wait.");

          // 2. Perform the DB update and WAIT for it
          bool success = await BlindUserService.clearWarningMessage();

          if (!mounted) return;

          if (success) {
            // 3. Close dialog
            await _flutterTts.speak("Acknowledged. Connecting you now.");
            Navigator.pop(ctx);

            // 4. IMPORTANT: Retry call immediately, skipping the DB check
            // This prevents the loop/race condition
            _startVisualAssistanceCall(checkStatus: false);

          } else {
            // 5. If failed, keep dialog open and retry
            await _flutterTts.speak("Network error. Please double tap again to acknowledge.");
          }
        },
        child: Container(
          color: Colors.redAccent, // High contrast
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "WARNING\n\nDouble Tap to Acknowledge",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelCall(String callId) async {
    try {
      const getStatusQuery = r'''
        query GetCallStatus($id: ID!) {
          getCall(id: $id) {
            status
          }
        }
      ''';

      final statusRequest = GraphQLRequest<String>(
          document: getStatusQuery,
          variables: {'id': callId},
          authorizationMode: APIAuthorizationType.apiKey
      );

      final statusResponse = await Amplify.API.query(request: statusRequest).response;

      if (statusResponse.data != null) {
        final data = jsonDecode(statusResponse.data!);
        if (data['getCall'] != null) {
          final currentStatus = data['getCall']['status'];
          if (currentStatus == 'COMPLETED') {
            safePrint("✅ Call $callId is already COMPLETED. Skipping cancellation.");
            return;
          }
        }
      }

      const mutation = r'''mutation CancelCall($id: ID!) { updateCall(input: {id: $id, status: CANCELLED}) { id status } }''';
      await Amplify.API.mutate(request: GraphQLRequest<String>(document: mutation, variables: {'id': callId}, authorizationMode: APIAuthorizationType.apiKey)).response;
      safePrint("⚠️ Call $callId cancelled (was not completed).");
    } catch (e) {
      safePrint("Error in _cancelCall: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleScreenTaps,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Image.asset('assets/app_logo.png', height: 70),
                const SizedBox(height: 10),
                Text('See for Me', style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[850])),
                Text('Double tap: Volunteer | Triple tap: AI', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600])),
                const Spacer(flex: 1),
                SizedBox(
                  width: double.infinity, height: 70,
                  child: ElevatedButton.icon(
                    onPressed: _isConnecting ? null : _triggerEmergency,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                    label: Text("EMERGENCY CALL", style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLargeButton(icon: Icons.videocam, title: "Call Volunteer", subtitle: "Tap here or Double Tap screen", color: const Color(0xFF093B75), isLoading: _isConnecting, onPressed: _isConnecting ? null : () => _startVisualAssistanceCall()),
                const SizedBox(height: 20),
                _buildLargeButton(icon: Icons.auto_awesome, title: "Ask AI", subtitle: "Tap here or Triple Tap screen", color: const Color(0xFF6A0DAD), isLoading: false, onPressed: _openAI),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyTermsScreen())),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF093B75), width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text("I'd like to volunteer", style: GoogleFonts.lato(fontSize: 16, color: const Color(0xFF093B75), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeButton({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback? onPressed, required bool isLoading}) {
    return SizedBox(
      width: double.infinity, height: 120,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color, disabledBackgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 36, color: Colors.white), const SizedBox(height: 8), Text(title, style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), Text(subtitle, style: GoogleFonts.lato(fontSize: 13, color: Colors.white70))]),
      ),
    );
  }
}