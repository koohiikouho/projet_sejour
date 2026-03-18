import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sojourn_local_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop existing tables and recreate
    await db.execute('DROP TABLE IF EXISTS activities');
    await db.execute('DROP TABLE IF EXISTS itineraryDays');
    await db.execute('DROP TABLE IF EXISTS trips');
    await _createDB(db, newVersion);
  }

  Future _onConfigure(Database db) async {
    // Enable Foreign Keys for cascading deletes
    await db.execute('PRAGMA foreign_keys = ON'); 
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        tripId TEXT PRIMARY KEY,
        tripName TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE itineraryDays (
        dayId TEXT PRIMARY KEY,
        tripId TEXT NOT NULL,
        dayNumber INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (tripId) REFERENCES trips (tripId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        activityId TEXT PRIMARY KEY,
        dayId TEXT NOT NULL,
        siteName TEXT NOT NULL,
        description TEXT,
        photoUrl TEXT,
        category TEXT NOT NULL,
        mobilityRating TEXT,
        location TEXT,
        scheduledArrival TEXT NOT NULL,
        scheduledDeparture TEXT NOT NULL,
        whatToBring TEXT,
        lastUpdatedAt TEXT NOT NULL,
        FOREIGN KEY (dayId) REFERENCES itineraryDays (dayId) ON DELETE CASCADE
      )
    ''');
  }
}
