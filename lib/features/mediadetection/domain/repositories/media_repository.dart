// lib/features/mediadetection/domain/repositories/media_repository.dart
import 'package:dartz/dartz.dart';
import 'package:media/features/mediadetection/domain/entities/album.dart';
import 'package:media/features/mediadetection/domain/entities/artist.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';

abstract class MediaRepository {
  Future<Either<Exception, List<Media>>> getAllMedia();
  Future<Either<Exception, List<Media>>> getAudioFiles();
  Future<Either<Exception, List<Media>>> getVideoFiles();
  Future<Either<Exception, List<Media>>> searchMedia(String query);
  Future<Either<Exception, Media?>> getMediaById(String id);
  Future<Either<Exception, void>> toggleFavorite(String mediaId);
  Future<Either<Exception, void>> toggleFilterOut(String mediaId);
  Future<Either<Exception, void>> deleteMedia(String mediaId);
  Future<Either<Exception, List<Media>>> getFavorites();
  Future<Either<Exception, List<Media>>> getRecentlyPlayed({int limit = 20});
  Future<Either<Exception, List<Album>>> getAllAlbums();
  Future<Either<Exception, List<Artist>>> getAllArtists();
  Future<Either<Exception, Album?>> getAlbumById(String albumId);
  Future<Either<Exception, Artist?>> getArtistById(String artistId);
  Future<Either<Exception, List<Media>>> getAlbumTracks(String albumId);
  Future<Either<Exception, List<Media>>> getArtistTracks(String artistId);
  Future<Either<Exception, int>> getTotalMediaCount();
  Future<Either<Exception, int>> getTotalAudioCount();
  Future<Either<Exception, int>> getTotalVideoCount();
  Future<Either<Exception, void>> scanMedia();
  Future<Either<Exception, void>> rescanMedia();
}

// import 'package:dartz/dartz.dart';
// import '../entities/media.dart';
// import '../entities/album.dart';
// import '../entities/artist.dart';

// abstract class MediaRepository {
//   // Media operations
//   Future<Either<Exception, List<Media>>> getAllMedia();
//   Future<Either<Exception, List<Media>>> getAudioFiles();
//   Future<Either<Exception, List<Media>>> getVideoFiles();
//   Future<Either<Exception, Media?>> getMediaById(String id);
//   Future<Either<Exception, void>> saveMedia(Media media);
//   Future<Either<Exception, void>> deleteMedia(String id);
//   Future<Either<Exception, void>> updateMedia(Media media);
  
//   // Album operations
//   Future<Either<Exception, List<Album>>> getAllAlbums();
//   Future<Either<Exception, Album?>> getAlbumById(String id);
//   Future<Either<Exception, List<Media>>> getAlbumTracks(String albumId);
  
//   // Artist operations
//   Future<Either<Exception, List<Artist>>> getAllArtists();
//   Future<Either<Exception, Artist?>> getArtistById(String id);
//   Future<Either<Exception, List<Media>>> getArtistTracks(String artistId);
  
//   // Favorites
//   Future<Either<Exception, List<Media>>> getFavorites();
//   Future<Either<Exception, void>> toggleFavorite(String mediaId);
  
//   // Search
//   Future<Either<Exception, List<Media>>> searchMedia(String query);
  
//   // Recently played
//   Future<Either<Exception, List<Media>>> getRecentlyPlayed({int limit = 20});
//   Future<Either<Exception, void>> addToRecentlyPlayed(String mediaId);
  
//   // Statistics
//   Future<Either<Exception, int>> getTotalMediaCount();
//   Future<Either<Exception, int>> getTotalAudioCount();
//   Future<Either<Exception, int>> getTotalVideoCount();
//   Future<Either<Exception, int>> getTotalDuration();
  
//   // Scan
//   Future<Either<Exception, void>> scanMedia();
//   Future<Either<Exception, void>> rescanMedia();
// }