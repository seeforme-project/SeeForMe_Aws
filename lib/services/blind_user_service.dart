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
        // Combine Brand + Model + Build ID to make it more unique on Android
        // Example: samsung_SM-G960F_UP1A.231005.007
        uuid = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        // Identifier for Vendor is unique to the device for your app
        uuid = iosInfo.identifierForVendor ?? "ios_unknown";
      }

      // Sanitize ID (remove spaces and special chars)
      uuid = uuid.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_');

      safePrint("📱 Hardware Blind Device ID: $uuid");

      // Ensure DB record exists
      await _createBlindUserRecord(uuid);

    } catch (e) {
      safePrint("Error getting device info: $e");
    }
    return uuid;
  }

  // 2. Silently create the record in DynamoDB
  static Future<void> _createBlindUserRecord(String uuid) async {
    try {
      // Check if user already exists to prevent errors
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
    safePrint("🔵 Attempting to link Volunteer: $volunteerId to User: $userId");

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
        } else {
          safePrint("✅ Success! Volunteer $volunteerId added to trusted list.");
        }
      } else {
        safePrint("ℹ️ Volunteer already in trusted list.");
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
        // Check if the list contains the ID
        return trustedList.contains(volunteerId);
      }
    } catch (e) {
      safePrint("Error checking trust status: $e");
    }
    return false;
  }
}