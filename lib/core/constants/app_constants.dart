class AppConstants {
  static const String appName = 'MediaPlayer';
  static const String appVersion = '1.0.0';
  
  // Shared Preferences Keys
  static const String keyThemeMode = 'themeMode';
  static const String keyFirstLaunch = 'firstLaunch';
  static const String keyDefaultPlayerSet = 'defaultPlayerSet';
  
  // Database
  static const String databaseName = 'mediaplayer.db';
  static const int databaseVersion = 1;
  
  // Cache
  static const int maxCacheSizeMB = 500;
  static const int thumbnailCacheSize = 100;
  
  // Media Types
  static const List<String> audioExtensions = [
    'mp3', 'wav', 'aac', 'flac', 'm4a', 'ogg', 'wma'
  ];
  static const List<String> videoExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', '3gp'
  ];
  
  // Player
  static const Duration seekStep = Duration(seconds: 10);
  static const Duration rewindStep = Duration(seconds: 10);
}