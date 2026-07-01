// lib/features/mediadetection/presentation/bloc/media_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';
import 'package:media/features/mediadetection/domain/repositories/media_repository.dart';
import 'media_event.dart';
import 'media_state.dart';
import '../../../../core/utils/helpers/logger_helper.dart';
import '../../../../core/di/service_locator.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final MediaRepository _repository = ServiceLocator().mediaRepository;
  final LoggerHelper _logger = ServiceLocator().logger;

  MediaBloc() : super(MediaInitial()) {
    on<LoadMedia>(_onLoadMedia);
    on<ScanMedia>(_onScanMedia);
    on<RescanMedia>(_onRescanMedia);
    on<SearchMedia>(_onSearchMedia);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ToggleFilterOut>(_onToggleFilterOut);
    on<DeleteMultipleMedia>(_onDeleteMultipleMedia);
    on<DeleteMedia>(_onDeleteMedia);
    on<LoadFavorites>(_onLoadFavorites);
    on<LoadRecentlyPlayed>(_onLoadRecentlyPlayed);
    on<LoadAlbums>(_onLoadAlbums);
    on<LoadArtists>(_onLoadArtists);
    on<GetMediaById>(_onGetMediaById);
    on<GetAlbumTracks>(_onGetAlbumTracks);
    on<GetArtistTracks>(_onGetArtistTracks);
  }

  Future<void> _onLoadMedia(
    LoadMedia event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final result = event.mediaType == null
          ? await _repository.getAllMedia()
          : event.mediaType == 'audio'
              ? await _repository.getAudioFiles()
              : await _repository.getVideoFiles();

      final totalCountResult = await _repository.getTotalMediaCount();
      final audioCountResult = await _repository.getTotalAudioCount();
      final videoCountResult = await _repository.getTotalVideoCount();

      final media = result.fold(
        (failure) => <Media>[],
        (mediaList) => mediaList,
      );

      final totalCount = totalCountResult.fold(
        (failure) => 0,
        (count) => count,
      );

      final audioCount = audioCountResult.fold(
        (failure) => 0,
        (count) => count,
      );

      final videoCount = videoCountResult.fold(
        (failure) => 0,
        (count) => count,
      );

      if (media.isEmpty && totalCount == 0) {
        add(ScanMedia());
        return;
      }

      emit(MediaLoaded(
        media: media,
        totalCount: totalCount,
        audioCount: audioCount,
        videoCount: videoCount,
      ));
    } catch (e) {
      _logger.error('Error loading media: $e');
      emit(MediaError('Failed to load media: $e'));
    }
  }

  Future<void> _onScanMedia(
    ScanMedia event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final result = await _repository.scanMedia();
      
      result.fold(
        (failure) => emit(MediaError('Failed to scan media: $failure')),
        (_) {
          add(LoadMedia());
        },
      );
    } catch (e) {
      _logger.error('Error scanning media: $e');
      emit(MediaError('Failed to scan media: $e'));
    }
  }

  Future<void> _onRescanMedia(
    RescanMedia event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final result = await _repository.rescanMedia();
      
      result.fold(
        (failure) => emit(MediaError('Failed to rescan media: $failure')),
        (_) {
          add(LoadMedia());
        },
      );
    } catch (e) {
      _logger.error('Error rescanning media: $e');
      emit(MediaError('Failed to rescan media: $e'));
    }
  }

  Future<void> _onSearchMedia(
    SearchMedia event,
    Emitter<MediaState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(LoadMedia());
      return;
    }

    emit(MediaLoading());
    
    try {
      final result = await _repository.searchMedia(event.query);
      
      result.fold(
        (failure) => emit(MediaError('Failed to search: $failure')),
        (media) {
          emit(MediaLoaded(
            media: media,
            totalCount: media.length,
            audioCount: media.where((m) => m.isAudio).length,
            videoCount: media.where((m) => m.isVideo).length,
          ));
        },
      );
    } catch (e) {
      _logger.error('Error searching media: $e');
      emit(MediaError('Failed to search: $e'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<MediaState> emit,
  ) async {
    try {
      final result = await _repository.toggleFavorite(event.mediaId);
      
      result.fold(
        (failure) => emit(MediaError('Failed to toggle favorite: $failure')),
        (_) {
          emit(const MediaOperationSuccess('Favorite toggled successfully'));
          add(LoadMedia());
        },
      );
    } catch (e) {
      _logger.error('Error toggling favorite: $e');
      emit(MediaError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onToggleFilterOut(
    ToggleFilterOut event,
    Emitter<MediaState> emit,
  ) async {
    try {
      final result = await _repository.toggleFilterOut(event.mediaId);
      
      result.fold(
        (failure) => emit(MediaError('Failed to toggle filter: $failure')),
        (_) {
          emit(const MediaOperationSuccess('Filter toggled successfully'));
          add(LoadMedia());
        },
      );
    } catch (e) {
      _logger.error('Error toggling filter: $e');
      emit(MediaError('Failed to toggle filter: $e'));
    }
  }

  Future<void> _onDeleteMultipleMedia(
    DeleteMultipleMedia event,
    Emitter<MediaState> emit,
  ) async {
    try {
      for (final id in event.mediaIds) {
        await _repository.deleteMedia(id);
      }
      emit(MediaOperationSuccess('Successfully deleted ${event.mediaIds.length} files'));
      add(LoadMedia());
    } catch (e) {
      _logger.error('Error deleting media: $e');
      emit(MediaError('Failed to delete media: $e'));
    }
  }

  Future<void> _onDeleteMedia(
    DeleteMedia event,
    Emitter<MediaState> emit,
  ) async {
    try {
      await _repository.deleteMedia(event.mediaId);
      emit(const MediaOperationSuccess('Successfully deleted file'));
      add(LoadMedia());
    } catch (e) {
      _logger.error('Error deleting media: $e');
      emit(MediaError('Failed to delete media: $e'));
    }
  }

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final result = await _repository.getFavorites();
      
      result.fold(
        (failure) => emit(MediaError('Failed to load favorites: $failure')),
        (favorites) => emit(FavoritesLoaded(favorites)),
      );
    } catch (e) {
      _logger.error('Error loading favorites: $e');
      emit(MediaError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onLoadRecentlyPlayed(
    LoadRecentlyPlayed event,
    Emitter<MediaState> emit,
  ) async {
    try {
      final result = await _repository.getRecentlyPlayed(limit: event.limit);
      
      result.fold(
        (failure) => emit(MediaError('Failed to load recently played: $failure')),
        (recentlyPlayed) => emit(RecentlyPlayedLoaded(recentlyPlayed)),
      );
    } catch (e) {
      _logger.error('Error loading recently played: $e');
      emit(MediaError('Failed to load recently played: $e'));
    }
  }

  Future<void> _onLoadAlbums(
    LoadAlbums event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final result = await _repository.getAllAlbums();
      
      result.fold(
        (failure) => emit(MediaError('Failed to load albums: $failure')),
        (albums) => emit(AlbumsLoaded(albums)),
      );
    } catch (e) {
      _logger.error('Error loading albums: $e');
      emit(MediaError('Failed to load albums: $e'));
    }
  }

  Future<void> _onLoadArtists(
    LoadArtists event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final result = await _repository.getAllArtists();
      
      result.fold(
        (failure) => emit(MediaError('Failed to load artists: $failure')),
        (artists) => emit(ArtistsLoaded(artists)),
      );
    } catch (e) {
      _logger.error('Error loading artists: $e');
      emit(MediaError('Failed to load artists: $e'));
    }
  }

  Future<void> _onGetMediaById(
    GetMediaById event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final result = await _repository.getMediaById(event.id);
      
      result.fold(
        (failure) => emit(MediaError('Failed to load media: $failure')),
        (media) {
          if (media != null) {
            emit(MediaDetailLoaded(media));
          } else {
            emit(MediaError('Media not found'));
          }
        },
      );
    } catch (e) {
      _logger.error('Error getting media by id: $e');
      emit(MediaError('Failed to load media: $e'));
    }
  }

  Future<void> _onGetAlbumTracks(
    GetAlbumTracks event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final albumResult = await _repository.getAlbumById(event.albumId);
      final tracksResult = await _repository.getAlbumTracks(event.albumId);
      
      final album = albumResult.fold(
        (failure) => null,
        (album) => album,
      );
      
      final tracks = tracksResult.fold(
        (failure) => <Media>[],
        (tracks) => tracks,
      );
      
      if (album != null) {
        emit(AlbumTracksLoaded(tracks: tracks, album: album));
      } else {
        emit(MediaError('Album not found'));
      }
    } catch (e) {
      _logger.error('Error getting album tracks: $e');
      emit(MediaError('Failed to load album tracks: $e'));
    }
  }

  Future<void> _onGetArtistTracks(
    GetArtistTracks event,
    Emitter<MediaState> emit,
  ) async {
    emit(MediaLoading());
    
    try {
      final artistResult = await _repository.getArtistById(event.artistId);
      final tracksResult = await _repository.getArtistTracks(event.artistId);
      
      final artist = artistResult.fold(
        (failure) => null,
        (artist) => artist,
      );
      
      final tracks = tracksResult.fold(
        (failure) => <Media>[],
        (tracks) => tracks,
      );
      
      if (artist != null) {
        emit(ArtistTracksLoaded(tracks: tracks, artist: artist));
      } else {
        emit(MediaError('Artist not found'));
      }
    } catch (e) {
      _logger.error('Error getting artist tracks: $e');
      emit(MediaError('Failed to load artist tracks: $e'));
    }
  }
}

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:dartz/dartz.dart';
// import 'package:media/features/mediadetection/domain/entities/media.dart';
// import 'package:media/features/mediadetection/domain/repositories/media_repository.dart';
// import 'media_event.dart';
// import 'media_state.dart';
// import '../../../../core/utils/helpers/logger_helper.dart';
// import '../../../../core/di/service_locator.dart';

// class MediaBloc extends Bloc<MediaEvent, MediaState> {
//   final MediaRepository _repository = ServiceLocator().mediaRepository;
//   final LoggerHelper _logger = ServiceLocator().logger;

//   MediaBloc() : super(MediaInitial()) {
//     on<LoadMedia>(_onLoadMedia);
//     on<ScanMedia>(_onScanMedia);
//     on<RescanMedia>(_onRescanMedia);
//     on<SearchMedia>(_onSearchMedia);
//     on<ToggleFavorite>(_onToggleFavorite);
//     on<LoadFavorites>(_onLoadFavorites);
//     on<LoadRecentlyPlayed>(_onLoadRecentlyPlayed);
//     on<LoadAlbums>(_onLoadAlbums);
//     on<LoadArtists>(_onLoadArtists);
//     on<GetMediaById>(_onGetMediaById);
//     on<GetAlbumTracks>(_onGetAlbumTracks);
//     on<GetArtistTracks>(_onGetArtistTracks);
//     on<DeleteMultipleMedia>(_onDeleteMultipleMedia);
//     on<DeleteMedia>(_onDeleteMedia);

//   }

//   Future<void> _onLoadMedia(
//     LoadMedia event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final result = event.mediaType == null
//           ? await _repository.getAllMedia()
//           : event.mediaType == 'audio'
//               ? await _repository.getAudioFiles()
//               : await _repository.getVideoFiles();

//       final totalCountResult = await _repository.getTotalMediaCount();
//       final audioCountResult = await _repository.getTotalAudioCount();
//       final videoCountResult = await _repository.getTotalVideoCount();

//       final media = result.fold(
//         (failure) => <Media>[],
//         (mediaList) => mediaList,
//       );

//       final totalCount = totalCountResult.fold(
//         (failure) => 0,
//         (count) => count,
//       );

//       final audioCount = audioCountResult.fold(
//         (failure) => 0,
//         (count) => count,
//       );

//       final videoCount = videoCountResult.fold(
//         (failure) => 0,
//         (count) => count,
//       );

//       if (media.isEmpty && totalCount == 0) {
//         // No media found, trigger scan
//         add(ScanMedia());
//         return;
//       }

//       emit(MediaLoaded(
//         media: media,
//         totalCount: totalCount,
//         audioCount: audioCount,
//         videoCount: videoCount,
//       ));
//     } catch (e) {
//       _logger.error('Error loading media: $e');
//       emit(MediaError('Failed to load media: $e'));
//     }
//   }
//   Future<void> _onDeleteMultipleMedia(
//   DeleteMultipleMedia event,
//   Emitter<MediaState> emit,
// ) async {
//   try {
//     for (final id in event.mediaIds) {
//       await _repository.deleteMedia(id);
//     }
//     emit(MediaOperationSuccess('Successfully deleted ${event.mediaIds.length} files'));
//     add(LoadMedia()); // Refresh the list
//   } catch (e) {
//     _logger.error('Error deleting media: $e');
//     emit(MediaError('Failed to delete media: $e'));
//   }
// }

// Future<void> _onDeleteMedia(
//   DeleteMedia event,
//   Emitter<MediaState> emit,
// ) async {
//   try {
//     await _repository.deleteMedia(event.mediaId);
//     emit(const MediaOperationSuccess('Successfully deleted file'));
//     add(LoadMedia());
//   } catch (e) {
//     _logger.error('Error deleting media: $e');
//     emit(MediaError('Failed to delete media: $e'));
//   }
// }

//   Future<void> _onScanMedia(
//     ScanMedia event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final result = await _repository.scanMedia();
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to scan media: $failure')),
//         (_) {
//           // Reload media after scan
//           add(LoadMedia());
//         },
//       );
//     } catch (e) {
//       _logger.error('Error scanning media: $e');
//       emit(MediaError('Failed to scan media: $e'));
//     }
//   }

//   Future<void> _onRescanMedia(
//     RescanMedia event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final result = await _repository.rescanMedia();
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to rescan media: $failure')),
//         (_) {
//           // Reload media after rescan
//           add(LoadMedia());
//         },
//       );
//     } catch (e) {
//       _logger.error('Error rescanning media: $e');
//       emit(MediaError('Failed to rescan media: $e'));
//     }
//   }

//   Future<void> _onSearchMedia(
//     SearchMedia event,
//     Emitter<MediaState> emit,
//   ) async {
//     if (event.query.isEmpty) {
//       add(LoadMedia());
//       return;
//     }

//     emit(MediaLoading());
    
//     try {
//       final result = await _repository.searchMedia(event.query);
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to search: $failure')),
//         (media) {
//           emit(MediaLoaded(
//             media: media,
//             totalCount: media.length,
//             audioCount: media.where((m) => m.isAudio).length,
//             videoCount: media.where((m) => m.isVideo).length,
//           ));
//         },
//       );
//     } catch (e) {
//       _logger.error('Error searching media: $e');
//       emit(MediaError('Failed to search: $e'));
//     }
//   }

//   Future<void> _onToggleFavorite(
//     ToggleFavorite event,
//     Emitter<MediaState> emit,
//   ) async {
//     try {
//       final result = await _repository.toggleFavorite(event.mediaId);
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to toggle favorite: $failure')),
//         (_) {
//           emit(const MediaOperationSuccess('Favorite toggled successfully'));
//           // Reload to reflect changes
//           add(LoadMedia());
//         },
//       );
//     } catch (e) {
//       _logger.error('Error toggling favorite: $e');
//       emit(MediaError('Failed to toggle favorite: $e'));
//     }
//   }

//   Future<void> _onLoadFavorites(
//     LoadFavorites event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final result = await _repository.getFavorites();
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to load favorites: $failure')),
//         (favorites) => emit(FavoritesLoaded(favorites)),
//       );
//     } catch (e) {
//       _logger.error('Error loading favorites: $e');
//       emit(MediaError('Failed to load favorites: $e'));
//     }
//   }

//   Future<void> _onLoadRecentlyPlayed(
//     LoadRecentlyPlayed event,
//     Emitter<MediaState> emit,
//   ) async {
//     try {
//       final result = await _repository.getRecentlyPlayed(limit: event.limit);
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to load recently played: $failure')),
//         (recentlyPlayed) => emit(RecentlyPlayedLoaded(recentlyPlayed)),
//       );
//     } catch (e) {
//       _logger.error('Error loading recently played: $e');
//       emit(MediaError('Failed to load recently played: $e'));
//     }
//   }

//   Future<void> _onLoadAlbums(
//     LoadAlbums event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final result = await _repository.getAllAlbums();
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to load albums: $failure')),
//         (albums) => emit(AlbumsLoaded(albums)),
//       );
//     } catch (e) {
//       _logger.error('Error loading albums: $e');
//       emit(MediaError('Failed to load albums: $e'));
//     }
//   }

//   Future<void> _onLoadArtists(
//     LoadArtists event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final result = await _repository.getAllArtists();
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to load artists: $failure')),
//         (artists) => emit(ArtistsLoaded(artists)),
//       );
//     } catch (e) {
//       _logger.error('Error loading artists: $e');
//       emit(MediaError('Failed to load artists: $e'));
//     }
//   }

//   Future<void> _onGetMediaById(
//     GetMediaById event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final result = await _repository.getMediaById(event.id);
      
//       result.fold(
//         (failure) => emit(MediaError('Failed to load media: $failure')),
//         (media) {
//           if (media != null) {
//             emit(MediaDetailLoaded(media));
//           } else {
//             emit(MediaError('Media not found'));
//           }
//         },
//       );
//     } catch (e) {
//       _logger.error('Error getting media by id: $e');
//       emit(MediaError('Failed to load media: $e'));
//     }
//   }

//   Future<void> _onGetAlbumTracks(
//     GetAlbumTracks event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final albumResult = await _repository.getAlbumById(event.albumId);
//       final tracksResult = await _repository.getAlbumTracks(event.albumId);
      
//       final album = albumResult.fold(
//         (failure) => null,
//         (album) => album,
//       );
      
//       final tracks = tracksResult.fold(
//         (failure) => <Media>[],
//         (tracks) => tracks,
//       );
      
//       if (album != null) {
//         emit(AlbumTracksLoaded(tracks: tracks, album: album));
//       } else {
//         emit(MediaError('Album not found'));
//       }
//     } catch (e) {
//       _logger.error('Error getting album tracks: $e');
//       emit(MediaError('Failed to load album tracks: $e'));
//     }
//   }

//   Future<void> _onGetArtistTracks(
//     GetArtistTracks event,
//     Emitter<MediaState> emit,
//   ) async {
//     emit(MediaLoading());
    
//     try {
//       final artistResult = await _repository.getArtistById(event.artistId);
//       final tracksResult = await _repository.getArtistTracks(event.artistId);
      
//       final artist = artistResult.fold(
//         (failure) => null,
//         (artist) => artist,
//       );
      
//       final tracks = tracksResult.fold(
//         (failure) => <Media>[],
//         (tracks) => tracks,
//       );
      
//       if (artist != null) {
//         emit(ArtistTracksLoaded(tracks: tracks, artist: artist));
//       } else {
//         emit(MediaError('Artist not found'));
//       }
//     } catch (e) {
//       _logger.error('Error getting artist tracks: $e');
//       emit(MediaError('Failed to load artist tracks: $e'));
//     }
//   }
// }