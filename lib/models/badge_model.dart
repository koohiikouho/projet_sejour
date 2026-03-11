import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeItem {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final double latitude;
  final double longitude;
  final double unlockRadiusInMeters;

  const BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.latitude,
    required this.longitude,
    required this.unlockRadiusInMeters,
  });

  factory BadgeItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      unlockRadiusInMeters: (data['unlockRadiusInMeters'] ?? 500.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'latitude': latitude,
      'longitude': longitude,
      'unlockRadiusInMeters': unlockRadiusInMeters,
    };
  }
}


class UserBadgeStatus {
  final String badgeId;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const UserBadgeStatus({
    required this.badgeId,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory UserBadgeStatus.fromMap(Map<String, dynamic> map, String id) {
    return UserBadgeStatus(
      badgeId: id,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }
}
