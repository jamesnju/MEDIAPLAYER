import 'package:equatable/equatable.dart';

class Album extends Equatable {
  final String id;
  final String title;
  final String artist;
  final int year;
  final String? albumArt;
  final int trackCount;
  final int totalDuration;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    this.albumArt,
    this.trackCount = 0,
    this.totalDuration = 0,
  });

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    int? year,
    String? albumArt,
    int? trackCount,
    int? totalDuration,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      year: year ?? this.year,
      albumArt: albumArt ?? this.albumArt,
      trackCount: trackCount ?? this.trackCount,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  String get formattedDuration {
    final int minutes = totalDuration ~/ 60000;
    final int seconds = (totalDuration % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        year,
        albumArt,
        trackCount,
        totalDuration,
      ];
}