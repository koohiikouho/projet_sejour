import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:projet_sejour/models/user_stats.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the latest user stats and recent activity
  Future<UserStats> getUserStats(String teamId, String userId) async {
    try {
      // 1. Get aggregate stats from the member document
      final memberDoc = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .get();

      // 2. Get the last 7 days of activity
      final activitySnapshot = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .collection('daily_activity')
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      final activity = activitySnapshot.docs
          .map((doc) => DailyActivity.fromMap(doc.data()))
          .toList()
          .reversed
          .toList();

      // 3. Get total badges count (could also be stored in aggregate stats)
      final badgesSnapshot = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .collection('unlocked_badges')
          .get();

      final stats = UserStats.fromFirestore(memberDoc, activity);
      
      // Override totalBadges if we want a fresh count
      return UserStats(
        totalDistanceKm: stats.totalDistanceKm,
        totalBadges: badgesSnapshot.docs.length,
        currentStreak: stats.currentStreak,
        weeklyActivity: activity,
      );
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return UserStats.empty();
    }
  }

  // Stream of user stats for real-time UI updates
  Stream<UserStats> streamUserStats(String teamId, String userId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .asyncMap((memberDoc) async {
      final activitySnapshot = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .collection('daily_activity')
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      final activity = activitySnapshot.docs
          .map((doc) => DailyActivity.fromMap(doc.data()))
          .toList()
          .reversed
          .toList();

      final badgesSnapshot = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .collection('unlocked_badges')
          .get();

      final stats = UserStats.fromFirestore(memberDoc, activity);
      return UserStats(
        totalDistanceKm: stats.totalDistanceKm,
        totalBadges: badgesSnapshot.docs.length,
        currentStreak: stats.currentStreak,
        weeklyActivity: activity,
      );
    });
  }

  // Seed some initial data for demonstration if none exists
  Future<void> seedMockAnalytics(String teamId, String userId) async {
    final activityColl = _firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(userId)
        .collection('daily_activity');

    final snapshot = await activityColl.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        await activityColl.add({
          'date': Timestamp.fromDate(date),
          'distanceKm': (i % 3 + 1) * 1.5,
          'activityScore': (i % 5 + 3) * 10,
        });
      }

      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(userId)
          .update({
        'totalDistanceKm': 15.4,
        'currentStreak': 5,
      });
    }
  }
}
