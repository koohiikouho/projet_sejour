import 'package:cloud_firestore/cloud_firestore.dart';

class DailyActivity {
  final DateTime date;
  final double distanceKm;
  final int activityScore;

  DailyActivity({
    required this.date,
    required this.distanceKm,
    required this.activityScore,
  });

  factory DailyActivity.fromMap(Map<String, dynamic> map) {
    return DailyActivity(
      date: (map['date'] as Timestamp).toDate(),
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      activityScore: map['activityScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'distanceKm': distanceKm,
      'activityScore': activityScore,
    };
  }
}

class UserStats {
  final double totalDistanceKm;
  final int totalBadges;
  final int currentStreak;
  final List<DailyActivity> weeklyActivity;

  UserStats({
    required this.totalDistanceKm,
    required this.totalBadges,
    required this.currentStreak,
    required this.weeklyActivity,
  });

  factory UserStats.fromFirestore(DocumentSnapshot doc, List<DailyActivity> activity) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return UserStats(
      totalDistanceKm: (data['totalDistanceKm'] ?? 0.0).toDouble(),
      totalBadges: data['totalBadges'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      weeklyActivity: activity,
    );
  }

  factory UserStats.empty() {
    return UserStats(
      totalDistanceKm: 0.0,
      totalBadges: 0,
      currentStreak: 0,
      weeklyActivity: [],
    );
  }
}
