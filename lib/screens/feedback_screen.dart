import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeforyou_aws/services/blind_user_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String callId;
  final bool isBlindUser;
  final String? volunteerId;

  const FeedbackScreen({
    super.key,
    required this.callId,
    required this.isBlindUser,
    this.volunteerId,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSubmitting = false;
  int _tapCount = 0;
  Timer? _tapTimer;
  String? _selectedCategory;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isBlindUser) {
      _initBlindFeedback();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _tapTimer?.cancel();
    super.dispose();
  }

  Future<void> _initBlindFeedback() async {
    await _flutterTts.stop();
    await Future.delayed(const Duration(milliseconds: 500));
    await _flutterTts.setLanguage("en-US");

    String instructions = "Call ended. Double tap to rate five stars. "
        "Triple tap if you had a safety issue.";

    if (widget.volunteerId != null) {
      instructions += " Long press to add this volunteer to your Trusted List.";
    }

    await _flutterTts.speak(instructions);
  }

  void _handleBlindGestures() {
    if (_isSubmitting) return;
    setState(() => _tapCount++);
    if (_tapTimer != null) _tapTimer!.cancel();

    _tapTimer = Timer(const Duration(milliseconds: 600), () async {
      if (_tapCount == 2) {
        await _flutterTts.stop();
        await _flutterTts.speak("Rated five stars. Thank you.");
        _submitReport("GOOD_EXPERIENCE", "User rated via gesture");
      } else if (_tapCount == 3) {
        await _flutterTts.stop();
        await _flutterTts.speak("Report submitted. Admin will review.");
        _submitReport("SAFETY_CONCERN", "Blind user reported issue via gesture");
      }
      _tapCount = 0;
    });
  }

  Future<void> _addToTrusted() async {
    HapticFeedback.mediumImpact();
    await _flutterTts.stop();

    if (widget.volunteerId == null) {
      await _flutterTts.speak("Cannot identify volunteer.");
      return;
    }

    await _flutterTts.speak("Adding volunteer to trusted list.");
    await BlindUserService.addTrustedVolunteer(widget.volunteerId!);
    await _flutterTts.speak("Added successfully.");
  }

  Future<void> _submitReport(String category, String description) async {
    setState(() => _isSubmitting = true);
    try {
      const String mutation = r'''mutation CreateReport($input: CreateReportInput!) { createReport(input: $input) { id status } }''';
      final request = GraphQLRequest<String>(document: mutation, variables: {'input': {'callId': widget.callId, 'reportedBy': widget.isBlindUser ? 'BLIND' : 'VOLUNTEER', 'category': category, 'description': description, 'status': 'OPEN'}}, authorizationMode: APIAuthorizationType.apiKey);
      await Amplify.API.mutate(request: request).response;
      if (mounted) {
        if (!widget.isBlindUser) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback Submitted!')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBlindUser) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBF9F4),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleBlindGestures,
          onLongPress: _addToTrusted,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 80, color: Colors.grey[800]),
                const SizedBox(height: 20),
                const Text("Double Tap: Good experience\nTriple Tap: Report an issue\nLong Press: Add trusted volunteer", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Call Feedback")),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How was the call?", style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildOption("Everything went well", "GOOD_EXPERIENCE"),
              _buildOption("Technical/Connection Issues", "CONNECTION_ISSUES"),
              _buildOption("Inappropriate Behavior", "INAPPROPRIATE_BEHAVIOR"),
              _buildOption("Safety Concern", "SAFETY_CONCERN"),
              const SizedBox(height: 20),
              TextField(controller: _commentController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Additional Comments (Optional)"), maxLines: 3),
              const Spacer(),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isSubmitting || _selectedCategory == null ? null : () => _submitReport(_selectedCategory!, _commentController.text), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF093B75)), child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Feedback", style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOption(String text, String value) {
    bool isSelected = _selectedCategory == value;
    return GestureDetector(onTap: () => setState(() => _selectedCategory = value), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: isSelected ? Colors.blue[50] : Colors.white, border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300), borderRadius: BorderRadius.circular(10)), child: Row(children: [Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.blue : Colors.grey), const SizedBox(width: 10), Text(text, style: const TextStyle(fontSize: 16))])));
  }
}