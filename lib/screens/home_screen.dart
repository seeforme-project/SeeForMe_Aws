import 'dart:async';
import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:seeforyou_aws/screens/video_call_screen.dart';
import 'package:seeforyou_aws/screens/welcome_screen.dart';
import 'package:seeforyou_aws/screens/notification_screen.dart';
import 'package:seeforyou_aws/widgets/volunteer_drawer.dart';

import 'package:seeforyou_aws/models/Volunteer.dart';
import 'package:seeforyou_aws/models/ModelProvider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Change to nullable to prevent LateError, though we handle loading state now
  String? _userId;
  bool _loading = true;
  bool _isAvailable = false;
  Volunteer? _volunteer;

  bool _hasUnreadNotifications = false;
  int _unreadCount = 0;

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
      await _checkNotifications();
      await _loadPendingCalls();
      _subscribeToIncomingCalls();

    } catch (e) {
      safePrint('HomeScreen init error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkNotifications() async {
    if (_userId == null) return;
    try {
      const String query = r'''
        query CheckUnread($userId: ID!) {
          listNotifications(filter: {userId: {eq: $userId}, isRead: {eq: false}}) {
            items { id }
          }
        }
      ''';
      final request = GraphQLRequest<String>(document: query, variables: {'userId': _userId!});
      final res = await Amplify.API.query(request: request).response;
      if (res.data != null) {
        final items = jsonDecode(res.data!)['listNotifications']['items'] as List;
        if (mounted) {
          setState(() {
            _unreadCount = items.length;
            _hasUnreadNotifications = items.isNotEmpty;
          });
        }
      }
    } catch(e) { safePrint("Error checking notifications: $e"); }
  }

  Future<void> _handleNotificationClick() async {
    if (_userId == null) return;
    await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotificationScreen(userId: _userId!))
    );
    await _checkNotifications();
  }

  Future<void> _loadVolunteer() async {
    if (_userId == null) return;
    try {
      final identifier = VolunteerModelIdentifier(id: _userId!);
      final request = ModelQueries.get<Volunteer>(Volunteer.classType, identifier);
      final response = await Amplify.API.query(request: request).response;

      final volunteer = response.data;
      if (volunteer != null) {
        // BAN CHECK
        if (volunteer.isBanned == true) {
          await Amplify.Auth.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(backgroundColor: Colors.red, content: Text("Your account has been suspended.")),
            );
          }
          return;
        }

        _volunteer = volunteer;
        _isAvailable = volunteer.isAvailableNow ?? false;
      }
      if (mounted) setState(() {});
    } catch (e) {
      safePrint('Error loading volunteer: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    if (_volunteer == null) return;

    // 1. Optimistically update UI
    setState(() => _isAvailable = !_isAvailable);

    try {
      // 2. Use RAW GraphQL to update ONLY isAvailableNow.
      // This prevents 'Unauthorized' errors on isBanned/owner fields.
      const String mutation = r'''
        mutation UpdateAvailability($id: ID!, $status: Boolean!) {
          updateVolunteer(input: {id: $id, isAvailableNow: $status}) {
            id
            isAvailableNow
            name
            email
            isBanned
            warningCount
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {
          'id': _volunteer!.id,
          'status': _isAvailable,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint("Update Errors: ${response.errors}");
        // Revert UI if failed
        setState(() => _isAvailable = !_isAvailable);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text("Failed: ${response.errors.first.message}")
          ));
        }
      } else {
        // Success: Update local model with response
        final data = jsonDecode(response.data!);
        // We manually update the local object to keep it in sync
        if (data['updateVolunteer'] != null) {
          // We don't need to rebuild the whole object, just know it succeeded
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _isAvailable ? Colors.green : Colors.grey[700],
                content: Text(_isAvailable ? '✅ You are now AVAILABLE' : '⏸️ You are now UNAVAILABLE', style: const TextStyle(fontWeight: FontWeight.bold)),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      }
    } catch (e) {
      safePrint('Error updating availability: $e');
      setState(() => _isAvailable = !_isAvailable);
    }
  }

  // ... [Keep _loadPendingCalls, _subscribeToIncomingCalls, _acceptCall, _rejectCall, _updateAvailabilityStatus EXACTLY AS THEY WERE] ...
  // Assuming these are unchanged from previous working versions.
  // I will include _loadPendingCalls and _updateAvailabilityStatus stub for context, paste logic back if needed.

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
              if (item['createdAt'] != null) {
                final createdAt = DateTime.parse(item['createdAt']);
                final difference = now.difference(createdAt).inMinutes;
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

  void _subscribeToIncomingCalls() {
    safePrint('🔔 Subscribing to Call Events...');
    final createReq = ModelSubscriptions.onCreate(Call.classType);
    _callSubscriptionStream = Amplify.API.subscribe(createReq, onEstablished: () => safePrint('✅ Create Sub Established'));

    _callSubscription = _callSubscriptionStream!.listen((event) {
      final call = event.data;
      if (call != null && call.status == CallStatus.PENDING) {
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

    final updateReq = ModelSubscriptions.onUpdate(Call.classType);
    final updateStream = Amplify.API.subscribe(updateReq, onEstablished: () => safePrint('✅ Update Sub Established'));

    _updateSubscription = updateStream.listen((event) {
      final call = event.data;
      if (call != null) {
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

      await _updateAvailabilityStatus(false);

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
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Failed to accept call: $e')),
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
        variables: {'input': {'id': callId, 'status': 'REJECTED'}},
      );

      await Amplify.API.mutate(request: request).response;

      if (mounted) {
        setState(() {
          _incomingCalls.removeWhere((c) => c['id'] == callId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.orange, content: Text('Call rejected'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      safePrint('Error rejecting call: $e');
    }
  }

  Future<void> _updateAvailabilityStatus(bool status) async {
    // Used when accepting/ending calls
    try {
      setState(() => _isAvailable = status);
      if (_volunteer != null) {
        const String mutation = r'''
          mutation UpdateAvailability($id: ID!, $status: Boolean!) {
            updateVolunteer(input: {id: $id, isAvailableNow: $status}) {
              id
              isAvailableNow
            }
          }
        ''';

        await Amplify.API.mutate(
            request: GraphQLRequest<String>(
                document: mutation,
                variables: {'id': _volunteer!.id, 'status': status}
            )
        ).response;
      }
    } catch (e) {
      safePrint('❌ Error updating availability status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. PREVENT CRASH: If loading, show spinner and DO NOT build Drawer yet
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBF9F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Safe to build full UI
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: _handleNotificationClick,
              ),
              if (_hasUnreadNotifications)
                Positioned(
                  right: 11, top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),

      // Drawer is safe because _userId and _volunteer are loaded
      drawer: VolunteerDrawer(volunteer: _volunteer, userId: _userId!),

      body: Column(
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

  // --- UI HELPERS ---
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
                  color: (_isAvailable ? Colors.green : Colors.redAccent).withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 6,
                )
              ],
            ),
            child: Center(
              child: Text(
                _isAvailable ? "AVAILABLE" : "UNAVAILABLE",
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isAvailable ? "You are ready to accept calls" : "You are currently offline",
          style: TextStyle(fontSize: 16, color: _isAvailable ? Colors.green : Colors.redAccent, fontWeight: FontWeight.w600),
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
              Text("No incoming calls", style: TextStyle(color: Colors.grey, fontSize: 16))
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.15),
                child: const Icon(Icons.person, color: Colors.blue, size: 30),
              ),
              title: Text(callerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text("Needs visual assistance", style: TextStyle(fontSize: 14, color: Colors.black87)),
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
}