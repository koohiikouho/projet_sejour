import 'package:flutter/material.dart';
import 'package:projet_sejour/models/announcement.dart';
import 'package:projet_sejour/pages/announcements/announcement_details_page.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({super.key, required this.announcement});

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

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AnnouncementDetailsPage(announcement: announcement),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: typeColor.withValues(alpha: 0.15),
                    child: Icon(typeIcon, size: 20, color: typeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (announcement.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 6.0),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                    ),
                  Text(
                    announcement.time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
