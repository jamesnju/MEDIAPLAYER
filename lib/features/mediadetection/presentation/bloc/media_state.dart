// lib/features/mediadetection/presentation/bloc/media_state.dart
import 'package:equatable/equatable.dart';
import 'package:media/features/mediadetection/domain/entities/album.dart';
import 'package:media/features/mediadetection/domain/entities/artist.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';

abstract class MediaState extends Equatable {
  const MediaState();

  @override
  List<Object?> get props => [];
}

class MediaInitial extends MediaState {}

class MediaLoading extends MediaState {}

class MediaLoaded extends MediaState {
  final List<Media> media;
  final int totalCount;
  final int audioCount;
  final int videoCount;
  
  const MediaLoaded({
    required this.media,
    required this.totalCount,
    required this.audioCount,
    required this.videoCount,
  });
  
  @override
  List<Object?> get props => [media, totalCount, audioCount, videoCount];
}

class MediaError extends MediaState {
  final String message;
  
  const MediaError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class FavoritesLoaded extends MediaState {
  final List<Media> favorites;
  
  const FavoritesLoaded(this.favorites);
  
  @override
  List<Object?> get props => [favorites];
}

class RecentlyPlayedLoaded extends MediaState {
  final List<Media> recentlyPlayed;
  
  const RecentlyPlayedLoaded(this.recentlyPlayed);
  
  @override
  List<Object?> get props => [recentlyPlayed];
}

class AlbumsLoaded extends MediaState {
  final List<Album> albums;
  
  const AlbumsLoaded(this.albums);
  
  @override
  List<Object?> get props => [albums];
}

class ArtistsLoaded extends MediaState {
  final List<Artist> artists;
  
  const ArtistsLoaded(this.artists);
  
  @override
  List<Object?> get props => [artists];
}

class MediaDetailLoaded extends MediaState {
  final Media media;
  
  const MediaDetailLoaded(this.media);
  
  @override
  List<Object?> get props => [media];
}

class AlbumTracksLoaded extends MediaState {
  final List<Media> tracks;
  final Album album;
  
  const AlbumTracksLoaded({
    required this.tracks,
    required this.album,
  });
  
  @override
  List<Object?> get props => [tracks, album];
}

class ArtistTracksLoaded extends MediaState {
  final List<Media> tracks;
  final Artist artist;
  
  const ArtistTracksLoaded({
    required this.tracks,
    required this.artist,
  });
  
  @override
  List<Object?> get props => [tracks, artist];
}

class MediaOperationSuccess extends MediaState {
  final String message;
  
  const MediaOperationSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

// import 'package:equatable/equatable.dart';
// import 'package:media/features/mediadetection/domain/entities/album.dart';
// import 'package:media/features/mediadetection/domain/entities/artist.dart';
// import 'package:media/features/mediadetection/domain/entities/media.dart';

// abstract class MediaState extends Equatable {
//   const MediaState();

//   @override
//   List<Object?> get props => [];
// }

// class MediaInitial extends MediaState {}

// class MediaLoading extends MediaState {}

// class MediaLoaded extends MediaState {
//   final List<Media> media;
//   final int totalCount;
//   final int audioCount;
//   final int videoCount;
  
//   const MediaLoaded({
//     required this.media,
//     required this.totalCount,
//     required this.audioCount,
//     required this.videoCount,
//   });
  
//   @override
//   List<Object?> get props => [media, totalCount, audioCount, videoCount];
// }

// class MediaError extends MediaState {
//   final String message;
  
//   const MediaError(this.message);
  
//   @override
//   List<Object?> get props => [message];
// }

// class FavoritesLoaded extends MediaState {
//   final List<Media> favorites;
  
//   const FavoritesLoaded(this.favorites);
  
//   @override
//   List<Object?> get props => [favorites];
// }

// class RecentlyPlayedLoaded extends MediaState {
//   final List<Media> recentlyPlayed;
  
//   const RecentlyPlayedLoaded(this.recentlyPlayed);
  
//   @override
//   List<Object?> get props => [recentlyPlayed];
// }

// class AlbumsLoaded extends MediaState {
//   final List<Album> albums;
  
//   const AlbumsLoaded(this.albums);
  
//   @override
//   List<Object?> get props => [albums];
// }

// class ArtistsLoaded extends MediaState {
//   final List<Artist> artists;
  
//   const ArtistsLoaded(this.artists);
  
//   @override
//   List<Object?> get props => [artists];
// }

// class MediaDetailLoaded extends MediaState {
//   final Media media;
  
//   const MediaDetailLoaded(this.media);
  
//   @override
//   List<Object?> get props => [media];
// }

// class AlbumTracksLoaded extends MediaState {
//   final List<Media> tracks;
//   final Album album;
  
//   const AlbumTracksLoaded({
//     required this.tracks,
//     required this.album,
//   });
  
//   @override
//   List<Object?> get props => [tracks, album];
// }

// class ArtistTracksLoaded extends MediaState {
//   final List<Media> tracks;
//   final Artist artist;
  
//   const ArtistTracksLoaded({
//     required this.tracks,
//     required this.artist,
//   });
  
//   @override
//   List<Object?> get props => [tracks, artist];
// }

// class MediaOperationSuccess extends MediaState {
//   final String message;
  
//   const MediaOperationSuccess(this.message);
  
//   @override
//   List<Object?> get props => [message];
// }