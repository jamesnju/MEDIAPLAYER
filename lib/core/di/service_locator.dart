import 'package:media/features/mediadetection/data/datasources/media_database.dart';
import 'package:media/features/mediadetection/data/datasources/media_scanner.dart';
import 'package:media/features/mediadetection/data/repositories/media_repository_impl.dart';
import 'package:media/features/mediadetection/domain/repositories/media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../constants/app_constants.dart';
import '../utils/helpers/logger_helper.dart';


/// Manual Dependency Injection Container
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  
  // Private constructor
  ServiceLocator._internal();
  
  // Factory constructor
  factory ServiceLocator() => _instance;
  
  // Registered dependencies
  Database? _database;
  SharedPreferences? _sharedPreferences;
  LoggerHelper? _loggerHelper;
  MediaDatabase? _mediaDatabase;
  MediaScanner? _mediaScanner;
  MediaRepository? _mediaRepository;
  
  // Getters
  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call setup() first.');
    }
    return _database!;
  }
  
  SharedPreferences get sharedPreferences {
    if (_sharedPreferences == null) {
      throw Exception('SharedPreferences not initialized. Call setup() first.');
    }
    return _sharedPreferences!;
  }
  
  LoggerHelper get logger {
    if (_loggerHelper == null) {
      throw Exception('Logger not initialized. Call setup() first.');
    }
    return _loggerHelper!;
  }
  
  MediaDatabase get mediaDatabase {
    if (_mediaDatabase == null) {
      _mediaDatabase = MediaDatabase();
    }
    return _mediaDatabase!;
  }
  
  MediaScanner get mediaScanner {
    if (_mediaScanner == null) {
      _mediaScanner = MediaScanner(
        logger: logger,
        database: mediaDatabase,
      );
    }
    return _mediaScanner!;
  }
  
  MediaRepository get mediaRepository {
    if (_mediaRepository == null) {
      _mediaRepository = MediaRepositoryImpl(
        database: mediaDatabase,
        scanner: mediaScanner,
        logger: logger,
      );
    }
    return _mediaRepository!;
  }
  
  /// Initialize all dependencies
  static Future<void> setup() async {
    final locator = ServiceLocator();
    
    // Register logger first
    locator._registerLogger();
    
    // Initialize database with tables
    await locator._initializeDatabase();
    
    // Register shared preferences
    await locator._registerSharedPreferences();
    
    // Try to enable WAL mode after database is initialized
    await locator.mediaDatabase.enableWALModeAfterOpen();
    
    locator.logger.info('Service locator setup complete');
  }
  
  Future<void> _initializeDatabase() async {
    try {
      // Get the database instance which will create tables
      final db = await mediaDatabase.database;
      _database = db;
      
      // Verify tables were created
      final stats = await mediaDatabase.getDatabaseStats();
      logger.info('Database initialized with ${stats['mediaCount']} media, ${stats['albumCount']} albums, ${stats['artistCount']} artists');
      
      // Verify database is working
      await _verifyDatabase();
    } catch (e) {
      logger.error('Failed to initialize database: $e');
      rethrow;
    }
  }
  
  Future<void> _verifyDatabase() async {
    try {
      // Test database by checking if media table exists
      final exists = await mediaDatabase.tableExists('media');
      if (exists) {
        logger.info('Database verification successful: media table exists');
      } else {
        logger.warning('Database verification: media table does not exist');
      }
    } catch (e) {
      logger.warning('Database verification failed: $e');
    }
  }
  
  Future<void> _registerSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }
  
  void _registerLogger() {
    _loggerHelper = LoggerHelper();
  }
  
  /// Reset all dependencies (useful for testing)
  void reset() {
    _database = null;
    _sharedPreferences = null;
    _loggerHelper = null;
    _mediaDatabase = null;
    _mediaScanner = null;
    _mediaRepository = null;
  }
}

// import 'package:media/features/mediadetection/data/datasources/media_database.dart';
// import 'package:media/features/mediadetection/data/datasources/media_scanner.dart';
// import 'package:media/features/mediadetection/data/repositories/media_repository_impl.dart';
// import 'package:media/features/mediadetection/domain/repositories/media_repository.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// import '../constants/app_constants.dart';
// import '../utils/helpers/logger_helper.dart';

// /// Manual Dependency Injection Container
// class ServiceLocator {
//   static final ServiceLocator _instance = ServiceLocator._internal();
  
//   // Private constructor
//   ServiceLocator._internal();
  
//   // Factory constructor
//   factory ServiceLocator() => _instance;
  
//   // Registered dependencies
//   Database? _database;
//   SharedPreferences? _sharedPreferences;
//   LoggerHelper? _loggerHelper;
//   MediaDatabase? _mediaDatabase;
//   MediaScanner? _mediaScanner;
//   MediaRepository? _mediaRepository;
  
//   // Getters
//   Database get database {
//     if (_database == null) {
//       throw Exception('Database not initialized. Call setup() first.');
//     }
//     return _database!;
//   }
  
//   SharedPreferences get sharedPreferences {
//     if (_sharedPreferences == null) {
//       throw Exception('SharedPreferences not initialized. Call setup() first.');
//     }
//     return _sharedPreferences!;
//   }
  
//   LoggerHelper get logger {
//     if (_loggerHelper == null) {
//       throw Exception('Logger not initialized. Call setup() first.');
//     }
//     return _loggerHelper!;
//   }
  
//   MediaDatabase get mediaDatabase {
//     if (_mediaDatabase == null) {
//       _mediaDatabase = MediaDatabase();
//     }
//     return _mediaDatabase!;
//   }
  
//   MediaScanner get mediaScanner {
//     if (_mediaScanner == null) {
//       _mediaScanner = MediaScanner(
//         logger: logger,
//         database: mediaDatabase,
//       );
//     }
//     return _mediaScanner!;
//   }
  
//   MediaRepository get mediaRepository {
//     if (_mediaRepository == null) {
//       _mediaRepository = MediaRepositoryImpl(
//         database: mediaDatabase,
//         scanner: mediaScanner,
//         logger: logger,
//       );
//     }
//     return _mediaRepository!;
//   }
  
//   /// Initialize all dependencies
//   static Future<void> setup() async {
//     final locator = ServiceLocator();
//     await locator._registerDatabase();
//     await locator._registerSharedPreferences();
//     locator._registerLogger();
    
//     // Initialize media components (lazy-loaded)
//     // They will be initialized when first accessed
//   }
  
//   Future<void> _registerDatabase() async {
//     final database = await openDatabase(
//       join(await getDatabasesPath(), AppConstants.databaseName),
//       version: AppConstants.databaseVersion,
//       onCreate: (db, version) {
//         // Tables will be created by MediaDatabase
//       },
//     );
//     _database = database;
//   }
  
//   Future<void> _registerSharedPreferences() async {
//     _sharedPreferences = await SharedPreferences.getInstance();
//   }
  
//   void _registerLogger() {
//     _loggerHelper = LoggerHelper();
//   }
  
//   /// Reset all dependencies (useful for testing)
//   void reset() {
//     _database = null;
//     _sharedPreferences = null;
//     _loggerHelper = null;
//     _mediaDatabase = null;
//     _mediaScanner = null;
//     _mediaRepository = null;
//   }
// }