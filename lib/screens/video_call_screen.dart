import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:seeforyou_aws/services/agora_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userName;
  final bool isBlindUser;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.userName,
    this.isBlindUser = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int uid = 0; // Local user ID
  int? _remoteUid; // Remote user ID
  bool _isJoined = false;
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isLoading = true;
  RtcEngine? _engine;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RTC engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: AgoraService.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Enable video
    await _engine!.enableVideo();
    await _engine!.startPreview();

    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          safePrint('Successfully joined channel: ${connection.channelId}');
          setState(() {
            _isJoined = true;
            _isLoading = false;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          safePrint('Remote user $remoteUid joined');
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          safePrint('Remote user $remoteUid left channel');
          setState(() {
            _remoteUid = null;
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          safePrint('Left channel');
          setState(() {
            _isJoined = false;
            _remoteUid = null;
          });
        },
      ),
    );

    // Join channel
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
    setState(() {
      _isMicOn = !_isMicOn;
    });
  }

  void _toggleCamera() async {
    await _engine?.muteLocalVideoStream(!_isCameraOn);
    setState(() {
      _isCameraOn = !_isCameraOn;
    });
  }

  void _switchCamera() {
    _engine?.switchCamera();
  }

  Future<void> _endCall() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
  }

  // Build remote video
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
            const Icon(
              Icons.person_outline,
              color: Colors.white54,
              size: 100,
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for ${widget.isBlindUser ? 'volunteer' : 'caller'} to join...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
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
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            _remoteVideo(),

            // Local video (picture-in-picture)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isJoined
                      ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                      : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Top info bar
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.isBlindUser
                          ? 'Visual Assistance'
                          : 'Helping Caller',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMicOn ? Icons.mic : Icons.mic_off,
                    onPressed: _toggleMic,
                    backgroundColor:
                    _isMicOn ? Colors.white24 : Colors.red,
                  ),
                  _buildControlButton(
                    icon: _isCameraOn
                        ? Icons.videocam
                        : Icons.videocam_off,
                    onPressed: _toggleCamera,
                    backgroundColor:
                    _isCameraOn ? Colors.white24 : Colors.red,
                  ),
                  _buildControlButton(
                    icon: Icons.flip_camera_ios,
                    onPressed: _switchCamera,
                    backgroundColor: Colors.white24,
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        iconSize: 32,
        onPressed: onPressed,
      ),
    );
  }
}