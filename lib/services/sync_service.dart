import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/trip.dart';
import '../models/itinerary_day.dart';
import '../data/local_repository.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalRepository _localRepository;

  SyncService(this._localRepository);

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is Iterable) {
      return List<String>.from(value.map((e) => e.toString()));
    }
    if (value is String) {
      if (value.trim().isEmpty) return [];
      try {
        final decoded = json.decode(value);
        if (decoded is Iterable) {
          return List<String>.from(decoded.map((e) => e.toString()));
        }
      } catch (_) {}
      return [value];
    }
    return [value.toString()];
  }

  /// Synchronize all Trips, Days, and Activities from Firestore into local SQLite cache
  Future<void> syncAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sync Trips
      final tripsSnapshot = await _firestore.collection('trips').get();
      for (var tripDoc in tripsSnapshot.docs) {
        try {
          final tripData = tripDoc.data() as Map<String, dynamic>;
          final trip = Trip(
            tripId: tripDoc.id,
            tripName: tripData['tripName'] ?? '',
            startDate: _parseDate(tripData['startDate']),
            endDate: _parseDate(tripData['endDate']),
            status: tripData['status'] ?? 'upcoming',
          );
          await _localRepository.insertOrUpdateTrip(trip);

          // Sync Itinerary Days for this trip
          final daysSnapshot = await tripDoc.reference
              .collection('itineraryDays')
              .get();
          for (var dayDoc in daysSnapshot.docs) {
            try {
              final dayData = dayDoc.data() as Map<String, dynamic>;
              final day = ItineraryDay(
                dayId: dayDoc.id,
                tripId: trip.tripId,
                dayNumber: dayData['dayNumber'] ?? 1,
                date: _parseDate(dayData['date']),
              );
              await _localRepository.insertOrUpdateItineraryDay(day);

              // Sync Activities for this day
              final lastSyncKey = 'lastSync_activities_${day.dayId}';
              final lastSyncStr = prefs.getString(lastSyncKey);

              Query activityQuery = dayDoc.reference.collection('activities');
              /* 
              // Temporarily disabled delta updates to ensure missing activities that were
              // skipped due to previous schema crashes are fully re-downloaded.
              if (lastSyncStr != null) {
                final lastSyncTimestamp = Timestamp.fromDate(DateTime.parse(lastSyncStr));
                activityQuery = activityQuery.where('lastUpdatedAt', isGreaterThan: lastSyncTimestamp);
              }
              */

              final activitiesSnapshot = await activityQuery.get();
              for (var activityDoc in activitiesSnapshot.docs) {
                try {
                  final activityData =
                      activityDoc.data() as Map<String, dynamic>;
                  final activity = Activity(
                    activityId: activityDoc.id,
                    dayId: day.dayId,
                    siteName: activityData['siteName'] ?? '',
                    description: activityData['description'] ?? '',
                    photoUrl: activityData['photoUrl'] ?? '',
                    category: activityData['category'] ?? 'destination',
                    mobilityRating:
                        activityData['mobilityRating']?.toString() ?? '',
                    location: activityData['location'] ?? '',
                    scheduledArrival: _parseDate(
                      activityData['scheduledArrival'],
                    ),
                    scheduledDeparture: _parseDate(
                      activityData['scheduledDeparture'],
                    ),
                    whatToBring: _parseStringList(activityData['whatToBring']),
                    lastUpdatedAt: _parseDate(activityData['lastUpdatedAt']),
                  );
                  await _localRepository.insertOrUpdateActivity(activity);
                } catch (e) {
                  debugPrint('Error parsing activity ${activityDoc.id}: $e');
                }
              }
              await prefs.setString(
                lastSyncKey,
                DateTime.now().toIso8601String(),
              );
            } catch (e) {
              debugPrint('Error parsing itineraryDay ${dayDoc.id}: $e');
            }
          }
        } catch (e) {
          debugPrint('Error parsing trip ${tripDoc.id}: $e');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error syncing all data from Firestore: $e\n$stackTrace');
      // Gracefully fail. The UI still reads from the local database
    }
  }
}
