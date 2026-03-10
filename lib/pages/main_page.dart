import 'package:flutter/material.dart';
import 'package:projet_sejour/services/auth_service.dart';
import 'package:projet_sejour/pages/map_page.dart';
import 'package:projet_sejour/pages/tabs/home_tab.dart';
import 'package:projet_sejour/widgets/custom_nav_bar.dart';
import 'package:projet_sejour/pages/ar_page.dart';
import 'package:projet_sejour/pages/itinerary/itinerary_overview_page.dart';
import 'package:projet_sejour/pages/profile_page.dart';

import 'package:projet_sejour/widgets/app_drawer.dart';

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
    }
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
