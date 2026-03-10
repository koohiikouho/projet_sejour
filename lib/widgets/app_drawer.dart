import 'package:flutter/material.dart';
import 'package:projet_sejour/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Custom Gradient Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('assets/images/BigHero.jpg'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Baymax',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Pilgrim',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Settings
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Help & Support
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to About Us
                  },
                ),
              ],
            ),
          ),
          
          // Footer Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService().logout();
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Projet Sejour v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(icon, color: color, size: 26),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        splashColor: (isDestructive ? colorScheme.error : colorScheme.primary).withValues(alpha: 0.1),
        hoverColor: (isDestructive ? colorScheme.error : colorScheme.primary).withValues(alpha: 0.05),
      ),
    );
  }
}
