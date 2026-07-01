// lib/features/mediadetection/data/models/media_model.dart
import 'package:equatable/equatable.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';

class MediaModel extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final int duration;
  final String? albumArt;
  final String mediaType;
  final int dateAdded;
  final int dateModified;
  final int? trackNumber;
  final int? year;
  final String? genre;
  final bool isFavorite;
  final int playCount;
  final int lastPlayed;
  final double? bitrate;
  final int? sampleRate;
  final bool isFilteredOut;

  const MediaModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.fileName,
    required this.fileExtension,
    required this.fileSize,
    required this.duration,
    this.albumArt,
    required this.mediaType,
    required this.dateAdded,
    required this.dateModified,
    this.trackNumber,
    this.year,
    this.genre,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayed = 0,
    this.bitrate,
    this.sampleRate,
    this.isFilteredOut = false,
  });

  factory MediaModel.fromEntity(Media media) {
    return MediaModel(
      id: media.id,
      title: media.title,
      artist: media.artist,
      album: media.album,
      filePath: media.path,
      fileName: media.fileName,
      fileExtension: media.fileExtension,
      fileSize: media.fileSize,
      duration: media.duration,
      albumArt: media.albumArt,
      mediaType: media.mediaType.name,
      dateAdded: media.dateAdded,
      dateModified: media.dateModified,
      trackNumber: media.trackNumber,
      year: media.year,
      genre: media.genre,
      isFavorite: media.isFavorite,
      playCount: media.playCount,
      lastPlayed: media.lastPlayed,
      bitrate: media.bitrate,
      sampleRate: media.sampleRate,
      isFilteredOut: media.isFilteredOut,
    );
  }

  Media toEntity() {
    return Media(
      id: id,
      title: title,
      artist: artist,
      album: album,
      path: filePath,
      fileName: fileName,
      fileExtension: fileExtension,
      fileSize: fileSize,
      duration: duration,
      albumArt: albumArt,
      mediaType: mediaType == 'audio' ? MediaType.audio : MediaType.video,
      dateAdded: dateAdded,
      dateModified: dateModified,
      trackNumber: trackNumber,
      year: year,
      genre: genre,
      isFavorite: isFavorite,
      playCount: playCount,
      lastPlayed: lastPlayed,
      bitrate: bitrate,
      sampleRate: sampleRate,
      isFilteredOut: isFilteredOut,
    );
  }

  factory MediaModel.fromMap(Map<String, dynamic> map) {
    return MediaModel(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      filePath: map['filePath'] as String,
      fileName: map['fileName'] as String,
      fileExtension: map['fileExtension'] as String,
      fileSize: map['fileSize'] as int,
      duration: map['duration'] as int,
      albumArt: map['albumArt'] as String?,
      mediaType: map['mediaType'] as String,
      dateAdded: map['dateAdded'] as int,
      dateModified: map['dateModified'] as int,
      trackNumber: map['trackNumber'] as int?,
      year: map['year'] as int?,
      genre: map['genre'] as String?,
      isFavorite: (map['isFavorite'] as int) == 1,
      playCount: map['playCount'] as int,
      lastPlayed: map['lastPlayed'] as int,
      bitrate: map['bitrate'] as double?,
      sampleRate: map['sampleRate'] as int?,
      isFilteredOut: (map['isFilteredOut'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'filePath': filePath,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileSize': fileSize,
      'duration': duration,
      'albumArt': albumArt,
      'mediaType': mediaType,
      'dateAdded': dateAdded,
      'dateModified': dateModified,
      'trackNumber': trackNumber,
      'year': year,
      'genre': genre,
      'isFavorite': isFavorite ? 1 : 0,
      'playCount': playCount,
      'lastPlayed': lastPlayed,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
      'isFilteredOut': isFilteredOut ? 1 : 0,
    };
  }

  MediaModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    String? fileName,
    String? fileExtension,
    int? fileSize,
    int? duration,
    String? albumArt,
    String? mediaType,
    int? dateAdded,
    int? dateModified,
    int? trackNumber,
    int? year,
    String? genre,
    bool? isFavorite,
    int? playCount,
    int? lastPlayed,
    double? bitrate,
    int? sampleRate,
    bool? isFilteredOut,
  }) {
    return MediaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      mediaType: mediaType ?? this.mediaType,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      isFilteredOut: isFilteredOut ?? this.isFilteredOut,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        filePath,
        fileName,
        fileExtension,
        fileSize,
        duration,
        albumArt,
        mediaType,
        dateAdded,
        dateModified,
        trackNumber,
        year,
        genre,
        isFavorite,
        playCount,
        lastPlayed,
        bitrate,
        sampleRate,
        isFilteredOut,
      ];
}
// import 'package:equatable/equatable.dart';
// import 'package:media/features/mediadetection/domain/entities/media.dart';

// class MediaModel extends Equatable {
//   final String id;
//   final String title;
//   final String artist;
//   final String album;
//   final String filePath;
//   final String fileName;
//   final String fileExtension;
//   final int fileSize;
//   final int duration;
//   final String? albumArt;
//   final String mediaType;
//   final int dateAdded;
//   final int dateModified;
//   final int? trackNumber;
//   final int? year;
//   final String? genre;
//   final bool isFavorite;
//   final int playCount;
//   final int lastPlayed;
//   final double? bitrate;
//   final int? sampleRate;

//   const MediaModel({
//     required this.id,
//     required this.title,
//     required this.artist,
//     required this.album,
//     required this.filePath,
//     required this.fileName,
//     required this.fileExtension,
//     required this.fileSize,
//     required this.duration,
//     this.albumArt,
//     required this.mediaType,
//     required this.dateAdded,
//     required this.dateModified,
//     this.trackNumber,
//     this.year,
//     this.genre,
//     this.isFavorite = false,
//     this.playCount = 0,
//     this.lastPlayed = 0,
//     this.bitrate,
//     this.sampleRate,
//   });

//   // Convert from Domain Entity to Model
//   factory MediaModel.fromEntity(Media media) {
//     return MediaModel(
//       id: media.id,
//       title: media.title,
//       artist: media.artist,
//       album: media.album,
//       filePath: media.filePath,
//       fileName: media.fileName,
//       fileExtension: media.fileExtension,
//       fileSize: media.fileSize,
//       duration: media.duration,
//       albumArt: media.albumArt,
//       mediaType: media.mediaType.name,
//       dateAdded: media.dateAdded,
//       dateModified: media.dateModified,
//       trackNumber: media.trackNumber,
//       year: media.year,
//       genre: media.genre,
//       isFavorite: media.isFavorite,
//       playCount: media.playCount,
//       lastPlayed: media.lastPlayed,
//       bitrate: media.bitrate,
//       sampleRate: media.sampleRate,
//     );
//   }

//   // Convert to Domain Entity
//   Media toEntity() {
//     return Media(
//       id: id,
//       title: title,
//       artist: artist,
//       album: album,
//       filePath: filePath,
//       fileName: fileName,
//       fileExtension: fileExtension,
//       fileSize: fileSize,
//       duration: duration,
//       albumArt: albumArt,
//       mediaType: mediaType == 'audio' ? MediaType.audio : MediaType.video,
//       dateAdded: dateAdded,
//       dateModified: dateModified,
//       trackNumber: trackNumber,
//       year: year,
//       genre: genre,
//       isFavorite: isFavorite,
//       playCount: playCount,
//       lastPlayed: lastPlayed,
//       bitrate: bitrate,
//       sampleRate: sampleRate,
//     );
//   }

//   // From Map (for database)
//   factory MediaModel.fromMap(Map<String, dynamic> map) {
//     return MediaModel(
//       id: map['id'] as String,
//       title: map['title'] as String,
//       artist: map['artist'] as String,
//       album: map['album'] as String,
//       filePath: map['filePath'] as String,
//       fileName: map['fileName'] as String,
//       fileExtension: map['fileExtension'] as String,
//       fileSize: map['fileSize'] as int,
//       duration: map['duration'] as int,
//       albumArt: map['albumArt'] as String?,
//       mediaType: map['mediaType'] as String,
//       dateAdded: map['dateAdded'] as int,
//       dateModified: map['dateModified'] as int,
//       trackNumber: map['trackNumber'] as int?,
//       year: map['year'] as int?,
//       genre: map['genre'] as String?,
//       isFavorite: (map['isFavorite'] as int) == 1,
//       playCount: map['playCount'] as int,
//       lastPlayed: map['lastPlayed'] as int,
//       bitrate: map['bitrate'] as double?,
//       sampleRate: map['sampleRate'] as int?,
//     );
//   }

//   // To Map (for database)
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'artist': artist,
//       'album': album,
//       'filePath': filePath,
//       'fileName': fileName,
//       'fileExtension': fileExtension,
//       'fileSize': fileSize,
//       'duration': duration,
//       'albumArt': albumArt,
//       'mediaType': mediaType,
//       'dateAdded': dateAdded,
//       'dateModified': dateModified,
//       'trackNumber': trackNumber,
//       'year': year,
//       'genre': genre,
//       'isFavorite': isFavorite ? 1 : 0,
//       'playCount': playCount,
//       'lastPlayed': lastPlayed,
//       'bitrate': bitrate,
//       'sampleRate': sampleRate,
//     };
//   }

//   @override
//   List<Object?> get props => [
//         id,
//         title,
//         artist,
//         album,
//         filePath,
//         fileName,
//         fileExtension,
//         fileSize,
//         duration,
//         albumArt,
//         mediaType,
//         dateAdded,
//         dateModified,
//         trackNumber,
//         year,
//         genre,
//         isFavorite,
//         playCount,
//         lastPlayed,
//         bitrate,
//         sampleRate,
//       ];
// }