// lib/features/mediadetection/data/repositories/media_repository_impl.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:media/features/mediadetection/domain/entities/album.dart';
import 'package:media/features/mediadetection/domain/entities/artist.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';
import 'package:media/features/mediadetection/domain/repositories/media_repository.dart';
import 'package:sqflite/sqflite.dart';
import '../datasources/media_database.dart';
import '../datasources/media_scanner.dart';
import '../models/media_model.dart';
import '../../../../core/utils/helpers/logger_helper.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaDatabase _database;
  final MediaScanner _scanner;
  final LoggerHelper _logger;

  MediaRepositoryImpl({
    required MediaDatabase database,
    required MediaScanner scanner,
    required LoggerHelper logger,
  })  : _database = database,
        _scanner = scanner,
        _logger = logger;

  @override
  Future<Either<Exception, List<Media>>> getAllMedia() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        orderBy: 'title COLLATE NOCASE ASC',
      );
      
      final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(mediaList);
    } catch (e) {
      _logger.error('Error getting all media: $e');
      return Left(Exception('Failed to get media: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Media>>> getAudioFiles() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        where: 'mediaType = ?',
        whereArgs: ['audio'],
        orderBy: 'title COLLATE NOCASE ASC',
      );
      
      final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(mediaList);
    } catch (e) {
      _logger.error('Error getting audio files: $e');
      return Left(Exception('Failed to get audio files: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Media>>> getVideoFiles() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        where: 'mediaType = ?',
        whereArgs: ['video'],
        orderBy: 'title COLLATE NOCASE ASC',
      );
      
      final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(mediaList);
    } catch (e) {
      _logger.error('Error getting video files: $e');
      return Left(Exception('Failed to get video files: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Media>>> searchMedia(String query) async {
    try {
      final db = await _database.database;
      final searchTerm = '%$query%';
      
      final result = await db.query(
        'media',
        where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
        whereArgs: [searchTerm, searchTerm, searchTerm],
        orderBy: 'title COLLATE NOCASE ASC',
      );
      
      final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(mediaList);
    } catch (e) {
      _logger.error('Error searching media: $e');
      return Left(Exception('Failed to search media: $e'));
    }
  }

  @override
  Future<Either<Exception, Media?>> getMediaById(String id) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result.isEmpty) return const Right(null);
      
      final media = MediaModel.fromMap(result.first).toEntity();
      return Right(media);
    } catch (e) {
      _logger.error('Error getting media by id: $e');
      return Left(Exception('Failed to get media: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> toggleFavorite(String mediaId) async {
    try {
      final db = await _database.database;
      
      final result = await db.query(
        'media',
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      if (result.isEmpty) {
        return Left(Exception('Media not found'));
      }
      
      final currentFavorite = (result.first['isFavorite'] as int) == 1;
      final newFavorite = currentFavorite ? 0 : 1;
      
      await db.update(
        'media',
        {'isFavorite': newFavorite},
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      return const Right(null);
    } catch (e) {
      _logger.error('Error toggling favorite: $e');
      return Left(Exception('Failed to toggle favorite: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> toggleFilterOut(String mediaId) async {
    try {
      final db = await _database.database;
      
      final result = await db.query(
        'media',
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      if (result.isEmpty) {
        return Left(Exception('Media not found'));
      }
      
      final currentFiltered = (result.first['isFilteredOut'] as int? ?? 0) == 1;
      final newFiltered = currentFiltered ? 0 : 1;
      
      await db.update(
        'media',
        {'isFilteredOut': newFiltered},
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      return const Right(null);
    } catch (e) {
      _logger.error('Error toggling filter out: $e');
      return Left(Exception('Failed to toggle filter out: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> deleteMedia(String mediaId) async {
    try {
      final db = await _database.database;
      
      // First check if the file exists on disk and delete it if it does
      final result = await db.query(
        'media',
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      if (result.isNotEmpty) {
        final filePath = result.first['filePath'] as String;
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            _logger.info('🗑️ Deleted file: $filePath');
          }
        } catch (e) {
          _logger.warning('⚠️ Could not delete file from disk: $e');
        }
      }
      
      // Delete from database
      await db.delete(
        'media',
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      return const Right(null);
    } catch (e) {
      _logger.error('Error deleting media: $e');
      return Left(Exception('Failed to delete media: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Media>>> getFavorites() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        where: 'isFavorite = 1',
        orderBy: 'title COLLATE NOCASE ASC',
      );
      
      final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(mediaList);
    } catch (e) {
      _logger.error('Error getting favorites: $e');
      return Left(Exception('Failed to get favorites: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Media>>> getRecentlyPlayed({int limit = 20}) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        where: 'lastPlayed > 0',
        orderBy: 'lastPlayed DESC',
        limit: limit,
      );
      
      final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(mediaList);
    } catch (e) {
      _logger.error('Error getting recently played: $e');
      return Left(Exception('Failed to get recently played: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Album>>> getAllAlbums() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'albums',
        orderBy: 'title COLLATE NOCASE ASC',
      );
      
      final albums = result.map((map) => Album(
        id: map['id'] as String,
        title: map['title'] as String,
        artist: map['artist'] as String,
        year: map['year'] as int? ?? 0,
        albumArt: map['albumArt'] as String?,
        trackCount: map['trackCount'] as int? ?? 0,
        totalDuration: map['totalDuration'] as int? ?? 0,
      )).toList();
      
      return Right(albums);
    } catch (e) {
      _logger.error('Error getting albums: $e');
      return Left(Exception('Failed to get albums: $e'));
    }
  }

  @override
  Future<Either<Exception, Album?>> getAlbumById(String albumId) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'albums',
        where: 'id = ?',
        whereArgs: [albumId],
      );
      
      if (result.isEmpty) return const Right(null);
      
      final map = result.first;
      final album = Album(
        id: map['id'] as String,
        title: map['title'] as String,
        artist: map['artist'] as String,
        year: map['year'] as int? ?? 0,
        albumArt: map['albumArt'] as String?,
        trackCount: map['trackCount'] as int? ?? 0,
        totalDuration: map['totalDuration'] as int? ?? 0,
      );
      
      return Right(album);
    } catch (e) {
      _logger.error('Error getting album by id: $e');
      return Left(Exception('Failed to get album: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Media>>> getAlbumTracks(String albumId) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        where: 'album = (SELECT title FROM albums WHERE id = ?)',
        whereArgs: [albumId],
        orderBy: 'trackNumber ASC, title ASC',
      );
      
      final tracks = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(tracks);
    } catch (e) {
      _logger.error('Error getting album tracks: $e');
      return Left(Exception('Failed to get album tracks: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Artist>>> getAllArtists() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'artists',
        orderBy: 'name COLLATE NOCASE ASC',
      );
      
      final artists = result.map((map) => Artist(
        id: map['id'] as String,
        name: map['name'] as String,
        albumCount: map['albumCount'] as int? ?? 0,
        trackCount: map['trackCount'] as int? ?? 0,
        image: map['image'] as String?,
      )).toList();
      
      return Right(artists);
    } catch (e) {
      _logger.error('Error getting artists: $e');
      return Left(Exception('Failed to get artists: $e'));
    }
  }

  @override
  Future<Either<Exception, Artist?>> getArtistById(String artistId) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'artists',
        where: 'id = ?',
        whereArgs: [artistId],
      );
      
      if (result.isEmpty) return const Right(null);
      
      final map = result.first;
      final artist = Artist(
        id: map['id'] as String,
        name: map['name'] as String,
        albumCount: map['albumCount'] as int? ?? 0,
        trackCount: map['trackCount'] as int? ?? 0,
        image: map['image'] as String?,
      );
      
      return Right(artist);
    } catch (e) {
      _logger.error('Error getting artist by id: $e');
      return Left(Exception('Failed to get artist: $e'));
    }
  }

  @override
  Future<Either<Exception, List<Media>>> getArtistTracks(String artistId) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        where: 'artist = (SELECT name FROM artists WHERE id = ?)',
        whereArgs: [artistId],
        orderBy: 'album ASC, trackNumber ASC',
      );
      
      final tracks = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
      return Right(tracks);
    } catch (e) {
      _logger.error('Error getting artist tracks: $e');
      return Left(Exception('Failed to get artist tracks: $e'));
    }
  }

  @override
  Future<Either<Exception, int>> getTotalMediaCount() async {
    try {
      final db = await _database.database;
      final result = await db.query('media', columns: ['COUNT(*) as count']);
      final count = Sqflite.firstIntValue(result) ?? 0;
      return Right(count);
    } catch (e) {
      _logger.error('Error getting total media count: $e');
      return Left(Exception('Failed to get media count: $e'));
    }
  }

  @override
  Future<Either<Exception, int>> getTotalAudioCount() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        columns: ['COUNT(*) as count'],
        where: 'mediaType = ?',
        whereArgs: ['audio'],
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      return Right(count);
    } catch (e) {
      _logger.error('Error getting total audio count: $e');
      return Left(Exception('Failed to get audio count: $e'));
    }
  }

  @override
  Future<Either<Exception, int>> getTotalVideoCount() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'media',
        columns: ['COUNT(*) as count'],
        where: 'mediaType = ?',
        whereArgs: ['video'],
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      return Right(count);
    } catch (e) {
      _logger.error('Error getting total video count: $e');
      return Left(Exception('Failed to get video count: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> scanMedia() async {
    try {
      await _scanner.scanAllMedia();
      return const Right(null);
    } catch (e) {
      _logger.error('Error scanning media: $e');
      return Left(Exception('Failed to scan media: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> rescanMedia() async {
    try {
      await _database.clearAllData();
      await _scanner.scanAllMedia();
      return const Right(null);
    } catch (e) {
      _logger.error('Error rescanning media: $e');
      return Left(Exception('Failed to rescan media: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> saveMedia(Media media) async {
    try {
      final db = await _database.database;
      final model = MediaModel.fromEntity(media);
      await db.insert(
        'media',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Right(null);
    } catch (e) {
      _logger.error('Error saving media: $e');
      return Left(Exception('Failed to save media: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> updateMedia(Media media) async {
    try {
      final db = await _database.database;
      final model = MediaModel.fromEntity(media);
      await db.update(
        'media',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [media.id],
      );
      return const Right(null);
    } catch (e) {
      _logger.error('Error updating media: $e');
      return Left(Exception('Failed to update media: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> addToRecentlyPlayed(String mediaId) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Get current play count
      final result = await db.query(
        'media',
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      if (result.isEmpty) {
        return Left(Exception('Media not found'));
      }
      
      final currentPlayCount = result.first['playCount'] as int? ?? 0;
      
      await db.update(
        'media',
        {
          'lastPlayed': now,
          'playCount': currentPlayCount + 1,
        },
        where: 'id = ?',
        whereArgs: [mediaId],
      );
      
      return const Right(null);
    } catch (e) {
      _logger.error('Error adding to recently played: $e');
      return Left(Exception('Failed to add to recently played: $e'));
    }
  }
}
// import 'package:dartz/dartz.dart';
// import 'package:media/features/mediadetection/domain/entities/album.dart';
// import 'package:media/features/mediadetection/domain/entities/artist.dart';
// import 'package:media/features/mediadetection/domain/entities/media.dart';
// import 'package:media/features/mediadetection/domain/repositories/media_repository.dart';
// import 'package:sqflite/sqflite.dart';
// import '../datasources/media_database.dart';
// import '../datasources/media_scanner.dart';
// import '../models/media_model.dart';
// import '../../../../core/utils/helpers/logger_helper.dart';

// class MediaRepositoryImpl implements MediaRepository {
//   final MediaDatabase _database;
//   final MediaScanner _scanner;
//   final LoggerHelper _logger;

//   MediaRepositoryImpl({
//     required MediaDatabase database,
//     required MediaScanner scanner,
//     required LoggerHelper logger,
//   })  : _database = database,
//         _scanner = scanner,
//         _logger = logger;

//   @override
//   Future<Either<Exception, List<Media>>> getAllMedia() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         orderBy: 'title COLLATE NOCASE ASC',
//       );
      
//       final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(mediaList);
//     } catch (e) {
//       _logger.error('Error getting all media: $e');
//       return Left(Exception('Failed to get media: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Media>>> getAudioFiles() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         where: 'mediaType = ?',
//         whereArgs: ['audio'],
//         orderBy: 'title COLLATE NOCASE ASC',
//       );
      
//       final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(mediaList);
//     } catch (e) {
//       _logger.error('Error getting audio files: $e');
//       return Left(Exception('Failed to get audio files: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Media>>> getVideoFiles() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         where: 'mediaType = ?',
//         whereArgs: ['video'],
//         orderBy: 'title COLLATE NOCASE ASC',
//       );
      
//       final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(mediaList);
//     } catch (e) {
//       _logger.error('Error getting video files: $e');
//       return Left(Exception('Failed to get video files: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, Media?>> getMediaById(String id) async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         where: 'id = ?',
//         whereArgs: [id],
//       );
      
//       if (result.isEmpty) return const Right(null);
      
//       final media = MediaModel.fromMap(result.first).toEntity();
//       return Right(media);
//     } catch (e) {
//       _logger.error('Error getting media by id: $e');
//       return Left(Exception('Failed to get media: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, void>> saveMedia(Media media) async {
//     try {
//       final db = await _database.database;
//       final model = MediaModel.fromEntity(media);
//       await db.insert(
//         'media',
//         model.toMap(),
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
//       return const Right(null);
//     } catch (e) {
//       _logger.error('Error saving media: $e');
//       return Left(Exception('Failed to save media: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, void>> deleteMedia(String id) async {
//     try {
//       final db = await _database.database;
//       await db.delete(
//         'media',
//         where: 'id = ?',
//         whereArgs: [id],
//       );
//       return const Right(null);
//     } catch (e) {
//       _logger.error('Error deleting media: $e');
//       return Left(Exception('Failed to delete media: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, void>> updateMedia(Media media) async {
//     try {
//       final db = await _database.database;
//       final model = MediaModel.fromEntity(media);
//       await db.update(
//         'media',
//         model.toMap(),
//         where: 'id = ?',
//         whereArgs: [media.id],
//       );
//       return const Right(null);
//     } catch (e) {
//       _logger.error('Error updating media: $e');
//       return Left(Exception('Failed to update media: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Album>>> getAllAlbums() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'albums',
//         orderBy: 'title COLLATE NOCASE ASC',
//       );
      
//       final albums = result.map((map) => Album(
//         id: map['id'] as String,
//         title: map['title'] as String,
//         artist: map['artist'] as String,
//         year: map['year'] as int? ?? 0,
//         albumArt: map['albumArt'] as String?,
//         trackCount: map['trackCount'] as int? ?? 0,
//         totalDuration: map['totalDuration'] as int? ?? 0,
//       )).toList();
      
//       return Right(albums);
//     } catch (e) {
//       _logger.error('Error getting albums: $e');
//       return Left(Exception('Failed to get albums: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, Album?>> getAlbumById(String id) async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'albums',
//         where: 'id = ?',
//         whereArgs: [id],
//       );
      
//       if (result.isEmpty) return const Right(null);
      
//       final map = result.first;
//       final album = Album(
//         id: map['id'] as String,
//         title: map['title'] as String,
//         artist: map['artist'] as String,
//         year: map['year'] as int? ?? 0,
//         albumArt: map['albumArt'] as String?,
//         trackCount: map['trackCount'] as int? ?? 0,
//         totalDuration: map['totalDuration'] as int? ?? 0,
//       );
      
//       return Right(album);
//     } catch (e) {
//       _logger.error('Error getting album by id: $e');
//       return Left(Exception('Failed to get album: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Media>>> getAlbumTracks(String albumId) async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         where: 'album = (SELECT title FROM albums WHERE id = ?)',
//         whereArgs: [albumId],
//         orderBy: 'trackNumber ASC, title ASC',
//       );
      
//       final tracks = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(tracks);
//     } catch (e) {
//       _logger.error('Error getting album tracks: $e');
//       return Left(Exception('Failed to get album tracks: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Artist>>> getAllArtists() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'artists',
//         orderBy: 'name COLLATE NOCASE ASC',
//       );
      
//       final artists = result.map((map) => Artist(
//         id: map['id'] as String,
//         name: map['name'] as String,
//         albumCount: map['albumCount'] as int? ?? 0,
//         trackCount: map['trackCount'] as int? ?? 0,
//         image: map['image'] as String?,
//       )).toList();
      
//       return Right(artists);
//     } catch (e) {
//       _logger.error('Error getting artists: $e');
//       return Left(Exception('Failed to get artists: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, Artist?>> getArtistById(String id) async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'artists',
//         where: 'id = ?',
//         whereArgs: [id],
//       );
      
//       if (result.isEmpty) return const Right(null);
      
//       final map = result.first;
//       final artist = Artist(
//         id: map['id'] as String,
//         name: map['name'] as String,
//         albumCount: map['albumCount'] as int? ?? 0,
//         trackCount: map['trackCount'] as int? ?? 0,
//         image: map['image'] as String?,
//       );
      
//       return Right(artist);
//     } catch (e) {
//       _logger.error('Error getting artist by id: $e');
//       return Left(Exception('Failed to get artist: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Media>>> getArtistTracks(String artistId) async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         where: 'artist = (SELECT name FROM artists WHERE id = ?)',
//         whereArgs: [artistId],
//         orderBy: 'album ASC, trackNumber ASC',
//       );
      
//       final tracks = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(tracks);
//     } catch (e) {
//       _logger.error('Error getting artist tracks: $e');
//       return Left(Exception('Failed to get artist tracks: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Media>>> getFavorites() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         where: 'isFavorite = 1',
//         orderBy: 'title COLLATE NOCASE ASC',
//       );
      
//       final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(mediaList);
//     } catch (e) {
//       _logger.error('Error getting favorites: $e');
//       return Left(Exception('Failed to get favorites: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, void>> toggleFavorite(String mediaId) async {
//     try {
//       final db = await _database.database;
      
//       // Get current favorite status
//       final result = await db.query(
//         'media',
//         where: 'id = ?',
//         whereArgs: [mediaId],
//       );
      
//       if (result.isEmpty) {
//         return Left(Exception('Media not found'));
//       }
      
//       final currentFavorite = (result.first['isFavorite'] as int) == 1;
//       final newFavorite = currentFavorite ? 0 : 1;
      
//       await db.update(
//         'media',
//         {'isFavorite': newFavorite},
//         where: 'id = ?',
//         whereArgs: [mediaId],
//       );
      
//       return const Right(null);
//     } catch (e) {
//       _logger.error('Error toggling favorite: $e');
//       return Left(Exception('Failed to toggle favorite: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Media>>> searchMedia(String query) async {
//     try {
//       final db = await _database.database;
//       final searchTerm = '%$query%';
      
//       final result = await db.query(
//         'media',
//         where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
//         whereArgs: [searchTerm, searchTerm, searchTerm],
//         orderBy: 'title COLLATE NOCASE ASC',
//       );
      
//       final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(mediaList);
//     } catch (e) {
//       _logger.error('Error searching media: $e');
//       return Left(Exception('Failed to search media: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, List<Media>>> getRecentlyPlayed({int limit = 20}) async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         where: 'lastPlayed > 0',
//         orderBy: 'lastPlayed DESC',
//         limit: limit,
//       );
      
//       final mediaList = result.map((map) => MediaModel.fromMap(map).toEntity()).toList();
//       return Right(mediaList);
//     } catch (e) {
//       _logger.error('Error getting recently played: $e');
//       return Left(Exception('Failed to get recently played: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, void>> addToRecentlyPlayed(String mediaId) async {
//     try {
//       final db = await _database.database;
//       final now = DateTime.now().millisecondsSinceEpoch;
      
//       // Update the media's lastPlayed timestamp
//       await db.update(
//         'media',
//         {
//           'lastPlayed': now,
//           'playCount': db.rawUpdate('playCount + 1'),
//         },
//         where: 'id = ?',
//         whereArgs: [mediaId],
//       );
      
//       return const Right(null);
//     } catch (e) {
//       _logger.error('Error adding to recently played: $e');
//       return Left(Exception('Failed to add to recently played: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, int>> getTotalMediaCount() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query('media', columns: ['COUNT(*) as count']);
//       final count = Sqflite.firstIntValue(result) ?? 0;
//       return Right(count);
//     } catch (e) {
//       _logger.error('Error getting total media count: $e');
//       return Left(Exception('Failed to get media count: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, int>> getTotalAudioCount() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         columns: ['COUNT(*) as count'],
//         where: 'mediaType = ?',
//         whereArgs: ['audio'],
//       );
//       final count = Sqflite.firstIntValue(result) ?? 0;
//       return Right(count);
//     } catch (e) {
//       _logger.error('Error getting total audio count: $e');
//       return Left(Exception('Failed to get audio count: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, int>> getTotalVideoCount() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query(
//         'media',
//         columns: ['COUNT(*) as count'],
//         where: 'mediaType = ?',
//         whereArgs: ['video'],
//       );
//       final count = Sqflite.firstIntValue(result) ?? 0;
//       return Right(count);
//     } catch (e) {
//       _logger.error('Error getting total video count: $e');
//       return Left(Exception('Failed to get video count: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, int>> getTotalDuration() async {
//     try {
//       final db = await _database.database;
//       final result = await db.query('media', columns: ['SUM(duration) as total']);
//       final total = Sqflite.firstIntValue(result) ?? 0;
//       return Right(total);
//     } catch (e) {
//       _logger.error('Error getting total duration: $e');
//       return Left(Exception('Failed to get total duration: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, void>> scanMedia() async {
//     try {
//       await _scanner.scanAllMedia();
//       return const Right(null);
//     } catch (e) {
//       _logger.error('Error scanning media: $e');
//       return Left(Exception('Failed to scan media: $e'));
//     }
//   }

//   @override
//   Future<Either<Exception, void>> rescanMedia() async {
//     try {
//       await _database.clearAllData();
//       await _scanner.scanAllMedia();
//       return const Right(null);
//     } catch (e) {
//       _logger.error('Error rescanning media: $e');
//       return Left(Exception('Failed to rescan media: $e'));
//     }
//   }
// }