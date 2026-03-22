import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_sejour/models/user_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projet_sejour/pages/edit_profile_page.dart';

class ProfileInfoCard extends StatelessWidget {
  final UserProfile profile;

  const ProfileInfoCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Picture
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                    ? profile.avatarUrl!
                    : (FirebaseAuth.instance.currentUser?.photoURL != null && FirebaseAuth.instance.currentUser!.photoURL!.isNotEmpty)
                        ? FirebaseAuth.instance.currentUser!.photoURL!
                        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile.username)}&background=6366f1&color=fff&size=128&format=png',
                placeholder: (context, url) => Center(
                  child: Text(
                    profile.username.isNotEmpty ? profile.username[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: 60,
                  color: colorScheme.primary,
                ),
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Name and Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      profile.username,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(profile: profile),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.role ?? 'Pilgrim',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}