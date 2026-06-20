// lib/features/audio_player/presentation/bloc/audio_player_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:just_audio/just_audio.dart' as just_audio;
import 'audio_player_event.dart';
import 'audio_player_state.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../data/services/audio_player_service.dart';
import '../../../../core/utils/helpers/logger_helper.dart';

class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  // Get the singleton instance
  final AudioPlayerService _playerService = AudioPlayerService();
  final LoggerHelper _logger = LoggerHelper();
  
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _queueSubscription;
  
  // Track if we've already initialized listeners
  bool _isInitialized = false;

  AudioPlayerBloc() : super(const AudioPlayerState()) {
    // Register event handlers
    on<PlayMedia>(_onPlayMedia);
    on<PlayQueue>(_onPlayQueue);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<Play>(_onPlay);
    on<Pause>(_onPause);
    on<Stop>(_onStop);
    on<Seek>(_onSeek);
    on<NextTrack>(_onNextTrack);
    on<PreviousTrack>(_onPreviousTrack);
    on<SetVolume>(_onSetVolume);
    on<SetSpeed>(_onSetSpeed);
    on<SetRepeatMode>(_onSetRepeatMode);
    on<ToggleShuffle>(_onToggleShuffle);
    on<RemoveFromQueue>(_onRemoveFromQueue);
    on<ClearQueue>(_onClearQueue);
    on<UpdatePosition>(_onUpdatePosition);

    _initializeListeners();
  }

  void _initializeListeners() {
    // Prevent multiple initialization
    if (_isInitialized) {
      _logger.debug('Listeners already initialized');
      return;
    }
    
    _logger.debug('Initializing listeners');
    _isInitialized = true;

    // Cancel any existing subscriptions first
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _queueSubscription?.cancel();

    try {
      // Listen to position changes
      _positionSubscription = _playerService.positionStream.listen(
        (position) {
          if (!isClosed) {
            add(UpdatePosition(position));
          }
        },
        onError: (error) {
          _logger.error('Position stream error: $error');
        },
      );

      // Listen to duration changes
      _durationSubscription = _playerService.durationStream.listen(
        (duration) {
          if (!isClosed && duration != null) {
            // Only update if duration changed
            if (state.duration != duration) {
              emit(state.copyWith(duration: duration));
            }
          }
        },
        onError: (error) {
          _logger.error('Duration stream error: $error');
        },
      );

      // Listen to player state changes
      _stateSubscription = _playerService.playerStateStream.listen(
        (playerState) {
          if (!isClosed) {
            final isPlaying = playerState.playing;
            final isBuffering = playerState.processingState == just_audio.ProcessingState.buffering;
            
            // Only update if state changed
            if (state.isPlaying != isPlaying || state.isBuffering != isBuffering) {
              emit(state.copyWith(
                isPlaying: isPlaying,
                isBuffering: isBuffering,
              ));
            }
          }
        },
        onError: (error) {
          _logger.error('Player state stream error: $error');
        },
      );

      // Listen to queue changes
      _queueSubscription = _playerService.queueStream.listen(
        (queue) {
          if (!isClosed) {
            emit(state.copyWith(queue: queue));
          }
        },
        onError: (error) {
          _logger.error('Queue stream error: $error');
        },
      );

      _logger.debug('All listeners initialized successfully');
    } catch (e) {
      _logger.error('Error initializing listeners: $e');
    }
  }

  Future<void> _onPlayMedia(PlayMedia event, Emitter<AudioPlayerState> emit) async {
    try {
      _logger.info('PlayMedia event received: ${event.media.title}');
      
      emit(state.copyWith(
        isBuffering: true,
        hasError: false,
        errorMessage: null,
      ));

      await _playerService.playMedia(event.media, queue: event.queue);

      emit(state.copyWith(
        currentMedia: event.media,
        isPlaying: true,
        isBuffering: false,
        position: Duration.zero,
        hasError: false,
      ));
      
      _logger.info('Media playing successfully');
    } catch (e) {
      _logger.error('Error playing media: $e');
      emit(state.copyWith(
        isBuffering: false,
        hasError: true,
        errorMessage: 'Failed to play media: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPlayQueue(PlayQueue event, Emitter<AudioPlayerState> emit) async {
    try {
      _logger.info('PlayQueue event received with ${event.queue.length} items');
      
      emit(state.copyWith(
        isBuffering: true,
        hasError: false,
        errorMessage: null,
      ));

      await _playerService.playQueue(event.queue, startIndex: event.startIndex);

      emit(state.copyWith(
        currentMedia: event.queue[event.startIndex],
        queue: event.queue,
        currentIndex: event.startIndex,
        isPlaying: true,
        isBuffering: false,
        position: Duration.zero,
        hasError: false,
      ));
      
      _logger.info('Queue playing successfully');
    } catch (e) {
      _logger.error('Error playing queue: $e');
      emit(state.copyWith(
        isBuffering: false,
        hasError: true,
        errorMessage: 'Failed to play queue: ${e.toString()}',
      ));
    }
  }

  Future<void> _onTogglePlayPause(TogglePlayPause event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.togglePlayPause();
      emit(state.copyWith(isPlaying: _playerService.isPlaying));
    } catch (e) {
      _logger.error('Error toggling play/pause: $e');
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'Failed to toggle play/pause: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPlay(Play event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.play();
      emit(state.copyWith(isPlaying: true));
    } catch (e) {
      _logger.error('Error playing: $e');
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'Failed to play: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPause(Pause event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.pause();
      emit(state.copyWith(isPlaying: false));
    } catch (e) {
      _logger.error('Error pausing: $e');
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'Failed to pause: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStop(Stop event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.stop();
      emit(state.copyWith(
        isPlaying: false,
        position: Duration.zero,
      ));
    } catch (e) {
      _logger.error('Error stopping: $e');
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'Failed to stop: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSeek(Seek event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.seek(event.position);
      emit(state.copyWith(position: event.position));
    } catch (e) {
      _logger.error('Error seeking: $e');
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'Failed to seek: ${e.toString()}',
      ));
    }
  }

  Future<void> _onNextTrack(NextTrack event, Emitter<AudioPlayerState> emit) async {
    try {
      if (state.hasNext) {
        await _playerService.next();
        final currentMedia = await _playerService.currentMediaStream.first;
        emit(state.copyWith(
          currentMedia: currentMedia,
          isPlaying: true,
        ));
        _logger.debug('Playing next track');
      } else {
        _logger.debug('No next track available');
      }
    } catch (e) {
      _logger.error('Error playing next track: $e');
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'Failed to play next track: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPreviousTrack(PreviousTrack event, Emitter<AudioPlayerState> emit) async {
    try {
      if (state.hasPrevious) {
        await _playerService.previous();
        final currentMedia = await _playerService.currentMediaStream.first;
        emit(state.copyWith(
          currentMedia: currentMedia,
          isPlaying: true,
        ));
        _logger.debug('Playing previous track');
      } else {
        _logger.debug('No previous track available');
      }
    } catch (e) {
      _logger.error('Error playing previous track: $e');
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'Failed to play previous track: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSetVolume(SetVolume event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.setVolume(event.volume);
      emit(state.copyWith(volume: event.volume));
    } catch (e) {
      _logger.error('Error setting volume: $e');
    }
  }

  Future<void> _onSetSpeed(SetSpeed event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.setSpeed(event.speed);
      emit(state.copyWith(speed: event.speed));
    } catch (e) {
      _logger.error('Error setting speed: $e');
    }
  }

  Future<void> _onSetRepeatMode(SetRepeatMode event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.setRepeatMode(event.mode);
      emit(state.copyWith(repeatMode: event.mode));
      _logger.debug('Repeat mode set to: ${event.mode}');
    } catch (e) {
      _logger.error('Error setting repeat mode: $e');
    }
  }

  Future<void> _onToggleShuffle(ToggleShuffle event, Emitter<AudioPlayerState> emit) async {
    try {
      final newShuffleState = !state.isShuffleEnabled;
      await _playerService.setShuffle(newShuffleState);
      emit(state.copyWith(isShuffleEnabled: newShuffleState));
      _logger.debug('Shuffle set to: $newShuffleState');
    } catch (e) {
      _logger.error('Error toggling shuffle: $e');
    }
  }

  Future<void> _onRemoveFromQueue(RemoveFromQueue event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.removeFromQueue(event.index);
    } catch (e) {
      _logger.error('Error removing from queue: $e');
    }
  }

  Future<void> _onClearQueue(ClearQueue event, Emitter<AudioPlayerState> emit) async {
    try {
      await _playerService.clearQueue();
      emit(state.copyWith(
        queue: [],
        currentIndex: -1,
        currentMedia: null,
        isPlaying: false,
        position: Duration.zero,
      ));
      _logger.debug('Queue cleared');
    } catch (e) {
      _logger.error('Error clearing queue: $e');
    }
  }

  void _onUpdatePosition(UpdatePosition event, Emitter<AudioPlayerState> emit) {
    emit(state.copyWith(position: event.position));
  }

  @override
  Future<void> close() {
    _logger.info('Closing AudioPlayerBloc');
    
    // Cancel all subscriptions
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _queueSubscription?.cancel();
    
    // Reset initialization flag
    _isInitialized = false;
    
    // Don't dispose the service here - it's a singleton
    // The service will be disposed when the app closes
    
    return super.close();
  }
  
  // Add a method to manually reset the service if needed
  void resetService() {
    _logger.info('Resetting audio player service');
    _playerService.dispose();
    AudioPlayerService.reset();
    _isInitialized = false;
    _initializeListeners();
  }
}