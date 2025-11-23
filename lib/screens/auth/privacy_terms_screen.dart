import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeforyou_aws/screens/auth/volunteer_get_started_screen.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
    //    title: const Text('See For Me'), // As per the screenshot
      //  leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy and Terms',
              style: GoogleFonts.lato(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'To use See for Me, you agree to the following:',
              style: GoogleFonts.lato(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.camera_alt_outlined,
              text: 'See for Me can record, review, and share videos and images for safety, quality, and as further described in the Privacy Policy.',
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.lock_outline,
              text: 'The data, videos, images, and personal information I submit to See for Me may be stored and processed in the U.S.A.',
            ),
            const SizedBox(height: 32),
            _buildLinkButton(context, title: 'Terms of Service'),
            const SizedBox(height: 12),
            _buildLinkButton(context, title: 'Privacy Policy'),
            const Spacer(),
            Text(
              "By clicking 'I agree', I agree to everything above and accept the Terms of Service and Privacy Policy.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VolunteerGetStartedScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                ),
                child: const Text('I agree'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[700], size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(fontSize: 15, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkButton(BuildContext context, {required String title}) {
    return GestureDetector(
      onTap: () {
        // TODO: Add URL launcher to open actual links
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This would open the $title')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Icon(Icons.launch, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}