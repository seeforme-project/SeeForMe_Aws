// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
import 'package:seeforyou_aws/screens/welcome_screen.dart';

// Import models
import 'package:seeforyou_aws/models/Volunteer.dart';
import 'package:seeforyou_aws/models/ModelProvider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _isAvailable = false;
  late String _userId;
  Volunteer? _volunteer;

  Stream<GraphQLResponse<Call>>? _callSubscriptionStream;
  StreamSubscription<GraphQLResponse<Call>>? _callSubscription;

  final List<Map<String, dynamic>> _incomingCalls = [];

  final Color bgColor = const Color(0xFFFBF9F4); // ❤️ Your theme color

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initScreen() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      _userId = user.userId;
      safePrint('HomeScreen: current user id: $_userId');

      await _loadVolunteer();

      // Load existing pending calls first
      await _loadPendingCalls();

      // Then subscribe to new calls
      _subscribeToIncomingCalls();

      setState(() => _loading = false);
    } catch (e, st) {
      safePrint('HomeScreen init error: $e\n$st');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadVolunteer() async {
    try {
      final identifier = VolunteerModelIdentifier(id: _userId);
      final request = ModelQueries.get<Volunteer>(Volunteer.classType, identifier);
      final response = await Amplify.API.query(request: request).response;

      final volunteer = response.data;
      safePrint('Loaded volunteer: $volunteer, errors: ${response.errors}');

      if (volunteer != null) {
        _volunteer = volunteer;
        _isAvailable = volunteer.isAvailableNow ?? false;
      } else {
        safePrint('Volunteer record is null for userId=$_userId');
        _volunteer = null;
        _isAvailable = false;
      }
      if (mounted) setState(() {});
    } catch (e) {
      safePrint('Error loading volunteer: $e');
    }
  }

  // Load existing pending calls when screen opens
  Future<void> _loadPendingCalls() async {
    try {
      const listCallsQuery = r'''
        query ListCalls {
          listCalls(filter: {status: {eq: PENDING}}) {
            items {
              id
              blindUserId
              blindUserName
              meetingId
              status
              createdAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(document: listCallsQuery);
      final response = await Amplify.API.query(request: request).response;

      safePrint('📋 List calls response: ${response.data}');

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        final items = data['listCalls']['items'] as List;

        if (mounted) {
          setState(() {
            _incomingCalls.clear();
            for (var item in items) {
              _incomingCalls.add(Map<String, dynamic>.from(item));
            }
          });
        }
        safePrint('✅ Loaded ${_incomingCalls.length} pending calls');
      }
    } catch (e) {
      safePrint('❌ Error loading pending calls: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() => _isAvailable = !_isAvailable);

    try {
      if (_volunteer != null) {
        final updated = _volunteer!.copyWith(isAvailableNow: _isAvailable);
        final req = ModelMutations.update(updated);
        final res = await Amplify.API.mutate(request: req).response;

        safePrint('Update response: ${res.data}, errors: ${res.errors}');

        if (res.data != null) {
          await _loadVolunteer();
        }
      } else {
        // Fallback: raw GraphQL mutation
        const updateMutation = r'''
          mutation UpdateVolunteer($input: UpdateVolunteerInput!) {
            updateVolunteer(input: $input) {
              id
              name
              email
              isAvailableNow
            }
          }
        ''';

        final variables = {
          'input': {
            'id': _userId,
            'isAvailableNow': _isAvailable,
          }
        };

        final req = GraphQLRequest<String>(
          document: updateMutation,
          variables: variables,
        );

        final res = await Amplify.API.mutate(request: req).response;
        safePrint('Update (raw) response: ${res.data}, errors: ${res.errors}');
        await _loadVolunteer();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _isAvailable ? Colors.green : Colors.grey[700],
            content: Text(
              _isAvailable ? '✅ You are now AVAILABLE' : '⏸️ You are now UNAVAILABLE',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      safePrint('Error updating availability: $e');
      setState(() => _isAvailable = !_isAvailable);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to update: $e'),
          ),
        );
      }
    }
  }

  void _subscribeToIncomingCalls() {
    safePrint('🔔 Subscribing to incoming calls...');

    // 1. Create the request
    final subscriptionRequest = ModelSubscriptions.onCreate(Call.classType);

    // 2. Subscribe (This line was erroring, now it will work because we fixed the variable type)
    _callSubscriptionStream = Amplify.API.subscribe(
      subscriptionRequest,
      onEstablished: () => safePrint('✅ Subscription established'),
    );

    // 3. Listen to events
    _callSubscription = _callSubscriptionStream!.listen(
          (event) {
        safePrint('📞 Subscription event received');
        // 'event.data' is now a 'Call' object, not a String!
        final call = event.data;

        if (call != null && call.status == CallStatus.PENDING) {
          if (mounted) {
            setState(() {
              // Check for duplicates
              if (!_incomingCalls.any((c) => c['id'] == call.id)) {
                // Add to list
                _incomingCalls.insert(0, {
                  'id': call.id,
                  'blindUserId': call.blindUserId,
                  'blindUserName': call.blindUserName,
                  'meetingId': call.meetingId,
                  'status': call.status.name, // Convert Enum to String
                  'createdAt': call.createdAt.toString(),
                });
                safePrint('✅ Added new call to list: ${call.id}');
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text('📞 New call from ${call.blindUserName}'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
      onError: (error) {
        safePrint('❌ Subscription error: $error');
      },
    );
  }

  Future<void> _acceptCall(Map<String, dynamic> call) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final callId = call['id'];
      final channelName = call['meetingId'];

      safePrint('Accepting call: $callId, channel: $channelName');

      // --- CHANGE 1: MARK AS BUSY (UNAVAILABLE) ---
      await _updateAvailabilityStatus(false);

      // Update call record in DynamoDB
      const updateMutation = r'''
        mutation UpdateCall($input: UpdateCallInput!) {
          updateCall(input: $input) {
            id
            volunteerId
            volunteerName
            status
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: updateMutation,
        variables: {
          'input': {
            'id': callId,
            'volunteerId': user.userId,
            'volunteerName': _volunteer?.name ?? user.username,
            'status': 'ACCEPTED',
          }
        },
      );

      await Amplify.API.mutate(request: request).response;

      if (!mounted) return;

      // Remove from incoming calls list locally
      setState(() {
        _incomingCalls.removeWhere((c) => c['id'] == callId);
      });

      // --- CHANGE 2: NAVIGATE AND WAIT ---
      // We use 'await' here. The code below this line will ONLY run
      // after the VideoCallScreen is closed (call ended).
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            channelName: channelName,
            userName: _volunteer?.name ?? user.username,
            isBlindUser: false,
          ),
        ),
      );

      // --- CHANGE 3: MARK AS AVAILABLE AGAIN ---
      // This runs immediately after the volunteer hangs up (leaves the screen)
      if (mounted) {
        safePrint('Call ended, making volunteer available again...');
        await _updateAvailabilityStatus(true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ Call ended. You are available again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      safePrint('❌ Error accepting call: $e');
      // If it fails, try to reset status to available just in case
      _updateAvailabilityStatus(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to accept call: $e'),
          ),
        );
      }
    }
  }

  Future<void> _rejectCall(Map<String, dynamic> call) async {
    try {
      final callId = call['id'];

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
          'input': {
            'id': callId,
            'status': 'REJECTED',
          }
        },
      );

      await Amplify.API.mutate(request: request).response;

      if (mounted) {
        setState(() {
          _incomingCalls.removeWhere((c) => c['id'] == callId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Call rejected'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      safePrint('Error rejecting call: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      safePrint('Error signing out: $e');
    }
  }

  // -------------------------------------------------------------
  // UI WIDGETS
  // -------------------------------------------------------------

  Widget _buildAvailabilityCircle() {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleAvailability,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 160,
            width: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isAvailable ? Colors.green : Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: (_isAvailable ? Colors.green : Colors.redAccent)
                      .withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 6,
                )
              ],
            ),
            child: Center(
              child: Text(
                _isAvailable ? "AVAILABLE" : "UNAVAILABLE",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          _isAvailable
              ? "You are ready to accept calls"
              : "You are currently offline",
          style: TextStyle(
            fontSize: 16,
            color: _isAvailable ? Colors.green : Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),

        TextButton.icon(
          onPressed: _loadPendingCalls,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
        ),
      ],
    );
  }

  Widget _buildIncomingCallsList() {
    if (_incomingCalls.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.call, size: 70, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "No incoming calls",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              )
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _incomingCalls.length,
        itemBuilder: (context, index) {
          final call = _incomingCalls[index];
          final callerName = call["blindUserName"] ?? "Unknown Caller";
          final createdAt = call["createdAt"] ?? "";

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.15),
                child: const Icon(Icons.person, color: Colors.blue, size: 30),
              ),
              title: Text(
                callerName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    "Needs visual assistance",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (createdAt.isNotEmpty)
                    Text(
                      createdAt.length > 19 ? createdAt.substring(0, 19) : createdAt,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green, size: 28),
                    onPressed: () => _acceptCall(call),
                    tooltip: 'Accept',
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.red, size: 28),
                    onPressed: () => _rejectCall(call),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // MAIN UI
  // -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // ❤️ YOUR NEW THEME COLOR

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Volunteer Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Call counter badge
          if (_incomingCalls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_incomingCalls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _signOut,
          )
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 20),
          _buildAvailabilityCircle(),
          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Text(
                  "Incoming Calls",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildIncomingCallsList(),
        ],
      ),
    );
  }
  // Add this inside _HomeScreenState
  Future<void> _updateAvailabilityStatus(bool status) async {
    try {
      // 1. Update Local UI immediately
      setState(() {
        _isAvailable = status;
      });

      // 2. Update Backend
      if (_volunteer != null) {
        final updatedVolunteer = _volunteer!.copyWith(isAvailableNow: status);

        final request = ModelMutations.update(updatedVolunteer);
        final response = await Amplify.API.mutate(request: request).response;

        safePrint('🔄 Availability updated to $status: ${response.data?.isAvailableNow}');

        // Refresh the local volunteer object to keep versions in sync
        if (response.data != null) {
          _volunteer = response.data;
        }
      }
    } catch (e) {
      safePrint('❌ Error updating availability status: $e');
    }
  }
}