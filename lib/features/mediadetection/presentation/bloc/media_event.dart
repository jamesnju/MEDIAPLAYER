import 'package:equatable/equatable.dart';

abstract class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedia extends MediaEvent {
  final String? mediaType; // 'audio', 'video', or null for all
  
  const LoadMedia({this.mediaType});
  
  @override
  List<Object?> get props => [mediaType];
}

class ScanMedia extends MediaEvent {}

class RescanMedia extends MediaEvent {}

class SearchMedia extends MediaEvent {
  final String query;
  
  const SearchMedia(this.query);
  
  @override
  List<Object?> get props => [query];
}

class ToggleFavorite extends MediaEvent {
  final String mediaId;
  
  const ToggleFavorite(this.mediaId);
  
  @override
  List<Object?> get props => [mediaId];
}

class LoadFavorites extends MediaEvent {}

class LoadRecentlyPlayed extends MediaEvent {
  final int limit;
  
  const LoadRecentlyPlayed({this.limit = 20});
  
  @override
  List<Object?> get props => [limit];
}

class LoadAlbums extends MediaEvent {}

class LoadArtists extends MediaEvent {}

class GetMediaById extends MediaEvent {
  final String id;
  
  const GetMediaById(this.id);
  
  @override
  List<Object?> get props => [id];
}

class GetAlbumTracks extends MediaEvent {
  final String albumId;
  
  const GetAlbumTracks(this.albumId);
  
  @override
  List<Object?> get props => [albumId];
}

class GetArtistTracks extends MediaEvent {
  final String artistId;
  
  const GetArtistTracks(this.artistId);
  
  @override
  List<Object?> get props => [artistId];
}