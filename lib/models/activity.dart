import 'dart:convert';
import 'package:flutter/material.dart';

class Activity {
  final String activityId;
  final String dayId; // Foreign Key for SQLite
  final String siteName;
  final String description;
  final String photoUrl;
  final String category;
  final String mobilityRating;
  final String location;
  final DateTime scheduledArrival;
  final DateTime scheduledDeparture;
  final List<String> whatToBring;
  final DateTime lastUpdatedAt;

  Activity({
    required this.activityId,
    required this.dayId,
    required this.siteName,
    required this.description,
    required this.photoUrl,
    required this.category,
    required this.mobilityRating,
    required this.location,
    required this.scheduledArrival,
    required this.scheduledDeparture,
    required this.whatToBring,
    required this.lastUpdatedAt,
  });

  // Calculate and return the duration
  Duration get duration => scheduledDeparture.difference(scheduledArrival);

  // Return the appropriate UI Icon based on the category string
  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'spiritual':
        return Icons.self_improvement;
      case 'transportation':
        return Icons.directions_transit;
      case 'destination':
        return Icons.place;
      case 'dining':
        return Icons.restaurant;
      default:
        return Icons.event;
    }
  }

  factory Activity.fromSqlite(Map<String, dynamic> map) {
    return Activity(
      activityId: map['activityId'] as String,
      dayId: map['dayId'] as String,
      siteName: map['siteName'] as String,
      description: map['description'] as String,
      photoUrl: map['photoUrl'] as String,
      category: map['category'] as String,
      mobilityRating: map['mobilityRating']?.toString() ?? '',
      location: map['location'] as String,
      scheduledArrival: DateTime.parse(map['scheduledArrival'] as String),
      scheduledDeparture: DateTime.parse(map['scheduledDeparture'] as String),
      whatToBring: List<String>.from(json.decode(map['whatToBring'] as String)),
      lastUpdatedAt: DateTime.parse(map['lastUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'activityId': activityId,
      'dayId': dayId,
      'siteName': siteName,
      'description': description,
      'photoUrl': photoUrl,
      'category': category,
      'mobilityRating': mobilityRating,
      'location': location,
      'scheduledArrival': scheduledArrival.toIso8601String(),
      'scheduledDeparture': scheduledDeparture.toIso8601String(),
      // Store String array gracefully as localized JSON string
      'whatToBring': json.encode(whatToBring), 
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }
}
