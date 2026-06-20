import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/helpers/logger_helper.dart';
import '../models/media_model.dart';
import 'media_database.dart';

class MediaScanner {
  final LoggerHelper _logger;
  final MediaDatabase _database;

  MediaScanner({
    required LoggerHelper logger,
    required MediaDatabase database,
  })  : _logger = logger,
        _database = database;

  // Scan all media files on device
  Future<List<MediaModel>> scanAllMedia() async {
    _logger.info('Starting media scan...');
    
    try {
      // Check permissions
      final permission = await _checkPermissions();
      if (!permission) {
        throw Exception('Storage permission denied');
      }

      final List<MediaModel> mediaFiles = [];
      
      // Get device storage directories
      final directories = await _getStorageDirectories();
      
      // Scan each directory
      for (final directory in directories) {
        final files = await _scanDirectory(directory);
        mediaFiles.addAll(files);
      }

      _logger.info('Scan complete. Found ${mediaFiles.length} media files');
      
      // Save to database
      await _saveToDatabase(mediaFiles);
      
      // Update albums and artists
      await _updateAlbumsAndArtists();
      
      return mediaFiles;
    } catch (e) {
      _logger.error('Error scanning media: $e');
      rethrow;
    }
  }

  Future<bool> _checkPermissions() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<List<String>> _getStorageDirectories() async {
    final directories = <String>[];
    
    // Android external storage
    if (Platform.isAndroid) {
      final externalStorage = '/storage/emulated/0';
      directories.add(externalStorage);
      
      // Common media directories
      directories.add('$externalStorage/Music');
      directories.add('$externalStorage/Download');
      directories.add('$externalStorage/DCIM');
      directories.add('$externalStorage/Video');
      directories.add('$externalStorage/Pictures');
      directories.add('$externalStorage/Movies');
      
      // External SD card if available
      final sdCard = '/storage/sdcard1';
      if (await Directory(sdCard).exists()) {
        directories.add(sdCard);
      }
    }
    
    return directories;
  }

  Future<List<MediaModel>> _scanDirectory(String directoryPath) async {
    final List<MediaModel> files = [];
    final directory = Directory(directoryPath);

    try {
      if (!await directory.exists()) {
        return files;
      }

      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final file = entity;
          final extension = path.extension(file.path).toLowerCase().substring(1);
          
          // Check if it's an audio file
          if (AppConstants.audioExtensions.contains(extension)) {
            final media = await _extractAudioMetadata(file);
            if (media != null) {
              files.add(media);
            }
          }
          // Check if it's a video file
          else if (AppConstants.videoExtensions.contains(extension)) {
            final media = await _extractVideoMetadata(file);
            if (media != null) {
              files.add(media);
            }
          }
        }
      }
    } catch (e) {
      _logger.error('Error scanning directory $directoryPath: $e');
    }

    return files;
  }

  Future<MediaModel?> _extractAudioMetadata(File file) async {
    try {
      final fileName = path.basename(file.path);
      final extension = path.extension(file.path).toLowerCase().substring(1);
      final fileSize = await file.length();
      final stat = await file.stat();
      final dateModified = stat.modified.millisecondsSinceEpoch;

      // Try to extract metadata using media_info package
      // For now, we'll use basic info
      // In production, use media_info or similar package
      
      String title = path.basenameWithoutExtension(file.path);
      String artist = 'Unknown Artist';
      String album = 'Unknown Album';
      int duration = 0;
      String? albumArt;
      int? trackNumber;
      int? year;
      String? genre;
      double? bitrate;
      int? sampleRate;

      // TODO: Use media_info package for real metadata extraction
      // For now, use placeholder values
      
      // Generate unique ID
      final id = 'audio_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

      return MediaModel(
        id: id,
        title: title,
        artist: artist,
        album: album,
        filePath: file.path,
        fileName: fileName,
        fileExtension: extension,
        fileSize: fileSize,
        duration: duration,
        albumArt: albumArt,
        mediaType: 'audio',
        dateAdded: dateModified,
        dateModified: dateModified,
        trackNumber: trackNumber,
        year: year,
        genre: genre,
        isFavorite: false,
        playCount: 0,
        lastPlayed: 0,
        bitrate: bitrate,
        sampleRate: sampleRate,
      );
    } catch (e) {
      _logger.error('Error extracting audio metadata from ${file.path}: $e');
      return null;
    }
  }

  Future<MediaModel?> _extractVideoMetadata(File file) async {
    try {
      final fileName = path.basename(file.path);
      final extension = path.extension(file.path).toLowerCase().substring(1);
      final fileSize = await file.length();
      final stat = await file.stat();
      final dateModified = stat.modified.millisecondsSinceEpoch;

      // Basic metadata
      String title = path.basenameWithoutExtension(file.path);
      String artist = 'Unknown Artist';
      String album = 'Unknown Album';
      int duration = 0;
      String? albumArt;

      // TODO: Use media_info package for real metadata extraction
      
      // Generate unique ID
      final id = 'video_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

      return MediaModel(
        id: id,
        title: title,
        artist: artist,
        album: album,
        filePath: file.path,
        fileName: fileName,
        fileExtension: extension,
        fileSize: fileSize,
        duration: duration,
        albumArt: albumArt,
        mediaType: 'video',
        dateAdded: dateModified,
        dateModified: dateModified,
        trackNumber: null,
        year: null,
        genre: null,
        isFavorite: false,
        playCount: 0,
        lastPlayed: 0,
        bitrate: null,
        sampleRate: null,
      );
    } catch (e) {
      _logger.error('Error extracting video metadata from ${file.path}: $e');
      return null;
    }
  }
  Future<void> _saveToDatabase(List<MediaModel> mediaFiles) async {
  try {
    // Check if media table exists
    final db = await _database.database;
    final tableExists = await _database.tableExists('media');
    
    if (!tableExists) {
      _logger.warning('Media table does not exist. Creating tables...');
      // Tables should have been created in _initDatabase, but just in case
      // we'll let the database handle it
      await _database.clearAllData();
    }
    
    // Clear existing data
    await _database.clearAllData();
    
    // Batch insert new data
    final batch = db.batch();
    
    for (final media in mediaFiles) {
      batch.insert(
        'media',
        media.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
    _logger.info('Saved ${mediaFiles.length} media files to database');
    
    // Update albums and artists
    await _updateAlbumsAndArtists();
  } catch (e) {
    _logger.error('Error saving media to database: $e');
    rethrow;
  }
}

  // Future<void> _saveToDatabase(List<MediaModel> mediaFiles) async {
  //   try {
  //     // Clear existing data
  //     await _database.clearAllData();
      
  //     // Batch insert new data
  //     final db = await _database.database;
  //     final batch = db.batch();
      
  //     for (final media in mediaFiles) {
  //       batch.insert(
  //         'media',
  //         media.toMap(),
  //         conflictAlgorithm: ConflictAlgorithm.replace,
  //       );
  //     }
      
  //     await batch.commit(noResult: true);
  //     _logger.info('Saved ${mediaFiles.length} media files to database');
  //   } catch (e) {
  //     _logger.error('Error saving media to database: $e');
  //     rethrow;
  //   }
  // }

  Future<void> _updateAlbumsAndArtists() async {
    try {
      final db = await _database.database;
      
      // Update albums
      await db.execute('''
        INSERT OR REPLACE INTO albums (id, title, artist, year, albumArt, trackCount, totalDuration)
        SELECT 
          substr(id, 1, 32) as id,
          album as title,
          artist,
          year,
          MAX(albumArt) as albumArt,
          COUNT(*) as trackCount,
          SUM(duration) as totalDuration
        FROM media
        WHERE album IS NOT NULL AND album != ''
        GROUP BY album, artist
      ''');
      
      // Update artists
      await db.execute('''
        INSERT OR REPLACE INTO artists (id, name, albumCount, trackCount)
        SELECT 
          substr(id, 1, 32) as id,
          artist as name,
          COUNT(DISTINCT album) as albumCount,
          COUNT(*) as trackCount
        FROM media
        WHERE artist IS NOT NULL AND artist != ''
        GROUP BY artist
      ''');
      
      _logger.info('Updated albums and artists');
    } catch (e) {
      _logger.error('Error updating albums and artists: $e');
    }
  }
}