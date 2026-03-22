import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_sejour/pages/edit_profile_page.dart';
import 'package:projet_sejour/services/user_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _locationTracking = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications_enabled') ?? true;
      _locationTracking = prefs.getBool('location_tracking_enabled') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() {
      _pushNotifications = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', value);
  }

  Future<void> _toggleLocationTracking(bool value) async {
    setState(() {
      _locationTracking = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_tracking_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Account Section
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: Icon(Icons.person_outline, color: colorScheme.primary),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              final userService = UserService();
              final profile = await userService.getUserProfile();
              
              if (context.mounted) {
                Navigator.pop(context); // close loader
                if (profile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfilePage(profile: profile)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not load profile.')),
                  );
                }
              }
            },
          ),
          
          const Divider(),

          // Preferences Section
          const _SectionHeader(title: 'Preferences'),
          SwitchListTile(
            secondary: Icon(Icons.notifications_active_outlined, color: colorScheme.primary),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive important updates and alerts'),
            value: _pushNotifications,
            activeColor: colorScheme.primary,
            onChanged: _togglePushNotifications,
          ),

          const Divider(),

          // Privacy Section
          const _SectionHeader(title: 'Privacy'),
          SwitchListTile(
            secondary: Icon(Icons.location_on_outlined, color: colorScheme.error),
            title: const Text('Location Sharing'),
            subtitle: const Text('Allow precise location tracking for maps and teams'),
            value: _locationTracking,
            activeColor: colorScheme.primary,
            onChanged: _toggleLocationTracking,
          ),

          const Divider(),

          // About Section
          const _SectionHeader(title: 'About App'),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open policies
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open policies
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Text(
              'Projet Sejour Version 0.2.0\n© 2026',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
