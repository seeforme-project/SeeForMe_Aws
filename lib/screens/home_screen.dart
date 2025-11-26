
import 'dart:async';
import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
import 'package:seeforyou_aws/screens/welcome_screen.dart';


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

  final Color bgColor = const Color(0xFFFBF9F4);
  StreamSubscription<GraphQLResponse<Call>>? _updateSubscription;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _updateSubscription?.cancel();
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

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        final items = data['listCalls']['items'] as List;

        if (mounted) {
          setState(() {
            _incomingCalls.clear();
            final now = DateTime.now();

            for (var item in items) {
              // Check if the call is older than 5 minutes
              if (item['createdAt'] != null) {
                final createdAt = DateTime.parse(item['createdAt']);
                final difference = now.difference(createdAt).inMinutes;

                // If call is older than 5 minutes, skip it (ghost call)
                if (difference > 5) continue;
              }

              _incomingCalls.add(Map<String, dynamic>.from(item));
            }
          });
        }
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
    safePrint('🔔 Subscribing to Call Events...');

    // ------------------------------------------------------
    // SUBSCRIPTION 1: NEW CALLS (onCreate)
    // ------------------------------------------------------
    final createReq = ModelSubscriptions.onCreate(Call.classType);
    _callSubscriptionStream = Amplify.API.subscribe(createReq, onEstablished: () => safePrint('✅ Create Sub Established'));

    _callSubscription = _callSubscriptionStream!.listen((event) {
      final call = event.data;
      if (call != null && call.status == CallStatus.PENDING) {
        // 5-Minute Filter Rule
        if (call.createdAt != null) {
          final created = DateTime.parse(call.createdAt.toString());
          if (DateTime.now().difference(created).inMinutes > 5) return;
        }

        if (mounted) {
          setState(() {
            if (!_incomingCalls.any((c) => c['id'] == call.id)) {
              _incomingCalls.insert(0, {
                'id': call.id,
                'blindUserId': call.blindUserId,
                'blindUserName': call.blindUserName,
                'meetingId': call.meetingId,
                'status': call.status.name,
                'createdAt': call.createdAt.toString(),
              });
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.green, content: Text('📞 New call from ${call.blindUserName}')),
          );
        }
      }
    });

    // ------------------------------------------------------
    // SUBSCRIPTION 2: UPDATES (onUpdate) - REMOVES CANCELLED CALLS
    // ------------------------------------------------------
    final updateReq = ModelSubscriptions.onUpdate(Call.classType);
    final updateStream = Amplify.API.subscribe(updateReq, onEstablished: () => safePrint('✅ Update Sub Established'));

    _updateSubscription = updateStream.listen((event) {
      final call = event.data;
      if (call != null) {
        safePrint('🔄 Call Update Received: ${call.id} is now ${call.status}');

        // If status is NOT pending (i.e., CANCELLED, ACCEPTED, COMPLETED), remove it
        if (call.status != CallStatus.PENDING) {
          if (mounted) {
            setState(() {
              _incomingCalls.removeWhere((c) => c['id'] == call.id);
            });
          }
        }
      }
    });
  }

  Future<void> _acceptCall(Map<String, dynamic> call) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final callId = call['id'];
      final channelName = call['meetingId'];

      safePrint('Accepting call: $callId, channel: $channelName');

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

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            channelName: channelName,
            userName: _volunteer?.name ?? user.username,
            isBlindUser: false,
            callId: callId,
          ),
        ),
      );

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
      backgroundColor: bgColor,

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
          if (_isAvailable && _incomingCalls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: Text('${_incomingCalls.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
            ),
          IconButton(icon: const Icon(Icons.logout, color: Colors.black87), onPressed: _signOut)
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 20),
          _buildAvailabilityCircle(),
          const SizedBox(height: 25),

          if (!_isAvailable) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      "You are currently offline",
                      style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tap the red circle above to go Online\nand receive calls.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Text(
                    "Incoming Calls",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildIncomingCallsList(),
          ],
        ],
      ),
    );
  }

  Future<void> _updateAvailabilityStatus(bool status) async {
    try {
      setState(() {
        _isAvailable = status;
      });

      if (_volunteer != null) {
        final updatedVolunteer = _volunteer!.copyWith(isAvailableNow: status);

        final request = ModelMutations.update(updatedVolunteer);
        final response = await Amplify.API.mutate(request: request).response;

        safePrint('🔄 Availability updated to $status: ${response.data?.isAvailableNow}');

        if (response.data != null) {
          _volunteer = response.data;
        }
      }
    } catch (e) {
      safePrint('❌ Error updating availability status: $e');
    }
  }
}