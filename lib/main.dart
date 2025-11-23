import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeforyou_aws/amplifyconfiguration.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:seeforyou_aws/screens/splash_screen.dart';

// Import your models
import 'package:seeforyou_aws/models/ModelProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (handle error if file doesn't exist)
  try {
    await dotenv.load(fileName: ".env");
    safePrint('Environment variables loaded successfully');
  } catch (e) {
    safePrint('Warning: .env file not found. Using default values. Error: $e');
    // Continue anyway - app will work without .env for now
  }

  await _configureAmplify();
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();

    // Create API plugin with model provider
    final api = AmplifyAPI(
      options: APIPluginOptions(
        modelProvider: ModelProvider.instance,
      ),
    );

    // Only add auth and api plugins
    await Amplify.addPlugins([auth, api]);

    await Amplify.configure(amplifyconfig);

    safePrint('Amplify configured successfully');
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'See for Me',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: const Color(0xFFFBF9F4),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF343434),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFBF9F4),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: GoogleFonts.lato(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}