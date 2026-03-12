import 'package:flutter/material.dart';
import 'package:projet_sejour/services/auth_service.dart';
import 'package:projet_sejour/pages/badges_page.dart';
import 'package:projet_sejour/pages/chatbot_page.dart';

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
            child: GridView.count(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildGridTile(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Lumen AI',
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatbotPage()),
                    );
                  },
                ),
                _buildGridTile(
                  context: context,
                  icon: Icons.shield_outlined,
                  title: 'Badges',
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BadgesPage()),
                    );
                  },
                ),
                _buildGridTile(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to Settings
                  },
                ),
                _buildGridTile(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(Icons.logout, color: colorScheme.error, size: 26),
                  title: Text(
                    'Log Out',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService().logout();
                  },
                  splashColor: colorScheme.error.withValues(alpha: 0.1),
                  hoverColor: colorScheme.error.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 16),
                Text(
                  'Projet Sejour v1.0.0',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
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

  Widget _buildGridTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
