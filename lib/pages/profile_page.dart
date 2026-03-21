import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_sejour/widgets/profile/profile_info_card.dart';
import 'package:projet_sejour/widgets/profile/about_section.dart';
import 'package:projet_sejour/widgets/profile/analytics_dashboard.dart';
import 'package:projet_sejour/services/analytics_service.dart';
import 'package:projet_sejour/services/user_service.dart';
import 'package:projet_sejour/models/user_stats.dart';
import 'package:projet_sejour/models/user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final UserService _userService = UserService();
  final String _teamId = "team_alpha"; // Consistent with LocationSyncService
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? "user_123";
    // Seed mock data for demonstration purposes
    _analyticsService.seedMockAnalytics(_teamId, _userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<UserProfile?>(
        stream: _userService.getUserProfileStream(_userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = userSnapshot.data ??
              UserProfile(
                uid: _userId,
                username: 'Pilgrim',
              );

          return StreamBuilder<UserStats>(
            stream: _analyticsService.streamUserStats(_teamId, _userId),
            builder: (context, statsSnapshot) {
              final stats = statsSnapshot.data ?? UserStats.empty();

              return CustomScrollView(
                slivers: [
                  // Profile Info Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: ProfileInfoCard(profile: profile),
                    ),
                  ),

                  // Analytics Dashboard
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnalyticsDashboard(stats: stats),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // About Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AboutSection(profile: profile),
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final TextEditingController distanceController = TextEditingController(text: '0.5');
          final TextEditingController streakController = TextEditingController(text: '5');
          
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Simulate Activity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Customize your simulation:'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Distance',
                      suffixText: 'km',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: streakController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Streak',
                      suffixText: 'days',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'distance': double.tryParse(distanceController.text) ?? 0.0,
                      'streak': int.tryParse(streakController.text) ?? 0,
                    });
                  },
                  child: const Text('Simulate'),
                ),
              ],
            ),
          );

          if (result != null) {
            final double distance = result['distance'];
            final int streak = result['streak'];
            
            await _analyticsService.simulateActivity(
              _teamId, 
              _userId, 
              distance, 
              streak: streak,
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Updated analytics: ${distance}km, $streak day streak!')),
              );
            }
          }
        },
        label: const Text('Test Analytics'),
        icon: const Icon(Icons.directions_walk),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
