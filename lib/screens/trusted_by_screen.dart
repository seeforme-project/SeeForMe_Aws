import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

class TrustedByScreen extends StatefulWidget {
  final String volunteerId;
  const TrustedByScreen({super.key, required this.volunteerId});

  @override
  State<TrustedByScreen> createState() => _TrustedByScreenState();
}

class _TrustedByScreenState extends State<TrustedByScreen> {
  List<dynamic> _blindUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrustedBy();
  }

  Future<void> _fetchTrustedBy() async {
    try {
      // Find Blind Users where trustedVolunteerIds CONTAINS this volunteerId
      // Note: trustedVolunteerIds is a List of Strings in DynamoDB
      const String query = r'''
        query ListTrustedBy($volId: String!) {
          listBlindUsers(filter: {trustedVolunteerIds: {contains: $volId}}) {
            items {
              id
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {'volId': widget.volunteerId},
        // IMPORTANT: BlindUser table is public (API Key), not UserPool.
        // We must explicitly use API Key to read it.
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        setState(() {
          _blindUsers = data['listBlindUsers']['items'];
          _isLoading = false;
        });

        safePrint("Found ${_blindUsers.length} trusted users.");
      } else if (response.errors.isNotEmpty) {
        safePrint("Errors: ${response.errors}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      safePrint("Error fetching trusted users: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trusted By")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blindUsers.isEmpty
          ? const Center(child: Text("No blind users have added you yet."))
          : ListView.builder(
        itemCount: _blindUsers.length,
        itemBuilder: (context, index) {
          final user = _blindUsers[index];
          // Display ID or Name if available
          final displayId = user['id'].toString().substring(0, 8);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.accessibility, color: Colors.white),
              ),
              title: Text("Blind User: $displayId..."),
              subtitle: const Text("Has added you to their trusted list"),
              trailing: const Icon(Icons.star, color: Colors.amber),
            ),
          );
        },
      ),
    );
  }
}