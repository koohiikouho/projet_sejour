import 'package:flutter/material.dart';
import 'package:projet_sejour/data/mock_data.dart';
import 'package:projet_sejour/pages/announcements/all_announcements_page.dart';
import 'package:projet_sejour/widgets/announcement_card.dart';
import 'package:projet_sejour/widgets/timeline_item.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
      children: [
        // Announcements Section
        Text(
          'Announcements',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildAnnouncementsSection(context),
        const SizedBox(height: 32),

        // Itinerary Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Itinerary',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Oct 12, 2026',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Timeline
        ...mockItinerary.map((item) => TimelineItem(item: item)),
      ],
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context) {
    final pinned = mockAnnouncements.where((ann) => ann.isPinned).toList();
    final others = mockAnnouncements
        .where((ann) => !ann.isPinned)
        .take(2)
        .toList();
    final displayList = [...pinned, ...others];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...displayList.map((ann) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AnnouncementCard(announcement: ann),
          );
        }),
        const SizedBox(height: 4),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllAnnouncementsPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'See All Announcements',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
