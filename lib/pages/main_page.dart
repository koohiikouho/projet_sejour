import 'package:flutter/material.dart';
import 'package:projet_sejour/services/auth_service.dart';
import 'package:projet_sejour/pages/map_page.dart';
import 'package:projet_sejour/pages/tabs/home_tab.dart';
import 'package:projet_sejour/widgets/custom_nav_bar.dart';
import 'package:projet_sejour/pages/ar_page.dart';
import 'package:projet_sejour/pages/itinerary/itinerary_overview_page.dart';
import 'package:projet_sejour/pages/profile_page.dart';

import 'package:projet_sejour/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_sejour/services/team_service.dart';
import 'package:projet_sejour/pages/join_team_scanner_page.dart';
import 'package:projet_sejour/widgets/team/team_code_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _authService.getUserData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _checkTeamOnboarding();
    }
  }

  Future<void> _checkTeamOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('onboarding_team_shown') == true) return;

    final teamId = await TeamService().getCurrentUserTeamId();
    if (teamId != null) return;

    if (!mounted) return;

    await prefs.setBool('onboarding_team_shown', true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.group_add_rounded, color: colorScheme.primary, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Join Your Pilgrimage Team',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan a QR code from your team leader, or enter your team code.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinTeamScannerPage()));
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    showDialog(context: context, builder: (_) => const TeamCodeDialog());
                  },
                  icon: const Icon(Icons.keyboard_rounded),
                  label: const Text('Enter Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Skip for Now', style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Projet Sejour',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeTab(),
          const MapPage(),
          ARPage(isActive: _currentIndex == 2),
          const ItineraryOverviewPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onNavTap: _onNavTap,
      ),
    );
  }
}
