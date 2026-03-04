import 'package:flutter/material.dart';
import 'package:projet_sejour/models/announcement.dart';

class AnnouncementDetailsPage extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailsPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    IconData typeIcon;
    Color typeColor;

    switch (announcement.type) {
      case AnnouncementType.important:
        typeIcon = Icons.warning_rounded;
        typeColor = Colors.redAccent;
        break;
      case AnnouncementType.alert:
        typeIcon = Icons.wb_cloudy_rounded;
        typeColor = Colors.orangeAccent;
        break;
      case AnnouncementType.info:
        typeIcon = Icons.info_outline_rounded;
        typeColor = Colors.blueAccent;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(typeIcon, color: typeColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          announcement.time,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              announcement.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 16),
            ),
            const SizedBox(height: 48),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Mark as Read'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
