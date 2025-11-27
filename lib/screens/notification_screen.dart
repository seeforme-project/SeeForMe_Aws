import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      const String query = r'''
        query ListMyNotifications($userId: ID!) {
          listNotifications(filter: {userId: {eq: $userId}}) {
            items {
              id
              title
              message
              type
              isRead
              createdAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {'userId': widget.userId},
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        final items = data['listNotifications']['items'] as List;

        // Sort newest first
        items.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

        setState(() {
          _notifications = items;
          _isLoading = false;
        });

        // MARK UNREAD AS READ
        _markAsRead(items);
      }
    } catch (e) {
      safePrint("Error fetching notifications: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(List<dynamic> items) async {
    const String mutation = r'''
      mutation MarkRead($id: ID!) {
        updateNotification(input: {id: $id, isRead: true}) { id }
      }
    ''';

    for (var item in items) {
      if (item['isRead'] == false) {
        try {
          final req = GraphQLRequest<String>(
              document: mutation,
              variables: {'id': item['id']}
          );
          await Amplify.API.mutate(request: req).response;
        } catch(e) {
          safePrint("Error marking read: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications", style: GoogleFonts.lato(color: Colors.black)),
        backgroundColor: const Color(0xFFFBF9F4),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(child: Text("No notifications", style: GoogleFonts.lato(fontSize: 16)))
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final note = _notifications[index];
          final isWarning = note['type'] == 'WARNING' || note['type'] == 'BAN_NOTICE';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isWarning ? Colors.red[50] : Colors.white,
            child: ListTile(
              leading: Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
                color: isWarning ? Colors.red : Colors.blue,
                size: 32,
              ),
              title: Text(note['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(note['message']),
                  const SizedBox(height: 4),
                  Text(
                    note['createdAt'].toString().split('T')[0],
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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