import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:seeforyou_aws/models/ModelProvider.dart';

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Volunteer? _volunteer;
  final _formKey = GlobalKey<FormState>();

  // Profile Controllers
  final TextEditingController _nameController = TextEditingController();

  // Default to Male, but we will update this from DB
  String _selectedGender = 'Male';
  // The exact list of options available
  final List<String> _genderOptions = ["Male", "Female", "Other"];

  // Password Controllers
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // Helper to capitalize first letter (fixes "female" vs "Female" crash)
  String _capitalize(String s) {
    if (s.isEmpty) return "";
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final identifier = VolunteerModelIdentifier(id: user.userId);
      final request = ModelQueries.get<Volunteer>(Volunteer.classType, identifier);
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        _volunteer = response.data!;
        _nameController.text = _volunteer!.name;

        // FIX: Ensure the value from DB exists in our list
        String dbGender = _capitalize(_volunteer!.gender);

        if (_genderOptions.contains(dbGender)) {
          _selectedGender = dbGender;
        } else {
          _selectedGender = "Other"; // Fallback if data is weird
        }
      }
    } catch (e) {
      safePrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... inside _VolunteerProfileScreenState ...

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      if (_volunteer != null) {
        // Use RAW Mutation to update ONLY name and gender
        const String mutation = r'''
          mutation UpdateProfile($id: ID!, $name: String!, $gender: String!) {
            updateVolunteer(input: {id: $id, name: $name, gender: $gender}) {
              id
              name
              gender
              email
              isAvailableNow
              warningCount
              isBanned
            }
          }
        ''';

        final request = GraphQLRequest<String>(
          document: mutation,
          variables: {
            'id': _volunteer!.id,
            'name': _nameController.text.trim(),
            'gender': _selectedGender,
          },
        );

        final response = await Amplify.API.mutate(request: request).response;

        if (response.hasErrors) {
          throw Exception(response.errors.first.message);
        }

        // Update local state manually since we aren't using ModelMutations
        final data = jsonDecode(response.data!);
        final updatedData = data['updateVolunteer'];

        setState(() {
          // Reconstruct volunteer from JSON response or just update fields
          _volunteer = _volunteer!.copyWith(
              name: updatedData['name'],
              gender: updatedData['gender']
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      safePrint("Save Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPassController.text.isEmpty || _newPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill both password fields")));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await Amplify.Auth.updatePassword(
        oldPassword: _oldPassController.text,
        newPassword: _newPassController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Password changed successfully")));
        _oldPassController.clear();
        _newPassController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Failed: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _selectedGender = v!),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF093B75),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const Divider(height: 50, thickness: 2),
              const Text("Change Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _oldPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Current Password", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _changePassword,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text("Update Password"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}