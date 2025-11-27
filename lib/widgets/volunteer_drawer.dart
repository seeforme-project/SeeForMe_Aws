import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:seeforyou_aws/models/Volunteer.dart';
import 'package:seeforyou_aws/screens/welcome_screen.dart';
import 'package:seeforyou_aws/screens/notification_screen.dart';
import 'package:seeforyou_aws/screens/volunteer_profile_screen.dart';
import 'package:seeforyou_aws/screens/trusted_by_screen.dart';

class VolunteerDrawer extends StatelessWidget {
  final Volunteer? volunteer;
  final String userId;

  const VolunteerDrawer({super.key, required this.volunteer, required this.userId});

  Future<void> _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF093B75)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFF093B75)),
            ),
            accountName: Text(volunteer?.name ?? "Volunteer"),
            accountEmail: Text(volunteer?.email ?? "Loading..."),
          ),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("My Profile"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerProfileScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text("Trusted By"),
            subtitle: const Text("Blind users who trust you"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => TrustedByScreen(volunteerId: userId)));
            },
          ),

          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text("Safety & Warnings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen(userId: userId)));
            },
          ),

          const Spacer(),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}