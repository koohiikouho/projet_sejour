enum AnnouncementType { important, alert, info }

class Announcement {
  final String title;
  final String time;
  final String description;
  final AnnouncementType type;
  final bool isPinned;

  Announcement({
    required this.title,
    required this.time,
    required this.description,
    required this.type,
    this.isPinned = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      title: json['title'] as String,
      time: json['time'] as String,
      description: json['description'] as String,
      type: AnnouncementType.values.byName(json['type'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
}
