import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seeforyou_aws/logic/session_cubit.dart';

class BlindLiveScreen extends StatelessWidget {
  const BlindLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SessionCubit()..startSession(),
      child: const _SessionPageView(),
    );
  }
}

class _SessionPageView extends StatefulWidget {
  const _SessionPageView();

  @override
  State<_SessionPageView> createState() => _SessionPageViewState();
}

class _SessionPageViewState extends State<_SessionPageView>
    with WidgetsBindingObserver {
  bool _showDebug = false;

  // Gesture detection variables
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  // Handle swipe up gesture - Start online mode
  Future<void> _handleSwipeUp() async {
    final cubit = context.read<SessionCubit>();
    if (cubit.state.mode != SessionMode.idle) return;
    await cubit.startOnlineMode();
  }

  // Handle swipe down gesture - Stop/Disconnect/Offline
  Future<void> _handleSwipeDown() async {
    final cubit = context.read<SessionCubit>();

    // If currently Online, stop it.
    if (cubit.state.mode == SessionMode.online) {
      await cubit.cancelCurrentMode();
      return;
    }

    // If Idle, start Offline Mode
    if (cubit.state.mode == SessionMode.idle) {
      await cubit.startOfflineMode();
    }
  }

  // 👇 THIS WAS THE MISSING FUNCTION
  Future<void> _handleDoubleTap() async {
    final cubit = context.read<SessionCubit>();

    // If the AI is active (Online or Offline), stop it first
    if (cubit.state.mode != SessionMode.idle) {
      await cubit.cancelCurrentMode();
    } else {
      // If idle, exit the screen completely
      await cubit.stopSession();
      if (mounted) Navigator.of(context).pop();
    }
  }

  // Combined tap handler
  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel();

    if (_tapCount == 3) {
      _tapCount = 0;
      // Triple tap action: Warn user this isn't the home screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Use the Home Screen to call a volunteer"),
        ),
      );
    } else {
      _tapTimer = Timer(const Duration(milliseconds: 300), () {
        if (_tapCount == 2) {
          // Double tap action: Exit or Stop
          _handleDoubleTap();
        }
        _tapCount = 0;
      });
    }
  }

  String _getStatusText(SessionState state) {
    if (state.connecting) return "Connecting...";

    // ONLINE MODE
    if (state.mode == SessionMode.online) {
      return state.isBotSpeaking ? "AI Speaking..." : "I am Listening...";
    }

    // OFFLINE MODE
    if (state.mode == SessionMode.offline) {
      return "Analyzing...";
    }

    if (state.isError) return "Error occurred";

    // IDLE MODE
    return "Swipe UP: Online\nSwipe DOWN: Offline";
  }

  String _getInstructionText(SessionMode mode) {
    switch (mode) {
      case SessionMode.idle:
        return "Double Tap to Exit";
      case SessionMode.online:
        return "Swipe DOWN to Stop";
      case SessionMode.offline:
        return "Please wait...";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<SessionCubit, SessionState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<SessionCubit>();
          final cameraController = cubit.cameraController;

          return GestureDetector(
            // SWIPE GESTURES
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // Swipe Up
                if (state.mode == SessionMode.idle) cubit.startOnlineMode();
              } else if (details.primaryVelocity! > 0) {
                // Swipe Down
                _handleSwipeDown();
              }
            },
            // TAP GESTURES (Single, Double, Triple)
            // We use onTap instead of onDoubleTap to handle the triple tap logic manually
            onTap: _handleTap,

            child: Stack(
              children: [
                // --- LAYER 1: CAMERA PREVIEW ---
                if (state.isCameraActive &&
                    cameraController != null &&
                    cameraController.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: cameraController.value.previewSize?.height ?? 1,
                        height: cameraController.value.previewSize?.width ?? 1,
                        child: CameraPreview(cameraController),
                      ),
                    ),
                  )
                else
                  Container(color: Colors.black),

                // --- LAYER 2: DARK OVERLAY ---
                Container(color: Colors.black.withOpacity(0.6)),

                // --- LAYER 3: UI ELEMENTS ---
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getStatusText(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),

                      // SOUND WAVE ICON
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: state.isBotSpeaking
                              ? Colors.greenAccent.withOpacity(0.8)
                              : (state.mode == SessionMode.online
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.white10),
                          shape: BoxShape.circle,
                          boxShadow: state.isBotSpeaking
                              ? [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                              : [],
                        ),
                        child: Icon(
                          state.mode == SessionMode.online
                              ? Icons.graphic_eq
                              : Icons.mic_off,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 60),

                      if (state.mode == SessionMode.online)
                        const Text(
                          "I can see you.\nSay 'Hello' or ask what I see.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                    ],
                  ),
                ),

                // Instructions Overlay
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Text(
                    _getInstructionText(state.mode), // New Helper
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (state.connecting)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),

                // Debug Overlay
                if (_showDebug)
                  _buildDebugOverlay(state, cameraController, cubit),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white12,
        onPressed: () => setState(() => _showDebug = !_showDebug),
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
    );
  }

  // --- DEBUG HELPERS ---

  Widget _buildDebugOverlay(
      SessionState state,
      CameraController? controller,
      SessionCubit cubit,
      ) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.92),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Panel',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _debugButton(
                      icon: Icons.cameraswitch,
                      label: 'Switch Cam',
                      onTap: () => cubit.switchCamera(),
                    ),
                    _debugButton(
                      icon: Icons.cloud,
                      label: 'Online',
                      onTap: () => _handleSwipeUp(),
                    ),
                    _debugButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      onTap: () => _handleSwipeDown(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Mode: ${state.mode.name}',
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  'Recording: ${state.isRecording}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Bot Speaking: ${state.isBotSpeaking}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (state.error != null)
                  Text(
                    'Error: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _debugButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
      ),
    );
  }
}