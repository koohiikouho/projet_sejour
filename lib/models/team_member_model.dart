import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final bool isOnline;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    required this.isOnline,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TeamMember(
      id: doc.id,
      name: data['name'] ?? 'Unknown User',
      role: data['role'] ?? 'Member',
      avatarUrl: data['avatarUrl'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isOnline': isOnline,
    };
  }
}
