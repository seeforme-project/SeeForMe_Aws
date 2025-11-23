import 'package:flutter_dotenv/flutter_dotenv.dart';

class AgoraService {
  static String get appId => dotenv.env['AGORA_APP_ID'] ?? '';

  // Generate unique channel name based on timestamp
  static String generateChannelName() {
    return 'call_${DateTime.now().millisecondsSinceEpoch}';
  }

  // For production, you would generate token from backend
  // For testing, use null (works without token in test mode)
  static String? getToken() {
    return null; // null works for testing
  }
}