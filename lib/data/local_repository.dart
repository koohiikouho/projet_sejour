import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';
import '../models/itinerary_day.dart';
import '../models/activity.dart';
import 'database_helper.dart';

class LocalRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  // Insert or completely replace an activity
  Future<void> insertOrUpdateActivity(Activity activity) async {
    final db = await dbHelper.database;
    await db.insert(
      'activities',
      activity.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch activities for a specific day, chronologically sorted
  Future<List<Activity>> getActivitiesForDay(String dayId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'activities',
      where: 'dayId = ?',
      whereArgs: [dayId],
      orderBy: 'scheduledArrival ASC',
    );

    return maps.map((map) => Activity.fromSqlite(map)).toList();
  }

  // Fetch all activities across all days, chronologically sorted
  Future<List<Activity>> getAllActivities() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'activities',
      orderBy: 'scheduledArrival ASC',
    );

    return maps.map((map) => Activity.fromSqlite(map)).toList();
  }

  // Optional convenience methods for Trip and ItineraryDay to complete the hierarchy
  Future<void> insertOrUpdateTrip(Trip trip) async {
    final db = await dbHelper.database;
    await db.insert(
      'trips',
      trip.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOrUpdateItineraryDay(ItineraryDay day) async {
    final db = await dbHelper.database;
    await db.insert(
      'itineraryDays',
      day.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get the first trip available
  Future<Trip?> getFirstTrip() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'trips',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Trip.fromSqlite(maps.first);
    }
    return null;
  }

  // Fetch itinerary days for a specific trip, ordered by day number
  Future<List<ItineraryDay>> getDaysForTrip(String tripId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'itineraryDays',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'dayNumber ASC',
    );
    return maps.map((map) => ItineraryDay.fromSqlite(map)).toList();
  }
}
