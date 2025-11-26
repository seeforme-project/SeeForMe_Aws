import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:seeforyou_aws/services/agora_service.dart';

import 'feedback_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userName;
  final bool isBlindUser;
  final String callId;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.userName,
    this.isBlindUser = false,
    required this.callId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int uid = 0;
  int? _remoteUid;
  bool _isJoined = false;
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isLoading = true;
  RtcEngine? _engine;
  bool _callEnded = false;
  String? _connectedVolunteerId;

  Timer? _waitTimer;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initAgora();


    if (widget.isBlindUser) {
      _startWaitingLogic();
    }
  }

  Future<void> _startWaitingLogic() async {

    await _flutterTts.setLanguage("en-US");


    await _flutterTts.speak("Waiting for a volunteer to join the call. Please hold.");

    _waitTimer = Timer(const Duration(seconds: 60), () async {
      if (_remoteUid == null && mounted && !_callEnded) {
        safePrint("❌ Timeout: No volunteer joined.");
        await _flutterTts.speak("No volunteer joined within the time limit. Ending call.");

        await Future.delayed(const Duration(seconds: 4));
        _endCall();
      }
    });
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: AgoraService.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine!.enableVideo();
    await _engine!.startPreview();

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          safePrint('Successfully joined channel: ${connection.channelId}');
          if (mounted) setState(() { _isJoined = true; _isLoading = false; });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          safePrint('Remote user $remoteUid joined');

          if (mounted) {
            setState(() => _remoteUid = remoteUid);
            // --- NEW: Volunteer joined, cancel timer & notify ---
            _waitTimer?.cancel();
            if (widget.isBlindUser) {
              _flutterTts.stop();
              _flutterTts.speak("Volunteer has joined.");
              _fetchVolunteerId();
            }
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          safePrint('Remote user left. Reason: $reason');
          if (reason == UserOfflineReasonType.userOfflineQuit) {
            safePrint('Remote user hung up. Ending local call...');
            _endCall();
          } else {
            if (mounted) setState(() => _remoteUid = null);
          }
        },
      ),
    );

    await _engine!.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _toggleMic() async {
    await _engine?.muteLocalAudioStream(!_isMicOn);
    setState(() => _isMicOn = !_isMicOn);
  }

  void _toggleCamera() async {
    await _engine?.muteLocalVideoStream(!_isCameraOn);
    setState(() => _isCameraOn = !_isCameraOn);
  }

  void _switchCamera() {
    _engine?.switchCamera();
  }

  Future<void> _fetchVolunteerId() async {
    if (!widget.isBlindUser) return;
    if (_connectedVolunteerId != null) return;

    for (int i = 0; i < 5; i++) {
      try {
        const String query = r'''
            query GetCall($id: ID!) {
              getCall(id: $id) {
                id
                volunteerId
              }
            }
          ''';
        final request = GraphQLRequest<String>(
          document: query,
          variables: {'id': widget.callId},
          authorizationMode: APIAuthorizationType.apiKey,
        );
        final response = await Amplify.API.query(request: request).response;

        if (response.data != null) {
          final data = jsonDecode(response.data!);
          if (data['getCall'] != null) {
            final volId = data['getCall']['volunteerId'];
            if (volId != null && volId.toString().isNotEmpty) {
              _connectedVolunteerId = volId.toString();
              safePrint("✅ SUCCESS: Found Volunteer ID: $_connectedVolunteerId");
              return;
            }
          }
        }
      } catch (e) {
        safePrint("❌ Exception fetching volunteer ID: $e");
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    _callEnded = true;

    _waitTimer?.cancel();

    await _flutterTts.stop();

    if (widget.isBlindUser && _connectedVolunteerId == null) {
      await _fetchVolunteerId();
    }

    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (e) {
      safePrint("Error releasing engine: $e");
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FeedbackScreen(
            callId: widget.callId,
            isBlindUser: widget.isBlindUser,
            volunteerId: _connectedVolunteerId,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _flutterTts.stop();
    if (!_callEnded) {
      _engine?.leaveChannel();
      _engine?.release();
    }
    super.dispose();
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, color: Colors.white54, size: 100),
            const SizedBox(height: 16),
            Text(
              widget.isBlindUser ? 'Waiting for volunteer...' : 'Waiting for user...',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
        child: Stack(
          children: [
            _remoteVideo(),
            Positioned(
              top: 16, right: 16,
              child: Container(
                width: 120, height: 160,
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isJoined
                      ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine!, canvas: const VideoCanvas(uid: 0)))
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              bottom: 32, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(icon: _isMicOn ? Icons.mic : Icons.mic_off, onPressed: _toggleMic, backgroundColor: _isMicOn ? Colors.white24 : Colors.red),
                  _buildControlButton(icon: _isCameraOn ? Icons.videocam : Icons.videocam_off, onPressed: _toggleCamera, backgroundColor: _isCameraOn ? Colors.white24 : Colors.red),
                  _buildControlButton(icon: Icons.flip_camera_ios, onPressed: _switchCamera, backgroundColor: Colors.white24),
                  _buildControlButton(icon: Icons.call_end, onPressed: _endCall, backgroundColor: Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed, required Color backgroundColor}) {
    return Container(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.white), iconSize: 32, onPressed: onPressed),
    );
  }
}