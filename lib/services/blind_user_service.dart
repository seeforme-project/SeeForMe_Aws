import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';

class BlindUserService {

  // 1. Get Hardware Device ID
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String uuid = "unknown_device";

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        uuid = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        uuid = iosInfo.identifierForVendor ?? "ios_unknown";
      }

      uuid = uuid.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_');
      safePrint("📱 Hardware Blind Device ID: $uuid");
      await _createBlindUserRecord(uuid);

    } catch (e) {
      safePrint("Error getting device info: $e");
    }
    return uuid;
  }

  // 2. Silently create the record in DynamoDB
  static Future<void> _createBlindUserRecord(String uuid) async {
    try {
      final exists = await _fetchBlindUser(uuid);
      if (exists != null) return;

      const mutation = r'''
        mutation CreateBlindUser($input: CreateBlindUserInput!) {
          createBlindUser(input: $input) {
            id
            trustedVolunteerIds
          }
        }
      ''';

      await Amplify.API.mutate(
          request: GraphQLRequest<String>(
            document: mutation,
            variables: {
              'input': { 'id': uuid, 'trustedVolunteerIds': [] }
            },
            authorizationMode: APIAuthorizationType.apiKey,
          )
      ).response;
      safePrint("🆕 Created new Blind User Record in DB");
    } catch (e) {
      safePrint("User creation check: $e");
    }
  }

  // 3. Add a Volunteer to Trusted List
  static Future<void> addTrustedVolunteer(String volunteerId) async {
    final userId = await getDeviceId();
    try {
      final currentUser = await _fetchBlindUser(userId);
      List<String> currentList = [];

      if (currentUser != null && currentUser['trustedVolunteerIds'] != null) {
        currentList = List<String>.from(currentUser['trustedVolunteerIds']);
      }

      if (!currentList.contains(volunteerId)) {
        currentList.add(volunteerId);

        const mutation = r'''
          mutation UpdateBlindUser($input: UpdateBlindUserInput!) {
            updateBlindUser(input: $input) {
              id
              trustedVolunteerIds
            }
          }
        ''';

        final res = await Amplify.API.mutate(
            request: GraphQLRequest<String>(
              document: mutation,
              variables: {
                'input': { 'id': userId, 'trustedVolunteerIds': currentList }
              },
              authorizationMode: APIAuthorizationType.apiKey,
            )
        ).response;

        if (res.hasErrors) {
          safePrint("❌ Error updating trusted list: ${res.errors}");
        }
      }
    } catch (e) {
      safePrint("Error adding trusted volunteer: $e");
    }
  }

  // 4. Fetch User Record
  static Future<Map<String, dynamic>?> _fetchBlindUser(String userId) async {
    const query = r'''
      query GetBlindUser($id: ID!) {
        getBlindUser(id: $id) {
          id
          trustedVolunteerIds
        }
      }
    ''';

    final response = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: query,
          variables: {'id': userId},
          authorizationMode: APIAuthorizationType.apiKey,
        )
    ).response;

    if (response.data != null) {
      final data = jsonDecode(response.data!);
      return data['getBlindUser'];
    }
    return null;
  }

  // 5. Emergency Logic
  static Future<String?> findAvailableTrustedVolunteer() async {
    final userId = await getDeviceId();
    final userRecord = await _fetchBlindUser(userId);

    if (userRecord == null || userRecord['trustedVolunteerIds'] == null) {
      return null;
    }

    List<dynamic> trustedIds = userRecord['trustedVolunteerIds'];
    if (trustedIds.isEmpty) return null;

    for (String volId in trustedIds) {
      if (await _isVolunteerAvailable(volId)) {
        return volId;
      }
    }
    return null;
  }

  static Future<bool> _isVolunteerAvailable(String volunteerId) async {
    try {
      const query = r'''
        query GetVolunteer($id: ID!) {
          getVolunteer(id: $id) {
            isAvailableNow
          }
        }
      ''';

      final response = await Amplify.API.query(
          request: GraphQLRequest<String>(
            document: query,
            variables: {'id': volunteerId},
            authorizationMode: APIAuthorizationType.apiKey,
          )
      ).response;

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        if (data['getVolunteer'] == null) return false;
        return data['getVolunteer']['isAvailableNow'] ?? false;
      }
      return false;
    } catch(e) {
      return false;
    }
  }

  static Future<bool> isVolunteerAlreadyTrusted(String volunteerId) async {
    try {
      final userId = await getDeviceId();
      final userRecord = await _fetchBlindUser(userId);

      if (userRecord != null && userRecord['trustedVolunteerIds'] != null) {
        List<dynamic> trustedList = userRecord['trustedVolunteerIds'];
        return trustedList.contains(volunteerId);
      }
    } catch (e) {
      safePrint("Error checking trust status: $e");
    }
    return false;
  }

  // --- UPDATED STATUS CHECK ---
  static Future<Map<String, dynamic>> checkUserStatus() async {
    final deviceId = await getDeviceId();

    try {
      const String query = r'''
        query GetBlindUser($id: ID!) {
          getBlindUser(id: $id) {
            id
            isBanned
            adminWarningMessage
            adminWarningAcknowledged
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: query,
        variables: {'id': deviceId},
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = jsonDecode(response.data!);
        if (data['getBlindUser'] != null) {
          return data['getBlindUser'];
        }
      }
    } catch (e) {
      safePrint("Error checking user status: $e");
    }

    return {
      'isBanned': false,
      'adminWarningMessage': null,
      'adminWarningAcknowledged': true
    };
  }

  // --- UPDATED CLEAR WARNING ---
  static Future<bool> clearWarningMessage() async {
    final deviceId = await getDeviceId();
    safePrint("Attempting to acknowledge warning for: $deviceId");

    try {
      // Sets boolean to true instead of deleting message
      const String mutation = r'''
        mutation AcknowledgeWarning($id: ID!) {
          updateBlindUser(input: {
            id: $id, 
            adminWarningAcknowledged: true
          }) {
            id
            adminWarningAcknowledged
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutation,
        variables: {'id': deviceId},
        authorizationMode: APIAuthorizationType.apiKey,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint("❌ Error acknowledging warning: ${response.errors}");
        return false;
      }

      safePrint("✅ Warning acknowledged successfully.");
      return true;
    } catch (e) {
      safePrint("❌ Exception acknowledging warning: $e");
      return false;
    }
  }
}