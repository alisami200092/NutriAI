import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('water_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // We store:
    // id: Unique ID
    // amount: How much water (0.5, 1.0, etc.)
    // date: The specific timestamp (e.g., "2024-01-29T10:30:00")
    await db.execute('''
    CREATE TABLE water_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL,
      date TEXT
    )
    ''');
  }

  // --- CRUD OPERATIONS ---

  // 1. Add Water
  Future<int> insertLog(double amount) async {
    final db = await instance.database;
    return await db.insert('water_logs', {
      'amount': amount,
      'date': DateTime.now().toIso8601String(), // Save current time
    });
  }

  // 2. Get Total Water for TODAY only
  Future<double> getTodayTotal() async {
    final db = await instance.database;

    // Get today's date string prefix (e.g., "2024-01-29")
    String todayPrefix = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Query: Sum all amounts where the date starts with today
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM water_logs WHERE date LIKE '$todayPrefix%'",
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  // 3. Reset (Optional: Debugging purposes)
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('water_logs');
  }
}
