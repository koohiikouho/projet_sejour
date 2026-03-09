import 'package:flutter/material.dart';
import 'package:projet_sejour/widgets/profile/profile_header.dart';
import 'package:projet_sejour/widgets/profile/profile_info_card.dart';
import 'package:projet_sejour/widgets/profile/about_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover Photo
          const ProfileHeader(),

          // Profile Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
              child: const ProfileInfoCard(),
            ),
          ),

          // About Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const AboutSection(),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}