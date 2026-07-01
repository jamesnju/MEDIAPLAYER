// lib/core/database/database_helper.dart (updated)
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'migrations/migration_v2.dart';

class DatabaseHelper {
  static Database? _database;
  static const int _databaseVersion = 2;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'media_player.db');
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        album TEXT,
        filePath TEXT,
        fileName TEXT,
        fileExtension TEXT,
        fileSize INTEGER,
        duration INTEGER,
        albumArt TEXT,
        mediaType TEXT,
        dateAdded INTEGER,
        dateModified INTEGER,
        trackNumber INTEGER,
        year INTEGER,
        genre TEXT,
        isFavorite INTEGER DEFAULT 0,
        playCount INTEGER DEFAULT 0,
        lastPlayed INTEGER DEFAULT 0,
        bitrate REAL,
        sampleRate INTEGER,
        isFilteredOut INTEGER DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE videos (
        id TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        album TEXT,
        filePath TEXT,
        fileName TEXT,
        fileExtension TEXT,
        fileSize INTEGER,
        duration INTEGER,
        albumArt TEXT,
        mediaType TEXT,
        dateAdded INTEGER,
        dateModified INTEGER,
        trackNumber INTEGER,
        year INTEGER,
        genre TEXT,
        isFavorite INTEGER DEFAULT 0,
        playCount INTEGER DEFAULT 0,
        lastPlayed INTEGER DEFAULT 0,
        bitrate REAL,
        sampleRate INTEGER,
        isFilteredOut INTEGER DEFAULT 0
      )
    ''');
    
    // Create indexes for performance
    await db.execute('CREATE INDEX idx_songs_title ON songs(title)');
    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist)');
    await db.execute('CREATE INDEX idx_songs_isFavorite ON songs(isFavorite)');
    await db.execute('CREATE INDEX idx_songs_isFilteredOut ON songs(isFilteredOut)');
    await db.execute('CREATE INDEX idx_videos_title ON videos(title)');
    await db.execute('CREATE INDEX idx_videos_isFavorite ON videos(isFavorite)');
    await db.execute('CREATE INDEX idx_videos_isFilteredOut ON videos(isFilteredOut)');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await MigrationV2.upgrade(db);
    }
  }
}