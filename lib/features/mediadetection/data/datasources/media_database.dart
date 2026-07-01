import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/helpers/logger_helper.dart';

class MediaDatabase {
  static final MediaDatabase _instance = MediaDatabase._internal();
  Database? _database;
  final LoggerHelper _logger = LoggerHelper();

  MediaDatabase._internal();

  factory MediaDatabase() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);
      
      _logger.info('Database path: $path');

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      _logger.error('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    _logger.info('Creating database tables for version $version');
    
    try {
      await _createTables(db);
      await _enableWALMode(db);
      await _createIndexes(db);
      
      _logger.info('Database tables created successfully');
    } catch (e) {
      _logger.error('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> _createTables(Database db) async {
    // Create media table WITH isFilteredOut column
    await db.execute('''
      CREATE TABLE IF NOT EXISTS media (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL,
        filePath TEXT NOT NULL UNIQUE,
        fileName TEXT NOT NULL,
        fileExtension TEXT NOT NULL,
        fileSize INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        albumArt TEXT,
        mediaType TEXT NOT NULL,
        dateAdded INTEGER NOT NULL,
        dateModified INTEGER NOT NULL,
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

    // Create albums table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS albums (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        year INTEGER,
        albumArt TEXT,
        trackCount INTEGER DEFAULT 0,
        totalDuration INTEGER DEFAULT 0
      )
    ''');

    // Create artists table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        albumCount INTEGER DEFAULT 0,
        trackCount INTEGER DEFAULT 0,
        image TEXT
      )
    ''');

    // Create playlists table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        coverImage TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        trackCount INTEGER DEFAULT 0
      )
    ''');

    // Create playlist_media junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_media (
        playlistId TEXT NOT NULL,
        mediaId TEXT NOT NULL,
        position INTEGER NOT NULL,
        addedAt INTEGER NOT NULL,
        PRIMARY KEY (playlistId, mediaId),
        FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (mediaId) REFERENCES media(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _enableWALMode(Database db) async {
    try {
      final result = await db.rawQuery('PRAGMA journal_mode = WAL');
      _logger.info('WAL mode enabled: ${result.first['journal_mode']}');
    } catch (e) {
      _logger.warning('Could not enable WAL mode: $e');
    }
  }

  Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_artist ON media(artist)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_album ON media(album)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_type ON media(mediaType)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_favorite ON media(isFavorite)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_last_played ON media(lastPlayed)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_file_path ON media(filePath)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_filtered_out ON media(isFilteredOut)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_playlist_media_playlist ON playlist_media(playlistId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_playlist_media_media ON playlist_media(mediaId)');
      
      _logger.info('Indexes created successfully');
    } catch (e) {
      _logger.warning('Error creating indexes: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.info('Upgrading database from version $oldVersion to $newVersion');
    
    try {
      if (oldVersion < 2) {
        // Add isFilteredOut column for version 2
        try {
          // Check if column exists first
          final columns = await db.rawQuery('PRAGMA table_info(media)');
          final columnNames = columns.map((col) => col['name'] as String).toList();
          
          if (!columnNames.contains('isFilteredOut')) {
            await db.execute('ALTER TABLE media ADD COLUMN isFilteredOut INTEGER DEFAULT 0');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_media_filtered_out ON media(isFilteredOut)');
            _logger.info('✅ Added isFilteredOut column');
          } else {
            _logger.info('ℹ️ isFilteredOut column already exists');
          }
        } catch (e) {
          _logger.error('Error adding isFilteredOut column: $e');
        }
      }
      
      _logger.info('Database upgrade completed');
    } catch (e) {
      _logger.error('Error upgrading database: $e');
      rethrow;
    }
  }

  Future<void> enableWALModeAfterOpen() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA journal_mode = WAL');
      _logger.info('WAL mode enabled after open: ${result.first['journal_mode']}');
    } catch (e) {
      _logger.warning('Could not enable WAL mode after open: $e');
    }
  }

  Future<bool> tableExists(String tableName) async {
    try {
      final db = await database;
      final result = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      _logger.error('Error checking table existence: $e');
      return false;
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      
      final mediaExists = await tableExists('media');
      final albumsExists = await tableExists('albums');
      final artistsExists = await tableExists('artists');
      final playlistsExists = await tableExists('playlists');
      final playlistMediaExists = await tableExists('playlist_media');
      
      if (playlistMediaExists) {
        await db.delete('playlist_media');
        _logger.info('Cleared playlist_media table');
      }
      
      if (playlistsExists) {
        await db.delete('playlists');
        _logger.info('Cleared playlists table');
      }
      
      if (mediaExists) {
        await db.delete('media');
        _logger.info('Cleared media table');
      }
      
      if (albumsExists) {
        await db.delete('albums');
        _logger.info('Cleared albums table');
      }
      
      if (artistsExists) {
        await db.delete('artists');
        _logger.info('Cleared artists table');
      }
    } catch (e) {
      _logger.error('Error clearing data: $e');
    }
  }

  Future<void> batchInsertMedia(List<Map<String, dynamic>> mediaList) async {
    try {
      final db = await database;
      final batch = db.batch();
      
      for (final media in mediaList) {
        batch.insert(
          'media',
          media,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      _logger.info('Batch inserted ${mediaList.length} media items');
    } catch (e) {
      _logger.error('Error in batch insert: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await database;
      final mediaCount = await db.query('media', columns: ['COUNT(*) as count']);
      final albumCount = await db.query('albums', columns: ['COUNT(*) as count']);
      final artistCount = await db.query('artists', columns: ['COUNT(*) as count']);
      
      return {
        'mediaCount': Sqflite.firstIntValue(mediaCount) ?? 0,
        'albumCount': Sqflite.firstIntValue(albumCount) ?? 0,
        'artistCount': Sqflite.firstIntValue(artistCount) ?? 0,
      };
    } catch (e) {
      _logger.error('Error getting database stats: $e');
      return {'mediaCount': 0, 'albumCount': 0, 'artistCount': 0};
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _logger.info('Database closed');
    }
  }

  Future<void> deleteDatabaseFile() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _logger.info('Database file deleted: $path');
      }
      _database = null;
    } catch (e) {
      _logger.error('Error deleting database file: $e');
    }
  }

  Future<void> recreateDatabase() async {
    try {
      await deleteDatabaseFile();
      _database = null;
      await database;
      _logger.info('Database recreated successfully');
    } catch (e) {
      _logger.error('Error recreating database: $e');
      rethrow;
    }
  }
}

// import 'dart:io';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import '../../../../core/constants/app_constants.dart';
// import '../../../../core/utils/helpers/logger_helper.dart';

// class MediaDatabase {
//   static final MediaDatabase _instance = MediaDatabase._internal();
//   Database? _database;
//   final LoggerHelper _logger = LoggerHelper();

//   MediaDatabase._internal();

//   factory MediaDatabase() => _instance;

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     try {
//       // Get the documents directory
//       final documentsDirectory = await getApplicationDocumentsDirectory();
//       final path = join(documentsDirectory.path, AppConstants.databaseName);
      
//       _logger.info('Database path: $path');

//       return await openDatabase(
//         path,
//         version: AppConstants.databaseVersion,
//         onCreate: _onCreate,
//         onUpgrade: _onUpgrade,
//         // Do NOT use onConfigure for PRAGMA statements that need transaction control
//       );
//     } catch (e) {
//       _logger.error('Error initializing database: $e');
//       rethrow;
//     }
//   }

//   Future<void> _onCreate(Database db, int version) async {
//     _logger.info('Creating database tables for version $version');
    
//     try {
//       // Create tables first
//       await _createTables(db);
      
//       // Then enable WAL mode after tables are created
//       // This is done outside the transaction by using a separate raw query
//       await _enableWALMode(db);
      
//       // Create indexes
//       await _createIndexes(db);
      
//       _logger.info('Database tables created successfully');
//     } catch (e) {
//       _logger.error('Error creating database tables: $e');
//       rethrow;
//     }
//   }

//   Future<void> _createTables(Database db) async {
//     // Create media table
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS media (
//         id TEXT PRIMARY KEY,
//         title TEXT NOT NULL,
//         artist TEXT NOT NULL,
//         album TEXT NOT NULL,
//         filePath TEXT NOT NULL UNIQUE,
//         fileName TEXT NOT NULL,
//         fileExtension TEXT NOT NULL,
//         fileSize INTEGER NOT NULL,
//         duration INTEGER NOT NULL,
//         albumArt TEXT,
//         mediaType TEXT NOT NULL,
//         dateAdded INTEGER NOT NULL,
//         dateModified INTEGER NOT NULL,
//         trackNumber INTEGER,
//         year INTEGER,
//         genre TEXT,
//         isFavorite INTEGER DEFAULT 0,
//         playCount INTEGER DEFAULT 0,
//         lastPlayed INTEGER DEFAULT 0,
//         bitrate REAL,
//         sampleRate INTEGER
//       )
//     ''');

//     // Create albums table
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS albums (
//         id TEXT PRIMARY KEY,
//         title TEXT NOT NULL,
//         artist TEXT NOT NULL,
//         year INTEGER,
//         albumArt TEXT,
//         trackCount INTEGER DEFAULT 0,
//         totalDuration INTEGER DEFAULT 0
//       )
//     ''');

//     // Create artists table
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS artists (
//         id TEXT PRIMARY KEY,
//         name TEXT NOT NULL UNIQUE,
//         albumCount INTEGER DEFAULT 0,
//         trackCount INTEGER DEFAULT 0,
//         image TEXT
//       )
//     ''');

//     // Create playlists table
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS playlists (
//         id TEXT PRIMARY KEY,
//         name TEXT NOT NULL,
//         description TEXT,
//         coverImage TEXT,
//         createdAt INTEGER NOT NULL,
//         updatedAt INTEGER NOT NULL,
//         trackCount INTEGER DEFAULT 0
//       )
//     ''');

//     // Create playlist_media junction table
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS playlist_media (
//         playlistId TEXT NOT NULL,
//         mediaId TEXT NOT NULL,
//         position INTEGER NOT NULL,
//         addedAt INTEGER NOT NULL,
//         PRIMARY KEY (playlistId, mediaId),
//         FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE,
//         FOREIGN KEY (mediaId) REFERENCES media(id) ON DELETE CASCADE
//       )
//     ''');
//   }

//   Future<void> _enableWALMode(Database db) async {
//     try {
//       // Execute PRAGMA outside of transaction
//       // Using rawQuery instead of execute to avoid transaction issues
//       final result = await db.rawQuery('PRAGMA journal_mode = WAL');
//       _logger.info('WAL mode enabled: ${result.first['journal_mode']}');
//     } catch (e) {
//       _logger.warning('Could not enable WAL mode: $e');
//       // Continue even if WAL mode fails - it's not critical
//     }
//   }

//   Future<void> _createIndexes(Database db) async {
//     try {
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_media_artist ON media(artist)');
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_media_album ON media(album)');
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_media_type ON media(mediaType)');
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_media_favorite ON media(isFavorite)');
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_media_last_played ON media(lastPlayed)');
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_media_file_path ON media(filePath)');
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_playlist_media_playlist ON playlist_media(playlistId)');
//       await db.execute('CREATE INDEX IF NOT EXISTS idx_playlist_media_media ON playlist_media(mediaId)');
      
//       _logger.info('Indexes created successfully');
//     } catch (e) {
//       _logger.warning('Error creating indexes: $e');
//       // Continue even if indexes fail
//     }
//   }

//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     _logger.info('Upgrading database from version $oldVersion to $newVersion');
    
//     try {
//       // Handle database upgrades here
//       if (oldVersion < 2) {
//         // Add new columns or tables for version 2
//         // Example: await db.execute('ALTER TABLE media ADD COLUMN newColumn TEXT');
//       }
      
//       _logger.info('Database upgrade completed');
//     } catch (e) {
//       _logger.error('Error upgrading database: $e');
//       rethrow;
//     }
//   }

//   // Alternative method to enable WAL mode after database is opened
//   Future<void> enableWALModeAfterOpen() async {
//     try {
//       final db = await database;
//       // Use rawQuery to execute PRAGMA
//       final result = await db.rawQuery('PRAGMA journal_mode = WAL');
//       _logger.info('WAL mode enabled after open: ${result.first['journal_mode']}');
//     } catch (e) {
//       _logger.warning('Could not enable WAL mode after open: $e');
//     }
//   }

//   // Check if a table exists
//   Future<bool> tableExists(String tableName) async {
//     try {
//       final db = await database;
//       final result = await db.query(
//         'sqlite_master',
//         where: 'type = ? AND name = ?',
//         whereArgs: ['table', tableName],
//       );
//       return result.isNotEmpty;
//     } catch (e) {
//       _logger.error('Error checking table existence: $e');
//       return false;
//     }
//   }

//   // Clear all data (useful for rescanning)
//   Future<void> clearAllData() async {
//     try {
//       final db = await database;
      
//       // Check if tables exist before deleting
//       final mediaExists = await tableExists('media');
//       final albumsExists = await tableExists('albums');
//       final artistsExists = await tableExists('artists');
//       final playlistsExists = await tableExists('playlists');
//       final playlistMediaExists = await tableExists('playlist_media');
      
//       if (playlistMediaExists) {
//         await db.delete('playlist_media');
//         _logger.info('Cleared playlist_media table');
//       }
      
//       if (playlistsExists) {
//         await db.delete('playlists');
//         _logger.info('Cleared playlists table');
//       }
      
//       if (mediaExists) {
//         await db.delete('media');
//         _logger.info('Cleared media table');
//       }
      
//       if (albumsExists) {
//         await db.delete('albums');
//         _logger.info('Cleared albums table');
//       }
      
//       if (artistsExists) {
//         await db.delete('artists');
//         _logger.info('Cleared artists table');
//       }
//     } catch (e) {
//       _logger.error('Error clearing data: $e');
//       // Don't rethrow - we can continue even if clear fails
//     }
//   }

//   // Batch insert for performance
//   Future<void> batchInsertMedia(List<Map<String, dynamic>> mediaList) async {
//     try {
//       final db = await database;
//       final batch = db.batch();
      
//       for (final media in mediaList) {
//         batch.insert(
//           'media',
//           media,
//           conflictAlgorithm: ConflictAlgorithm.replace,
//         );
//       }
      
//       await batch.commit(noResult: true);
//       _logger.info('Batch inserted ${mediaList.length} media items');
//     } catch (e) {
//       _logger.error('Error in batch insert: $e');
//       rethrow;
//     }
//   }

//   // Get database statistics
//   Future<Map<String, dynamic>> getDatabaseStats() async {
//     try {
//       final db = await database;
//       final mediaCount = await db.query('media', columns: ['COUNT(*) as count']);
//       final albumCount = await db.query('albums', columns: ['COUNT(*) as count']);
//       final artistCount = await db.query('artists', columns: ['COUNT(*) as count']);
      
//       return {
//         'mediaCount': Sqflite.firstIntValue(mediaCount) ?? 0,
//         'albumCount': Sqflite.firstIntValue(albumCount) ?? 0,
//         'artistCount': Sqflite.firstIntValue(artistCount) ?? 0,
//       };
//     } catch (e) {
//       _logger.error('Error getting database stats: $e');
//       return {'mediaCount': 0, 'albumCount': 0, 'artistCount': 0};
//     }
//   }

//   // Close database
//   Future<void> close() async {
//     final db = _database;
//     if (db != null) {
//       await db.close();
//       _database = null;
//       _logger.info('Database closed');
//     }
//   }

//   // Delete database file (useful for testing)
//   Future<void> deleteDatabaseFile() async {
//     try {
//       final documentsDirectory = await getApplicationDocumentsDirectory();
//       final path = join(documentsDirectory.path, AppConstants.databaseName);
//       final file = File(path);
//       if (await file.exists()) {
//         await file.delete();
//         _logger.info('Database file deleted: $path');
//       }
//       _database = null;
//     } catch (e) {
//       _logger.error('Error deleting database file: $e');
//     }
//   }

//   // Recreate database (useful for debugging)
//   Future<void> recreateDatabase() async {
//     try {
//       await deleteDatabaseFile();
//       _database = null;
//       await database;
//       _logger.info('Database recreated successfully');
//     } catch (e) {
//       _logger.error('Error recreating database: $e');
//       rethrow;
//     }
//   }
// }

// // import 'package:sqflite/sqflite.dart';
// // import 'package:path/path.dart';
// // import '../../../../core/constants/app_constants.dart';

// // class MediaDatabase {
// //   static final MediaDatabase _instance = MediaDatabase._internal();
// //   Database? _database;

// //   MediaDatabase._internal();

// //   factory MediaDatabase() => _instance;

// //   Future<Database> get database async {
// //     if (_database != null) return _database!;
// //     _database = await _initDatabase();
// //     return _database!;
// //   }

// //   Future<Database> _initDatabase() async {
// //     final databasesPath = await getDatabasesPath();
// //     final path = join(databasesPath, AppConstants.databaseName);

// //     return await openDatabase(
// //       path,
// //       version: AppConstants.databaseVersion,
// //       onCreate: _onCreate,
// //       onUpgrade: _onUpgrade,
// //     );
// //   }

// //   Future<void> _onCreate(Database db, int version) async {
// //     // Create media table
// //     await db.execute('''
// //       CREATE TABLE media (
// //         id TEXT PRIMARY KEY,
// //         title TEXT NOT NULL,
// //         artist TEXT NOT NULL,
// //         album TEXT NOT NULL,
// //         filePath TEXT NOT NULL UNIQUE,
// //         fileName TEXT NOT NULL,
// //         fileExtension TEXT NOT NULL,
// //         fileSize INTEGER NOT NULL,
// //         duration INTEGER NOT NULL,
// //         albumArt TEXT,
// //         mediaType TEXT NOT NULL,
// //         dateAdded INTEGER NOT NULL,
// //         dateModified INTEGER NOT NULL,
// //         trackNumber INTEGER,
// //         year INTEGER,
// //         genre TEXT,
// //         isFavorite INTEGER DEFAULT 0,
// //         playCount INTEGER DEFAULT 0,
// //         lastPlayed INTEGER DEFAULT 0,
// //         bitrate REAL,
// //         sampleRate INTEGER
// //       )
// //     ''');

// //     // Create albums table
// //     await db.execute('''
// //       CREATE TABLE albums (
// //         id TEXT PRIMARY KEY,
// //         title TEXT NOT NULL,
// //         artist TEXT NOT NULL,
// //         year INTEGER,
// //         albumArt TEXT,
// //         trackCount INTEGER DEFAULT 0,
// //         totalDuration INTEGER DEFAULT 0
// //       )
// //     ''');

// //     // Create artists table
// //     await db.execute('''
// //       CREATE TABLE artists (
// //         id TEXT PRIMARY KEY,
// //         name TEXT NOT NULL UNIQUE,
// //         albumCount INTEGER DEFAULT 0,
// //         trackCount INTEGER DEFAULT 0,
// //         image TEXT
// //       )
// //     ''');

// //     // Create playlists table
// //     await db.execute('''
// //       CREATE TABLE playlists (
// //         id TEXT PRIMARY KEY,
// //         name TEXT NOT NULL,
// //         description TEXT,
// //         coverImage TEXT,
// //         createdAt INTEGER NOT NULL,
// //         updatedAt INTEGER NOT NULL,
// //         trackCount INTEGER DEFAULT 0
// //       )
// //     ''');

// //     // Create playlist_media junction table
// //     await db.execute('''
// //       CREATE TABLE playlist_media (
// //         playlistId TEXT NOT NULL,
// //         mediaId TEXT NOT NULL,
// //         position INTEGER NOT NULL,
// //         addedAt INTEGER NOT NULL,
// //         PRIMARY KEY (playlistId, mediaId),
// //         FOREIGN KEY (playlistId) REFERENCES playlists(id) ON DELETE CASCADE,
// //         FOREIGN KEY (mediaId) REFERENCES media(id) ON DELETE CASCADE
// //       )
// //     ''');

// //     // Create indexes for better performance
// //     await db.execute(
// //       'CREATE INDEX idx_media_artist ON media(artist)'
// //     );
// //     await db.execute(
// //       'CREATE INDEX idx_media_album ON media(album)'
// //     );
// //     await db.execute(
// //       'CREATE INDEX idx_media_type ON media(mediaType)'
// //     );
// //     await db.execute(
// //       'CREATE INDEX idx_media_favorite ON media(isFavorite)'
// //     );
// //     await db.execute(
// //       'CREATE INDEX idx_media_last_played ON media(lastPlayed)'
// //     );
// //   }

// //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// //     // Handle database upgrades here
// //     if (oldVersion < 2) {
// //       // Add new columns or tables for version 2
// //     }
// //   }

// //   // Clear all data (useful for rescanning)
// //   Future<void> clearAllData() async {
// //     final db = await database;
// //     await db.delete('media');
// //     await db.delete('albums');
// //     await db.delete('artists');
// //   }

// //   // Batch insert for performance
// //   Future<void> batchInsertMedia(List<Map<String, dynamic>> mediaList) async {
// //     final db = await database;
// //     final batch = db.batch();
    
// //     for (final media in mediaList) {
// //       batch.insert(
// //         'media',
// //         media,
// //         conflictAlgorithm: ConflictAlgorithm.replace,
// //       );
// //     }
    
// //     await batch.commit(noResult: true);
// //   }

// //   // Close database
// //   Future<void> close() async {
// //     final db = _database;
// //     if (db != null) {
// //       await db.close();
// //       _database = null;
// //     }
// //   }
// // }