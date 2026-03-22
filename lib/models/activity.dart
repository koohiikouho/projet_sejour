import 'dart:convert';
import 'package:flutter/material.dart';

class TodoItem {
  String title;
  bool isChecked;

  TodoItem({required this.title, this.isChecked = false});

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json['title'] as String,
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'isChecked': isChecked,
  };
}

class Activity {
  final String activityId;
  final String dayId; // Foreign Key for SQLite
  final String siteName;
  final String description;
  final String photoUrl;
  final String category;
  final String mobilityRating;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime scheduledArrival;
  final DateTime scheduledDeparture;
  final List<TodoItem> whatToBring;
  final DateTime lastUpdatedAt;
  final bool isCompleted;

  Activity({
    required this.activityId,
    required this.dayId,
    required this.siteName,
    required this.description,
    required this.photoUrl,
    required this.category,
    required this.mobilityRating,
    required this.location,
    this.latitude,
    this.longitude,
    required this.scheduledArrival,
    required this.scheduledDeparture,
    required this.whatToBring,
    required this.lastUpdatedAt,
    this.isCompleted = false,
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
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      scheduledArrival: DateTime.parse(map['scheduledArrival'] as String),
      scheduledDeparture: DateTime.parse(map['scheduledDeparture'] as String),
      whatToBring: _parseWhatToBring(map['whatToBring']),
      lastUpdatedAt: DateTime.parse(map['lastUpdatedAt'] as String),
      isCompleted: (map['isCompleted'] as int?) == 1,
    );
  }

  static List<TodoItem> _parseWhatToBring(dynamic value) {
    if (value == null) return [];
    try {
      final decoded = json.decode(value as String);
      if (decoded is List) {
        return decoded.map((item) {
          if (item is String) {
            return TodoItem(title: item);
          } else if (item is Map<String, dynamic>) {
            return TodoItem.fromJson(item);
          }
          return TodoItem(title: item.toString());
        }).toList();
      }
    } catch (_) {}
    return [];
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
      'latitude': latitude,
      'longitude': longitude,
      'scheduledArrival': scheduledArrival.toIso8601String(),
      'scheduledDeparture': scheduledDeparture.toIso8601String(),
      // Store String array gracefully as localized JSON string
      'whatToBring': json.encode(whatToBring.map((i) => i.toJson()).toList()), 
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }
}
