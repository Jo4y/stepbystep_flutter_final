import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip_model.dart';

class DbHelper {
  static Database? _database;

  // [09] 資料儲存初始化
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'travel_planner.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE trips(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, startDate TEXT)',
        );
      },
    );
  }

  static Future<void> insertTrip(Trip trip) async {
    final db = await database;
    await db.insert('trips', trip.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Trip>> getTrips() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('trips');
    return List.generate(maps.length, (i) => Trip(
      id: maps[i]['id'],
      title: maps[i]['title'],
      startDate: maps[i]['startDate'],
    ));
  }
}