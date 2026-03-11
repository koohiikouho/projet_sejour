import 'package:flutter/material.dart';
import 'package:projet_sejour/models/badge_model.dart';
import 'package:projet_sejour/services/badge_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  final BadgeService _badgeService = BadgeService();
  final String _teamId = 'team_alpha';
  final String _userId = 'user_123'; // Hardcoded for demo

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Badges', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<BadgeItem>>(
        stream: _badgeService.getAvailableBadgesStream(),
        builder: (context, availableSnapshot) {
          if (availableSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final availableBadges = availableSnapshot.data ?? [];
          
          return StreamBuilder<List<UserBadgeStatus>>(
            stream: _badgeService.getUserBadgesStream(_teamId, _userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final unlockedStatuses = snapshot.data ?? [];
              final unlockedIds = unlockedStatuses.where((s) => s.isUnlocked).map((s) => s.badgeId).toSet();

              // Calculate progress
              final totalBadges = availableBadges.length;
              final unlockedCount = unlockedIds.length;
              final progress = totalBadges == 0 ? 0.0 : unlockedCount / totalBadges;

              return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Explorer Progress',
                              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$unlockedCount / $totalBadges',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final badge = availableBadges[index];
                      final isUnlocked = unlockedIds.contains(badge.id);
                      final status = unlockedStatuses.firstWhere(
                        (s) => s.badgeId == badge.id, 
                        orElse: () => UserBadgeStatus(badgeId: badge.id, isUnlocked: false)
                      );

                      return _buildBadgeCard(context, badge, isUnlocked, status.unlockedAt);
                    },
                    childCount: availableBadges.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      );
    },
  ),
);
  }

  Widget _buildBadgeCard(BuildContext context, BadgeItem badge, bool isUnlocked, DateTime? unlockedAt) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        _showBadgeDetails(context, badge, isUnlocked, unlockedAt);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isUnlocked ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked ? [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Image / Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  isUnlocked ? Icons.verified : Icons.lock_outline,
                  size: 40,
                  color: isUnlocked ? colorScheme.primary : Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isUnlocked ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              isUnlocked ? 'Unlocked' : 'Locked',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? colorScheme.primary : Colors.grey.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, BadgeItem badge, bool isUnlocked, DateTime? unlockedAt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 32),
              
              // Big Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked ? colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(
                    isUnlocked ? Icons.verified : Icons.lock_outline,
                    size: 64,
                    color: isUnlocked ? colorScheme.primary : Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                badge.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              if (isUnlocked && unlockedAt != null)
                Text(
                  "Earned on ${unlockedAt.day.toString().padLeft(2, '0')}/${unlockedAt.month.toString().padLeft(2, '0')}/${unlockedAt.year}",
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                )
              else
                Text(
                  'Explore to find this badge',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                ),
                
              const SizedBox(height: 24),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.8), height: 1.5),
              ),
              const SizedBox(height: 24),
              // MapBox Widget Injection pinpointing exactly where the badge unlocks
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: MapWidget(
                    key: ValueKey(badge.id),
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: Position(badge.longitude, badge.latitude)),
                      zoom: 15.5,
                      pitch: 45.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }
}
