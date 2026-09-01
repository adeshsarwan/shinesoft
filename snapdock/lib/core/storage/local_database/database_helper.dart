import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static final LocalDB instance = LocalDB._init();
  static Database? _database;

  LocalDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('VideoDownload.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: _createDB,
      // onUpgrade: _upgradeDB, // Added onUpgrade
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE downloads (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      imageUrl TEXT,
      videoPath TEXT,
      createdAt TEXT,
      isFavorite INTEGER DEFAULT 0
    )
    ''');
  }

  // Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
  //   if (oldVersion < 2) {
  //     // Add isFavorite column if upgrading from version 1
  //     await db.execute('ALTER TABLE downloads ADD COLUMN isFavorite INTEGER DEFAULT 0');
  //   }
  // }

  Future<int> insertDownload(String imageUrl, String videoPath) async {
    final db = await instance.database;
    return await db.insert("downloads", {
      "imageUrl": imageUrl,
      "videoPath": videoPath,
      "createdAt": DateTime.now().toIso8601String(),
      "isFavorite": 0
    });
  }

  Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final db = await instance.database;
    return await db.query("downloads", orderBy: "id DESC");
  }

  // Get only favorite videos
  Future<List<Map<String, dynamic>>> getFavoriteDownloads() async {
    final db = await instance.database;
    return await db.query(
      "downloads", 
      where: "isFavorite = ?",
      whereArgs: [1],
      orderBy: "id DESC"
    );
  }

  // Toggle favorite status
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await instance.database;
    return await db.update(
      "downloads",
      {"isFavorite": isFavorite ? 1 : 0},
      where: "id = ?",
      whereArgs: [id]
    );
  }

  // Check if a video is favorite
  Future<bool> isFavorite(int id) async {
    final db = await instance.database;
    final result = await db.query(
      "downloads",
      columns: ["isFavorite"],
      where: "id = ?",
      whereArgs: [id]
    );
    
    if (result.isNotEmpty) {
      return result.first["isFavorite"] == 1;
    }
    return false;
  }

  Future<int> deleteDownload(int id) async {
    final db = await instance.database;
    return await db.delete("downloads", where: "id = ?", whereArgs: [id]);
  }

  Future closeDB() async {
    final db = await _database;
    db?.close();
  }
}