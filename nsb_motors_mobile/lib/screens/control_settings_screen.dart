import 'package:flutter/material.dart';
import '../config/cloud_api_config.dart';
import '../theme/leon_theme.dart';
import '../widgets/leon/leon_brand_header.dart';

class ControlSettingsScreen extends StatelessWidget {
  const ControlSettingsScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LeonColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LeonBrandHeader(
                title: 'Settings',
                subtitle: 'NSBMotors Ug · ${CloudApiConfig.baseUrl}',
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
