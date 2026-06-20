import 'package:equatable/equatable.dart';

enum MediaType { audio, video }

class Media extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSize; // in bytes
  final int duration; // in milliseconds
  final String? albumArt;
  final MediaType mediaType;
  final int dateAdded; // timestamp
  final int dateModified; // timestamp
  final int? trackNumber;
  final int? year;
  final String? genre;
  final bool isFavorite;
  final int playCount;
  final int lastPlayed; // timestamp
  final double? bitrate;
  final int? sampleRate;

  const Media({
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
  });

  Media copyWith({
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
    MediaType? mediaType,
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
  }) {
    return Media(
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
    );
  }

  String get formattedDuration {
    final int minutes = duration ~/ 60000;
    final int seconds = (duration % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1048576) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1073741824) {
      return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / 1073741824).toStringAsFixed(1)} GB';
  }

  bool get isAudio => mediaType == MediaType.audio;
  bool get isVideo => mediaType == MediaType.video;

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
      ];
}