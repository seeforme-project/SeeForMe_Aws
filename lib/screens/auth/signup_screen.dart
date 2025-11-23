// lib/screens/auth/signup_screen.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeforyou_aws/screens/auth/confirm_signup_screen.dart';
import 'package:seeforyou_aws/screens/auth/login_screen.dart';
import '../../models/Volunteer.dart';
import '../home_screen.dart';
import '../onboarding/set_availability_screen.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- Sign Up Function ----------------
  Future<void> _signUpUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Sign up the user with Cognito
      final signUpResult = await Amplify.Auth.signUp(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: _emailController.text.trim(), CognitoUserAttributeKey.name: _nameController.text.trim(), // Add this
            CognitoUserAttributeKey.gender: _selectedGender!, // Add this// ✅ correct key type
          },
        ),

      );

      if (signUpResult.isSignUpComplete) {
        // 2. Sign in the user
        await _signInUser();
      } else {
        // If confirmation required, go to confirm signup screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConfirmSignUpScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------- Sign In Function ----------------
  Future<void> _signInUser() async {
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();

        // Create Volunteer object in backend if not exists
        final volunteerIdentifier = VolunteerModelIdentifier(id: user.userId);

        // Check if Volunteer already exists
        final getRequest = ModelQueries.get<Volunteer>(
          Volunteer.classType,
          volunteerIdentifier,
        );

        final getResponse = await Amplify.API.query(request: getRequest).response;
        var volunteer = getResponse.data;

        if (volunteer == null) {
          // Create new Volunteer
          volunteer = Volunteer(
            id: user.userId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            gender: _selectedGender!,
          );

          final createRequest = ModelMutations.create(volunteer);
          await Amplify.API.mutate(request: createRequest).response;
        }

        // Navigate based on availability schedule
        if (!mounted) return;
        if (volunteer.availabilitySchedule == null || volunteer.availabilitySchedule!.isEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SetAvailabilityScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Volunteer Account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => (value?.length ?? 0) < 8
                        ? 'Password must be at least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text('Gender',
                      style: GoogleFonts.lato(
                          color: Colors.grey[700], fontSize: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Male'),
                          value: 'male',
                          groupValue: _selectedGender,
                          onChanged: (value) =>
                              setState(() => _selectedGender = value),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Female'),
                          value: 'female',
                          groupValue: _selectedGender,
                          onChanged: (value) =>
                              setState(() => _selectedGender = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUpUser,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF)),
                    child: _isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white))
                        : const Text('Create Account'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Already have an account? Log In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
