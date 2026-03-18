import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_sejour/widgets/profile/profile_info_card.dart';
import 'package:projet_sejour/widgets/profile/about_section.dart';
import 'package:projet_sejour/widgets/profile/analytics_dashboard.dart';
import 'package:projet_sejour/services/analytics_service.dart';
import 'package:projet_sejour/models/user_stats.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AnalyticsService _analyticsService = AnalyticsService();
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
      body: StreamBuilder<UserStats>(
        stream: _analyticsService.streamUserStats(_teamId, _userId),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? UserStats.empty();

          return CustomScrollView(
            slivers: [
              // Profile Info Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: const ProfileInfoCard(),
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
                  child: const AboutSection(),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}
