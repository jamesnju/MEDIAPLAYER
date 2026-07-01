// lib/features/audio_player/data/services/audio_player_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:just_audio/just_audio.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../../../core/utils/helpers/logger_helper.dart';

class AudioPlayerService {
  static AudioPlayerService? _instance;
  static bool _isDisposed = false;
  
  final AudioPlayer _player = AudioPlayer();
  final LoggerHelper _logger = LoggerHelper();
  
  List<Media> _queue = [];
  int _queueIndex = -1;
  String? _currentMediaId;
  
  ConcatenatingAudioSource? _audioSource;
  
  final BehaviorSubject<List<Media>> _queueSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _queueIndexSubject = BehaviorSubject.seeded(-1);
  final BehaviorSubject<Media?> _currentMediaSubject = BehaviorSubject.seeded(null);
  
  // New subjects for duration updates
  final BehaviorSubject<Duration> _positionSubject = BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<Duration?> _durationSubject = BehaviorSubject.seeded(null);
  
  AudioPlayerService._internal() {
    _logger.info('🔄 AudioPlayerService._internal() - Creating new instance');
    _initializePlayer();
  }

  factory AudioPlayerService() {
    if (_instance == null || _isDisposed) {
      _instance = AudioPlayerService._internal();
      _isDisposed = false;
    }
    return _instance!;
  }

  void _initializePlayer() {
    _logger.info('🔧 _initializePlayer() - Setting up player listeners');
    try {
      _player.playerStateStream.listen((state) {
        _logger.debug('📊 Player state: ${state.processingState}, Playing: ${state.playing}');
        
        if (state.processingState == ProcessingState.completed) {
          _logger.info('⏹️ Playback COMPLETED - Auto-playing next');
          _onPlaybackComplete();
        }
      });

      // Listen to position changes with debounce for performance
      _player.positionStream.listen((position) {
        _positionSubject.add(position);
      });

      // Listen to duration changes
      _player.durationStream.listen((duration) {
        _durationSubject.add(duration);
        if (duration != null) {
          _logger.debug('⏱️ Duration: ${duration.inSeconds}s');
        }
      });

      // Listen to current index changes
      _player.currentIndexStream.listen((index) {
        if (index != null) {
          _logger.debug('📌 Current index: $index');
          _queueIndex = index;
          _queueIndexSubject.add(index);
          if (index < _queue.length) {
            _currentMediaId = _queue[index].id;
            _currentMediaSubject.add(_queue[index]);
            _logger.debug('📌 Current media: ${_queue[index].title}');
          }
        }
      });

      // Listen to shuffle mode changes
      _player.shuffleModeEnabledStream.listen((enabled) {
        _logger.info('🔀 Shuffle mode: $enabled');
      });

      // Listen to loop mode changes
      _player.loopModeStream.listen((mode) {
        _logger.info('🔁 Loop mode: $mode');
      });

      _logger.info('✅ _initializePlayer() - All listeners set up successfully');
    } catch (e) {
      _logger.error('❌ Error initializing player: $e');
    }
  }

  void _onPlaybackComplete() {
    _logger.info('🎵 Playback completed, checking for next track...');
    if (hasNext) {
      _logger.info('⏭️ Moving to next track automatically');
      _player.seekToNext();
    } else if (_player.loopMode == LoopMode.all) {
      _logger.info('🔄 Loop all enabled, going to first track');
      _player.seekToPrevious();
    } else {
      _logger.info('📋 End of queue reached');
    }
  }

  // Getters
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _positionSubject.stream;
  Stream<Duration?> get durationStream => _durationSubject.stream;
  Stream<List<Media>> get queueStream => _queueSubject.stream;
  Stream<int> get queueIndexStream => _queueIndexSubject.stream;
  Stream<Media?> get currentMediaStream => _currentMediaSubject.stream;
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  
  bool get isPlaying => _player.playing;
  bool get isBuffering => _player.playerState.processingState == ProcessingState.buffering;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  double get volume => _player.volume;
  double get speed => _player.speed;
  int get queueLength => _queue.length;
  bool get hasNext => _queueIndex < _queue.length - 1 && _queueIndex >= 0;
  bool get hasPrevious => _queueIndex > 0;
  bool get isShuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  int get currentIndex => _queueIndex;

  Future<void> playMedia(Media media, {List<Media>? queue}) async {
    _logger.info('========================================');
    _logger.info('🎯 playMedia() CALLED');
    _logger.info('========================================');
    
    try {
      _logger.info('📝 Media Title: ${media.title}');
      _logger.info('📝 File Path: ${media.path}');
      _logger.info('📝 Duration: ${media.formattedDuration}');
      
      if (queue != null && queue.isNotEmpty) {
        _queue = queue;
        _queueIndex = _queue.indexWhere((m) => m.id == media.id);
        if (_queueIndex == -1) {
          _queue.add(media);
          _queueIndex = _queue.length - 1;
        }
        _queueSubject.add(_queue);
        _logger.info('📋 Queue set with ${queue.length} items, index: $_queueIndex');
      } else if (_queue.isEmpty || _queueIndex == -1) {
        _queue = [media];
        _queueIndex = 0;
        _queueSubject.add(_queue);
        _logger.info('📋 Single item queue created');
      } else {
        final existingIndex = _queue.indexWhere((m) => m.id == media.id);
        if (existingIndex == -1) {
          _queue.add(media);
          _queueIndex = _queue.length - 1;
          _logger.info('📋 Added to existing queue at index $_queueIndex');
        } else {
          _queueIndex = existingIndex;
          _logger.info('📋 Using existing queue index $_queueIndex');
        }
        _queueSubject.add(_queue);
      }

      _currentMediaId = media.id;
      _currentMediaSubject.add(media);
      _queueIndexSubject.add(_queueIndex);

      // Build sources
      final sources = <AudioSource>[];
      for (int i = 0; i < _queue.length; i++) {
        final mediaItem = _queue[i];
        final file = File(mediaItem.path);
        if (!await file.exists()) {
          _logger.error('❌ File does NOT exist: ${mediaItem.path}');
          throw Exception('File not found: ${mediaItem.path}');
        }
        sources.add(AudioSource.file(mediaItem.path));
        _logger.info('📝 Added to queue: ${mediaItem.title}');
      }
      
      _audioSource = ConcatenatingAudioSource(
        children: sources,
      );
      
      await _player.setAudioSource(
        _audioSource!,
        initialIndex: _queueIndex,
      );
      _logger.info('✅ AudioSource loaded successfully with ${sources.length} tracks');
      
      await _player.play();
      _logger.info('✅ Playback started successfully!');
      
      _logger.info('========================================');
      _logger.info('🎉 PLAYBACK SUCCESSFUL');
      _logger.info('========================================');
    } catch (e) {
      _logger.error('❌ Error in playMedia(): $e');
      rethrow;
    }
  }

  Future<void> playQueue(List<Media> queue, {int startIndex = 0}) async {
    _logger.info('========================================');
    _logger.info('🎯 playQueue() CALLED');
    _logger.info('========================================');
    
    try {
      if (queue.isEmpty) {
        _logger.warning('⚠️ Queue is empty');
        return;
      }

      _queue = queue;
      _queueIndex = startIndex.clamp(0, queue.length - 1);
      _queueSubject.add(_queue);
      _queueIndexSubject.add(_queueIndex);
      
      final media = queue[_queueIndex];
      _currentMediaId = media.id;
      _currentMediaSubject.add(media);
      _logger.info('📝 Playing: ${media.title}');

      // Build sources
      final sources = <AudioSource>[];
      for (int i = 0; i < _queue.length; i++) {
        final mediaItem = _queue[i];
        final file = File(mediaItem.path);
        if (!await file.exists()) {
          _logger.error('❌ File does NOT exist: ${mediaItem.path}');
          throw Exception('File not found: ${mediaItem.path}');
        }
        sources.add(AudioSource.file(mediaItem.path));
      }
      
      _audioSource = ConcatenatingAudioSource(
        children: sources,
      );
      
      await _player.setAudioSource(
        _audioSource!,
        initialIndex: _queueIndex,
      );
      _logger.info('✅ AudioSource loaded with ${sources.length} tracks');
      
      await _player.play();
      _logger.info('✅ Playback started');
      _logger.info('========================================');
    } catch (e) {
      _logger.error('❌ Error playing queue: $e');
      rethrow;
    }
  }

  Future<void> togglePlayPause() async {
    _logger.info('🔄 togglePlayPause() - Currently playing: ${_player.playing}');
    try {
      if (_player.playing) {
        await _player.pause();
        _logger.info('⏸️ Playback PAUSED');
      } else {
        await _player.play();
        _logger.info('▶️ Playback RESUMED');
      }
    } catch (e) {
      _logger.error('❌ Error toggling play/pause: $e');
    }
  }

  Future<void> play() async {
    _logger.info('▶️ play() called');
    try {
      await _player.play();
      _logger.info('✅ Play started');
    } catch (e) {
      _logger.error('❌ Error playing: $e');
    }
  }

  Future<void> pause() async {
    _logger.info('⏸️ pause() called');
    try {
      await _player.pause();
      _logger.info('✅ Paused');
    } catch (e) {
      _logger.error('❌ Error pausing: $e');
    }
  }

  Future<void> stop() async {
    _logger.info('⏹️ stop() called');
    try {
      await _player.stop();
      _logger.info('✅ Stopped');
    } catch (e) {
      _logger.error('❌ Error stopping: $e');
    }
  }

  Future<void> seek(Duration position) async {
    _logger.info('⏱️ seek() called - Position: ${position.inSeconds}s');
    try {
      await _player.seek(position);
      _logger.info('✅ Seek complete');
    } catch (e) {
      _logger.error('❌ Error seeking: $e');
    }
  }

  Future<void> next() async {
    _logger.info('⏭️ next() called - Current index: $_queueIndex, Queue length: ${_queue.length}');
    try {
      if (hasNext) {
        await _player.seekToNext();
        _logger.info('✅ Next track playing');
      } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
        _logger.info('🔄 Loop all enabled, going to first track');
        _queueIndex = 0;
        await _player.seek(Duration.zero, index: 0);
        _logger.info('✅ Jumped to first track');
      } else {
        _logger.info('⏭️ No next track available - reached end of queue');
      }
    } catch (e) {
      _logger.error('❌ Error playing next: $e');
    }
  }

  Future<void> previous() async {
    _logger.info('⏮️ previous() called - Current index: $_queueIndex, Queue length: ${_queue.length}');
    
    if (_queue.isEmpty) {
      _logger.info('⏮️ Queue is empty');
      return;
    }
    
    try {
      // If current position is more than 3 seconds, seek to beginning of current track
      if (_player.position.inSeconds > 3) {
        await _player.seek(Duration.zero);
        _logger.info('⏮️ Seeked to beginning of current track');
        return;
      }
      
      if (hasPrevious) {
        await _player.seekToPrevious();
        _logger.info('✅ Previous track playing');
      } else if (_player.loopMode == LoopMode.all) {
        _queueIndex = _queue.length - 1;
        await _player.seek(Duration.zero, index: _queue.length - 1);
        _logger.info('🔄 Loop all enabled, jumped to last track');
      } else {
        await _player.seek(Duration.zero);
        _logger.info('⏮️ At beginning of queue, seeked to start');
      }
    } catch (e) {
      _logger.error('❌ Error playing previous: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
      _logger.info('🔊 Volume set to: $volume');
    } catch (e) {
      _logger.error('❌ Error setting volume: $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed.clamp(0.5, 2.0));
      _logger.info('⚡ Speed set to: $speed');
    } catch (e) {
      _logger.error('❌ Error setting speed: $e');
    }
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    _logger.info('🔁 setRepeatMode() called - Mode: $mode');
    try {
      final loopMode = _convertToLoopMode(mode);
      await _player.setLoopMode(loopMode);
      _logger.info('✅ Repeat mode set to: $loopMode');
    } catch (e) {
      _logger.error('❌ Error setting repeat mode: $e');
    }
  }

  LoopMode _convertToLoopMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return LoopMode.off;
      case RepeatMode.one:
        return LoopMode.one;
      case RepeatMode.all:
        return LoopMode.all;
    }
  }

  Future<void> setShuffle(bool enabled) async {
    _logger.info('🔀 setShuffle() called - Enabled: $enabled');
    try {
      await _player.setShuffleModeEnabled(enabled);
      _logger.info('✅ Shuffle set to: $enabled');
    } catch (e) {
      _logger.error('❌ Error setting shuffle: $e');
    }
  }

  Future<void> removeFromQueue(int index) async {
    _logger.info('🗑️ removeFromQueue() called - Index: $index');
    try {
      if (index >= 0 && index < _queue.length) {
        _queue.removeAt(index);
        _queueSubject.add(_queue);
        _logger.info('✅ Removed item at index $index');
        
        if (_queue.isNotEmpty) {
          await _rebuildAudioSource();
        }
        
        if (_queueIndex >= index && _queueIndex > 0) {
          _queueIndex--;
          _queueIndexSubject.add(_queueIndex);
          _logger.info('📌 Updated queue index to $_queueIndex');
        }
        
        if (_queue.isEmpty) {
          _logger.info('📋 Queue is now empty, stopping playback');
          await stop();
        }
      }
    } catch (e) {
      _logger.error('❌ Error removing from queue: $e');
    }
  }

  Future<void> clearQueue() async {
    _logger.info('🧹 clearQueue() called');
    try {
      _queue.clear();
      _queueIndex = -1;
      _currentMediaId = null;
      _queueSubject.add([]);
      _queueIndexSubject.add(-1);
      _currentMediaSubject.add(null);
      await stop();
      _logger.info('✅ Queue cleared');
    } catch (e) {
      _logger.error('❌ Error clearing queue: $e');
    }
  }

  Future<void> _rebuildAudioSource() async {
    if (_queue.isEmpty) return;
    
    _logger.info('🔄 Rebuilding audio source...');
    final sources = <AudioSource>[];
    for (int i = 0; i < _queue.length; i++) {
      final mediaItem = _queue[i];
      final file = File(mediaItem.path);
      if (!await file.exists()) {
        _logger.warning('⚠️ File does NOT exist: ${mediaItem.path}');
        continue;
      }
      sources.add(AudioSource.file(mediaItem.path));
    }
    
    if (sources.isEmpty) {
      _logger.warning('⚠️ No valid sources to rebuild');
      return;
    }
    
    _audioSource = ConcatenatingAudioSource(
      children: sources,
    );
    
    final newIndex = _queueIndex.clamp(0, sources.length - 1);
    await _player.setAudioSource(
      _audioSource!,
      initialIndex: newIndex,
    );
    _logger.info('✅ Audio source rebuilt with ${sources.length} tracks');
  }

  void dispose() {
    _logger.info('🗑️ dispose() called');
    try {
      _player.dispose();
      _queueSubject.close();
      _queueIndexSubject.close();
      _currentMediaSubject.close();
      _positionSubject.close();
      _durationSubject.close();
      _isDisposed = true;
      _instance = null;
      _logger.info('✅ AudioPlayerService disposed');
    } catch (e) {
      _logger.error('❌ Error disposing: $e');
    }
  }

  static void reset() {
    if (_instance != null) {
      _instance!.dispose();
    }
    _instance = null;
    _isDisposed = false;
  }

  // Added this method to get duration from media without playing
  static Future<Duration> getMediaDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(filePath);
      final duration = player.duration ?? Duration.zero;
      await player.dispose();
      return duration;
    } catch (e) {
      return Duration.zero;
    }
  }
}

// // lib/features/audio_player/data/services/audio_player_service.dart
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart' hide RepeatMode;
// import 'package:just_audio/just_audio.dart';
// import 'package:media/features/mediadetection/domain/entities/media.dart';
// import 'package:rxdart/rxdart.dart';
// import '../../domain/entities/repeat_mode.dart';
// import '../../../../core/utils/helpers/logger_helper.dart';

// class AudioPlayerService {
//   static AudioPlayerService? _instance;
//   static bool _isDisposed = false;
  
//   final AudioPlayer _player = AudioPlayer();
//   final LoggerHelper _logger = LoggerHelper();
  
//   List<Media> _queue = [];
//   int _queueIndex = -1;
//   String? _currentMediaId;
  
//   // Use ConcatenatingAudioSource for proper queue management
//   ConcatenatingAudioSource? _audioSource;
  
//   final BehaviorSubject<List<Media>> _queueSubject = BehaviorSubject.seeded([]);
//   final BehaviorSubject<int> _queueIndexSubject = BehaviorSubject.seeded(-1);
//   final BehaviorSubject<Media?> _currentMediaSubject = BehaviorSubject.seeded(null);
  
//   AudioPlayerService._internal() {
//     _logger.info('🔄 AudioPlayerService._internal() - Creating new instance');
//     _initializePlayer();
//   }

//   factory AudioPlayerService() {
//     if (_instance == null || _isDisposed) {
//       _instance = AudioPlayerService._internal();
//       _isDisposed = false;
//     }
//     return _instance!;
//   }

//   void _initializePlayer() {
//     _logger.info('🔧 _initializePlayer() - Setting up player listeners');
//     try {
//       // Listen to player state changes
//       _player.playerStateStream.listen((state) {
//         _logger.debug('📊 Player state: ${state.processingState}, Playing: ${state.playing}');
        
//         // When playback completes, auto-play next
//         if (state.processingState == ProcessingState.completed) {
//           _logger.info('⏹️ Playback COMPLETED - Auto-playing next');
//           _onPlaybackComplete();
//         }
//       });

//       // Listen to position changes
//       _player.positionStream.listen((position) {
//         // Update position if needed
//       });

//       // Listen to duration changes
//       _player.durationStream.listen((duration) {
//         if (duration != null) {
//           _logger.debug('⏱️ Duration: ${duration.inSeconds}s');
//         }
//       });

//       // Listen to current index changes
//       _player.currentIndexStream.listen((index) {
//         if (index != null) {
//           _logger.debug('📌 Current index: $index');
//           _queueIndex = index;
//           _queueIndexSubject.add(index);
//           if (index < _queue.length) {
//             _currentMediaId = _queue[index].id;
//             _currentMediaSubject.add(_queue[index]);
//             _logger.debug('📌 Current media: ${_queue[index].title}');
//           }
//         }
//       });

//       _logger.info('✅ _initializePlayer() - All listeners set up successfully');
//     } catch (e) {
//       _logger.error('❌ Error initializing player: $e');
//     }
//   }

//   // Called when playback completes
//   void _onPlaybackComplete() {
//     _logger.info('🎵 Playback completed, checking for next track...');
//     if (hasNext) {
//       _logger.info('⏭️ Moving to next track automatically');
//       _player.seekToNext();
//     } else {
//       _logger.info('📋 End of queue reached');
//     }
//   }

//   // Getters
//   Stream<PlayerState> get playerStateStream => _player.playerStateStream;
//   Stream<Duration> get positionStream => _player.positionStream;
//   Stream<Duration?> get durationStream => _player.durationStream;
//   Stream<List<Media>> get queueStream => _queueSubject.stream;
//   Stream<int> get queueIndexStream => _queueIndexSubject.stream;
//   Stream<Media?> get currentMediaStream => _currentMediaSubject.stream;
  
//   bool get isPlaying => _player.playing;
//   bool get isBuffering => _player.playerState.processingState == ProcessingState.buffering;
//   Duration get position => _player.position;
//   Duration? get duration => _player.duration;
//   double get volume => _player.volume;
//   double get speed => _player.speed;
//   int get queueLength => _queue.length;
//   bool get hasNext => _queueIndex < _queue.length - 1;
//   bool get hasPrevious => _queueIndex > 0;

//   Future<void> playMedia(Media media, {List<Media>? queue}) async {
//     _logger.info('========================================');
//     _logger.info('🎯 playMedia() CALLED');
//     _logger.info('========================================');
    
//     try {
//       _logger.info('📝 Media Title: ${media.title}');
//       _logger.info('📝 File Path: ${media.filePath}');
      
//       // Step 1: Set up the queue
//       _logger.info('📋 Step 1: Setting up queue...');
//       if (queue != null) {
//         _queue = queue;
//         _queueIndex = _queue.indexWhere((m) => m.id == media.id);
//         if (_queueIndex == -1) {
//           _queue.add(media);
//           _queueIndex = _queue.length - 1;
//         }
//         _queueSubject.add(_queue);
//         _logger.info('📋 Queue set with ${queue.length} items, index: $_queueIndex');
//       } else if (_queue.isEmpty || _queueIndex == -1) {
//         _queue = [media];
//         _queueIndex = 0;
//         _queueSubject.add(_queue);
//         _logger.info('📋 Single item queue created');
//       } else {
//         final existingIndex = _queue.indexWhere((m) => m.id == media.id);
//         if (existingIndex == -1) {
//           _queue.add(media);
//           _queueIndex = _queue.length - 1;
//           _logger.info('📋 Added to existing queue at index $_queueIndex');
//         } else {
//           _queueIndex = existingIndex;
//           _logger.info('📋 Using existing queue index $_queueIndex');
//         }
//         _queueSubject.add(_queue);
//       }

//       _currentMediaId = media.id;
//       _currentMediaSubject.add(media);
//       _queueIndexSubject.add(_queueIndex);
//       _logger.info('✅ Queue setup complete');

//       // Step 2: Check if file exists
//       _logger.info('📂 Step 2: Checking if file exists...');
//       for (int i = 0; i < _queue.length; i++) {
//         final file = File(_queue[i].filePath);
//         if (!await file.exists()) {
//           _logger.error('❌ File does NOT exist: ${_queue[i].filePath}');
//           throw Exception('File not found: ${_queue[i].filePath}');
//         }
//       }
//       _logger.info('✅ All files exist');

//       // Step 3: Build the audio source list
//       _logger.info('🎵 Step 3: Building audio source list...');
//       final sources = <AudioSource>[];
//       for (int i = 0; i < _queue.length; i++) {
//         final mediaItem = _queue[i];
//         sources.add(
//           AudioSource.file(mediaItem.filePath),
//         );
//         _logger.info('📝 Added to queue: ${mediaItem.title}');
//       }
      
//       // Step 4: Create concatenating audio source
//       _logger.info('🎵 Step 4: Creating concatenating audio source...');
//       _audioSource = ConcatenatingAudioSource(
//         children: sources,
//       );
      
//       // Step 5: Load the audio source
//       _logger.info('🎵 Step 5: Loading audio source...');
//       await _player.setAudioSource(
//         _audioSource!,
//         initialIndex: _queueIndex,
//       );
//       _logger.info('✅ AudioSource loaded successfully with ${sources.length} tracks');
      
//       // Step 6: Play
//       _logger.info('▶️ Step 6: Starting playback...');
//       await _player.play();
//       _logger.info('✅ Playback started successfully!');
      
//       _logger.info('========================================');
//       _logger.info('🎉 PLAYBACK SUCCESSFUL');
//       _logger.info('========================================');
//     } catch (e) {
//       _logger.error('❌ Error in playMedia(): $e');
//       rethrow;
//     }
//   }

//   Future<void> playQueue(List<Media> queue, {int startIndex = 0}) async {
//     _logger.info('========================================');
//     _logger.info('🎯 playQueue() CALLED');
//     _logger.info('========================================');
    
//     try {
//       if (queue.isEmpty) {
//         _logger.warning('⚠️ Queue is empty');
//         return;
//       }

//       _queue = queue;
//       _queueIndex = startIndex.clamp(0, queue.length - 1);
//       _queueSubject.add(_queue);
//       _queueIndexSubject.add(_queueIndex);
      
//       final media = queue[_queueIndex];
//       _currentMediaId = media.id;
//       _currentMediaSubject.add(media);
//       _logger.info('📝 Playing: ${media.title}');

//       // Build sources
//       final sources = <AudioSource>[];
//       for (int i = 0; i < _queue.length; i++) {
//         final mediaItem = _queue[i];
//         sources.add(
//           AudioSource.file(mediaItem.filePath),
//         );
//       }
      
//       _audioSource = ConcatenatingAudioSource(
//         children: sources,
//       );
      
//       await _player.setAudioSource(
//         _audioSource!,
//         initialIndex: _queueIndex,
//       );
//       _logger.info('✅ AudioSource loaded');
      
//       await _player.play();
//       _logger.info('✅ Playback started');
//       _logger.info('========================================');
//     } catch (e) {
//       _logger.error('❌ Error playing queue: $e');
//       rethrow;
//     }
//   }

//   Future<void> togglePlayPause() async {
//     _logger.info('🔄 togglePlayPause() - Currently playing: ${_player.playing}');
//     try {
//       if (_player.playing) {
//         await _player.pause();
//         _logger.info('⏸️ Playback PAUSED');
//       } else {
//         await _player.play();
//         _logger.info('▶️ Playback RESUMED');
//       }
//     } catch (e) {
//       _logger.error('❌ Error toggling play/pause: $e');
//     }
//   }

//   Future<void> play() async {
//     _logger.info('▶️ play() called');
//     try {
//       await _player.play();
//       _logger.info('✅ Play started');
//     } catch (e) {
//       _logger.error('❌ Error playing: $e');
//     }
//   }

//   Future<void> pause() async {
//     _logger.info('⏸️ pause() called');
//     try {
//       await _player.pause();
//       _logger.info('✅ Paused');
//     } catch (e) {
//       _logger.error('❌ Error pausing: $e');
//     }
//   }

//   Future<void> stop() async {
//     _logger.info('⏹️ stop() called');
//     try {
//       await _player.stop();
//       _logger.info('✅ Stopped');
//     } catch (e) {
//       _logger.error('❌ Error stopping: $e');
//     }
//   }

//   Future<void> seek(Duration position) async {
//     _logger.info('⏱️ seek() called - Position: ${position.inSeconds}s');
//     try {
//       await _player.seek(position);
//       _logger.info('✅ Seek complete');
//     } catch (e) {
//       _logger.error('❌ Error seeking: $e');
//     }
//   }

//   Future<void> next() async {
//     _logger.info('⏭️ next() called - Current index: $_queueIndex, Queue length: ${_queue.length}');
//     try {
//       if (hasNext) {
//         await _player.seekToNext();
//         _logger.info('✅ Next track playing');
//       } else {
//         _logger.info('⏭️ No next track available - reached end of queue');
//         if (_player.loopMode == LoopMode.all) {
//           _logger.info('🔄 Loop all enabled, going to first track');
//           await _player.seekToPrevious();
//         }
//       }
//     } catch (e) {
//       _logger.error('❌ Error playing next: $e');
//     }
//   }

//   Future<void> previous() async {
//     _logger.info('⏮️ previous() called - Current index: $_queueIndex, Queue length: ${_queue.length}');
    
//     // If queue is empty or only has one item, just seek to beginning
//     if (_queue.isEmpty || _queue.length <= 1) {
//       _logger.info('⏮️ Queue has less than 2 items, seeking to beginning');
//       await _player.seek(Duration.zero);
//       return;
//     }
    
//     try {
//       // Use the player's built-in seekToPrevious which works with ConcatenatingAudioSource
//       await _player.seekToPrevious();
//       _logger.info('✅ Previous track playing');
//     } catch (e) {
//       _logger.error('❌ Error playing previous: $e');
//       // Fallback: manual navigation
//       try {
//         int previousIndex = _queueIndex - 1;
//         if (previousIndex < 0) {
//           previousIndex = _queue.length - 1;
//         }
//         _queueIndex = previousIndex;
//         _queueIndexSubject.add(_queueIndex);
        
//         final media = _queue[_queueIndex];
//         _currentMediaId = media.id;
//         _currentMediaSubject.add(media);
        
//         await _player.setAudioSource(
//           AudioSource.file(media.filePath),
//         );
//         await _player.play();
//         _logger.info('✅ Previous track playing (fallback): ${media.title}');
//       } catch (e2) {
//         _logger.error('❌ Fallback also failed: $e2');
//       }
//     }
//   }

//   Future<void> setVolume(double volume) async {
//     try {
//       await _player.setVolume(volume);
//       _logger.info('🔊 Volume set to: $volume');
//     } catch (e) {
//       _logger.error('❌ Error setting volume: $e');
//     }
//   }

//   Future<void> setSpeed(double speed) async {
//     try {
//       await _player.setSpeed(speed);
//       _logger.info('⚡ Speed set to: $speed');
//     } catch (e) {
//       _logger.error('❌ Error setting speed: $e');
//     }
//   }

//   Future<void> setRepeatMode(RepeatMode mode) async {
//     _logger.info('🔁 setRepeatMode() called - Mode: $mode');
//     try {
//       final loopMode = _convertToLoopMode(mode);
//       await _player.setLoopMode(loopMode);
//       _logger.info('✅ Repeat mode set to: $loopMode');
//     } catch (e) {
//       _logger.error('❌ Error setting repeat mode: $e');
//     }
//   }

//   LoopMode _convertToLoopMode(RepeatMode mode) {
//     switch (mode) {
//       case RepeatMode.off:
//         return LoopMode.off;
//       case RepeatMode.one:
//         return LoopMode.one;
//       case RepeatMode.all:
//         return LoopMode.all;
//     }
//   }

//   Future<void> setShuffle(bool enabled) async {
//     _logger.info('🔀 setShuffle() called - Enabled: $enabled');
//     try {
//       await _player.setShuffleModeEnabled(enabled);
//       _logger.info('✅ Shuffle set to: $enabled');
//     } catch (e) {
//       _logger.error('❌ Error setting shuffle: $e');
//     }
//   }

//   Future<void> removeFromQueue(int index) async {
//     _logger.info('🗑️ removeFromQueue() called - Index: $index');
//     try {
//       if (index >= 0 && index < _queue.length) {
//         _queue.removeAt(index);
//         _queueSubject.add(_queue);
//         _logger.info('✅ Removed item at index $index');
        
//         if (_queue.isNotEmpty) {
//           await _rebuildAudioSource();
//         }
        
//         if (_queueIndex >= index && _queueIndex > 0) {
//           _queueIndex--;
//           _queueIndexSubject.add(_queueIndex);
//           _logger.info('📌 Updated queue index to $_queueIndex');
//         }
        
//         if (_queue.isEmpty) {
//           _logger.info('📋 Queue is now empty, stopping playback');
//           await stop();
//         }
//       }
//     } catch (e) {
//       _logger.error('❌ Error removing from queue: $e');
//     }
//   }

//   Future<void> clearQueue() async {
//     _logger.info('🧹 clearQueue() called');
//     try {
//       _queue.clear();
//       _queueIndex = -1;
//       _currentMediaId = null;
//       _queueSubject.add([]);
//       _queueIndexSubject.add(-1);
//       _currentMediaSubject.add(null);
//       await stop();
//       _logger.info('✅ Queue cleared');
//     } catch (e) {
//       _logger.error('❌ Error clearing queue: $e');
//     }
//   }

//   Future<void> _rebuildAudioSource() async {
//     if (_queue.isEmpty) return;
    
//     _logger.info('🔄 Rebuilding audio source...');
//     final sources = <AudioSource>[];
//     for (int i = 0; i < _queue.length; i++) {
//       final mediaItem = _queue[i];
//       sources.add(
//         AudioSource.file(mediaItem.filePath),
//       );
//     }
    
//     _audioSource = ConcatenatingAudioSource(
//       children: sources,
//     );
    
//     await _player.setAudioSource(
//       _audioSource!,
//       initialIndex: _queueIndex.clamp(0, _queue.length - 1),
//     );
//     _logger.info('✅ Audio source rebuilt with ${sources.length} tracks');
//   }

//   void dispose() {
//     _logger.info('🗑️ dispose() called');
//     try {
//       _player.dispose();
//       _queueSubject.close();
//       _queueIndexSubject.close();
//       _currentMediaSubject.close(); 
//       _isDisposed = true;
//       _instance = null;
//       _logger.info('✅ AudioPlayerService disposed');
//     } catch (e) {
//       _logger.error('❌ Error disposing: $e');
//     }
//   }

//   static void reset() {
//     if (_instance != null) {
//       _instance!.dispose();
//     }
//     _instance = null;
//     _isDisposed = false;
//   }
// }
// // // lib/features/audio_player/data/services/audio_player_service.dart
// // import 'dart:async';
// // import 'dart:io';
// // import 'package:flutter/material.dart' hide RepeatMode;
// // import 'package:just_audio/just_audio.dart';
// // import 'package:media/features/mediadetection/domain/entities/media.dart';
// // import 'package:rxdart/rxdart.dart';
// // import '../../domain/entities/repeat_mode.dart';
// // import '../../../../core/utils/helpers/logger_helper.dart';

// // class AudioPlayerService {
// //   // Remove the _instance pattern and use a simpler approach
// //   static AudioPlayerService? _instance;
// //   static bool _isDisposed = false;
  
// //   final AudioPlayer _player = AudioPlayer();
// //   final LoggerHelper _logger = LoggerHelper();
  
// //   List<Media> _queue = [];
// //   int _queueIndex = -1;
// //   String? _currentMediaId;
  
// //   // Stream controllers
// //   final BehaviorSubject<List<Media>> _queueSubject = BehaviorSubject.seeded([]);
// //   final BehaviorSubject<int> _queueIndexSubject = BehaviorSubject.seeded(-1);
// //   final BehaviorSubject<Media?> _currentMediaSubject = BehaviorSubject.seeded(null);
  
// //   // Private constructor
// //   AudioPlayerService._internal() {
// //     _logger.info('🔄 AudioPlayerService._internal() - Creating new instance');
// //     _initializePlayer();
// //   }

// //   // Factory to get the single instance
// //   factory AudioPlayerService() {
// //     //_logger.info('🏭 AudioPlayerService() factory called');
// //     if (_instance == null || _isDisposed) {
// //       //_logger.info('📦 Creating new AudioPlayerService instance (instance: $_instance, disposed: $_isDisposed)');
// //       _instance = AudioPlayerService._internal();
// //       _isDisposed = false;
// //     } else {
// //       //_logger.info('♻️ Reusing existing AudioPlayerService instance');
// //     }
// //     return _instance!;
// //   }

// //   void _initializePlayer() {
// //     _logger.info('🔧 _initializePlayer() - Setting up player listeners');
// //     try {
// //       // Listen to player state changes
// //       _player.playerStateStream.listen((state) {
// //         _logger.debug('📊 Player state: ${state.processingState}, Playing: ${state.playing}');
// //         if (state.processingState == ProcessingState.ready) {
// //           _logger.info('✅ Player is READY to play');
// //         }
// //         if (state.processingState == ProcessingState.completed) {
// //           _logger.info('⏹️ Playback COMPLETED');
// //         }
// //         // if (state.processingState == ProcessingState.error) {
// //         //   _logger.error('❌ Player ERROR state');
// //         // }
// //       });

// //       // Listen to position changes
// //       _player.positionStream.listen((position) {
// //         // Only log occasionally to avoid spam - uncomment if needed
// //         // _logger.debug('⏱️ Position: ${position.inSeconds}s');
// //       });

// //       // Listen to duration changes
// //       _player.durationStream.listen((duration) {
// //         if (duration != null) {
// //           _logger.debug('⏱️ Duration: ${duration.inSeconds}s');
// //         } else {
// //           _logger.debug('⏱️ Duration: null (not loaded yet)');
// //         }
// //       });

// //       // Listen to current index changes
// //       _player.currentIndexStream.listen((index) {
// //         if (index != null) {
// //           _logger.debug('📌 Current index: $index');
// //           _queueIndex = index;
// //           _queueIndexSubject.add(index);
// //           if (index < _queue.length) {
// //             _currentMediaId = _queue[index].id;
// //             _currentMediaSubject.add(_queue[index]);
// //             _logger.debug('📌 Current media: ${_queue[index].title}');
// //           }
// //         }
// //       });

// //       // Listen to sequence state changes
// //       _player.sequenceStateStream.listen((sequenceState) {
// //         if (sequenceState != null) {
// //           _logger.debug('📋 Sequence state updated');
// //           if (sequenceState.currentSource != null) {
// //             _logger.debug('📋 Current source: ${sequenceState.currentSource}');
// //           }
// //         }
// //       });

// //       // Listen to player errors
// //       _player.playbackEventStream.listen((event) {
// //         //_logger.debug('🎵 Playback event: ${event.eventType}');
// //       });

// //       _logger.info('✅ _initializePlayer() - All listeners set up successfully');
// //     } catch (e) {
// //       _logger.error('❌ Error initializing player: $e');
// //     }
// //   }
  

// //   // Getters
// //   Stream<PlayerState> get playerStateStream {
// //     _logger.debug('📤 Getting playerStateStream');
// //     return _player.playerStateStream;
// //   }
  
// //   Stream<Duration> get positionStream {
// //     _logger.debug('📤 Getting positionStream');
// //     return _player.positionStream;
// //   }
  
// //   Stream<Duration?> get durationStream {
// //     _logger.debug('📤 Getting durationStream');
// //     return _player.durationStream;
// //   }
  
// //   Stream<List<Media>> get queueStream {
// //     _logger.debug('📤 Getting queueStream');
// //     return _queueSubject.stream;
// //   }
  
// //   Stream<int> get queueIndexStream {
// //     _logger.debug('📤 Getting queueIndexStream');
// //     return _queueIndexSubject.stream;
// //   }
  
// //   Stream<Media?> get currentMediaStream {
// //     _logger.debug('📤 Getting currentMediaStream');
// //     return _currentMediaSubject.stream;
// //   }
  
// //   bool get isPlaying {
// //     final playing = _player.playing;
// //     _logger.debug('🎵 isPlaying: $playing');
// //     return playing;
// //   }
  
// //   bool get isBuffering {
// //     final buffering = _player.playerState.processingState == ProcessingState.buffering;
// //     _logger.debug('⏳ isBuffering: $buffering');
// //     return buffering;
// //   }
  
// //   Duration get position {
// //     final pos = _player.position;
// //     _logger.debug('⏱️ position: ${pos.inSeconds}s');
// //     return pos;
// //   }
  
// //   Duration? get duration {
// //     final dur = _player.duration;
// //     _logger.debug('⏱️ duration: ${dur?.inSeconds ?? 'null'}s');
// //     return dur;
// //   }
  
// //   double get volume {
// //     final vol = _player.volume;
// //     _logger.debug('🔊 volume: $vol');
// //     return vol;
// //   }
  
// //   double get speed {
// //     final spd = _player.speed;
// //     _logger.debug('⚡ speed: $spd');
// //     return spd;
// //   }
  
// //   int get queueLength {
// //     final len = _queue.length;
// //     _logger.debug('📋 queueLength: $len');
// //     return len;
// //   }
  
// //   bool get hasNext {
// //     final has = _queueIndex < _queue.length - 1;
// //     _logger.debug('⏭️ hasNext: $has (index: $_queueIndex, length: ${_queue.length})');
// //     return has;
// //   }
  
// //   bool get hasPrevious {
// //     final has = _queueIndex > 0;
// //     _logger.debug('⏮️ hasPrevious: $has (index: $_queueIndex)');
// //     return has;
// //   }

// //   Future<void> playMedia(Media media, {List<Media>? queue}) async {
// //     _logger.info('========================================');
// //     _logger.info('🎯 playMedia() CALLED');
// //     _logger.info('========================================');
    
// //     try {
// //       _logger.info('📝 Media Title: ${media.title}');
// //       _logger.info('📝 File Path: ${media.filePath}');
// //       _logger.info('📝 Media ID: ${media.id}');
// //       _logger.info('📝 Queue provided: ${queue != null}');
      
// //       // Step 1: Set up the queue
// //       _logger.info('📋 Step 1: Setting up queue...');
// //       if (queue != null) {
// //         _queue = queue;
// //         _queueIndex = _queue.indexWhere((m) => m.id == media.id);
// //         _queueSubject.add(_queue);
// //         _logger.info('📋 Queue set with ${queue.length} items');
// //         _logger.info('📋 Queue index for media: $_queueIndex');
// //       } else if (_queue.isEmpty || _queueIndex == -1) {
// //         _queue = [media];
// //         _queueIndex = 0;
// //         _queueSubject.add(_queue);
// //         _logger.info('📋 Single item queue created');
// //       } else {
// //         final existingIndex = _queue.indexWhere((m) => m.id == media.id);
// //         if (existingIndex == -1) {
// //           _queue.add(media);
// //           _queueIndex = _queue.length - 1;
// //           _logger.info('📋 Added to existing queue at index $_queueIndex');
// //         } else {
// //           _queueIndex = existingIndex;
// //           _logger.info('📋 Using existing queue index $_queueIndex');
// //         }
// //         _queueSubject.add(_queue);
// //       }

// //       _currentMediaId = media.id;
// //       _currentMediaSubject.add(media);
// //       _queueIndexSubject.add(_queueIndex);
// //       _logger.info('✅ Queue setup complete');

// //       // Step 2: Check if file exists
// //       _logger.info('📂 Step 2: Checking if file exists...');
// //       final file = File(media.filePath);
// //       if (!await file.exists()) {
// //         _logger.error('❌ File does NOT exist: ${media.filePath}');
// //         throw Exception('File not found: ${media.filePath}');
// //       }
// //       _logger.info('✅ File exists');

// //       // Step 3: Check file size
// //       _logger.info('📏 Step 3: Checking file size...');
// //       final fileSize = await file.length();
// //       _logger.info('📏 File size: $fileSize bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
// //       if (fileSize == 0) {
// //         _logger.error('❌ File is empty (0 bytes)');
// //         throw Exception('File is empty');
// //       }
// //       _logger.info('✅ File has content');

// //       // Step 4: Load audio source
// //       _logger.info('🎵 Step 4: Loading audio source...');
// //       _logger.info('🎵 Creating AudioSource from: ${media.filePath}');
      
// //       try {
// //         await _player.setAudioSource(
// //           AudioSource.file(media.filePath),
// //         );
// //         _logger.info('✅ AudioSource loaded successfully');
        
// //         // Log the current player state after loading
// //         _logger.info('📊 Player state after load - Processing: ${_player.playerState.processingState}');
// //       } catch (e) {
// //         _logger.error('❌ Failed to load AudioSource: $e');
// //         _logger.error('❌ Error details: ${e.toString()}');
// //         rethrow;
// //       }
      
// //       // Step 5: Play
// //       _logger.info('▶️ Step 5: Starting playback...');
// //       try {
// //         await _player.play();
// //         _logger.info('✅ Playback started successfully!');
// //         _logger.info('📊 Current state - Playing: ${_player.playing}');
// //         _logger.info('📊 Position: ${_player.position.inSeconds}s');
// //         _logger.info('📊 Duration: ${_player.duration?.inSeconds ?? 'null'}s');
// //         _logger.info('📊 Processing: ${_player.playerState.processingState}');
// //       } catch (e) {
// //         _logger.error('❌ Failed to start playback: $e');
// //         _logger.error('❌ Error details: ${e.toString()}');
// //         rethrow;
// //       }
      
// //       _logger.info('========================================');
// //       _logger.info('🎉 PLAYBACK SUCCESSFUL');
// //       _logger.info('========================================');
// //     } catch (e) {
// //       _logger.error('========================================');
// //       _logger.error('❌ ERROR IN playMedia()');
// //       _logger.error('❌ Error: $e');
// //       _logger.error('❌ Stack trace: ${StackTrace.current}');
// //       _logger.error('========================================');
// //       rethrow;
// //     }
// //   }

// //   Future<void> playQueue(List<Media> queue, {int startIndex = 0}) async {
// //     _logger.info('========================================');
// //     _logger.info('🎯 playQueue() CALLED');
// //     _logger.info('========================================');
    
// //     try {
// //       _logger.info('📝 Queue length: ${queue.length}');
// //       _logger.info('📝 Start index: $startIndex');
      
// //       if (queue.isEmpty) {
// //         _logger.warning('⚠️ Queue is empty');
// //         return;
// //       }

// //       _queue = queue;
// //       _queueIndex = startIndex.clamp(0, queue.length - 1);
// //       _queueSubject.add(_queue);
// //       _queueIndexSubject.add(_queueIndex);
      
// //       final media = queue[_queueIndex];
// //       _currentMediaId = media.id;
// //       _currentMediaSubject.add(media);
// //       _logger.info('📝 Playing: ${media.title}');

// //       _logger.info('🎵 Loading audio source...');
// //       await _player.setAudioSource(
// //         AudioSource.file(media.filePath),
// //       );
// //       _logger.info('✅ AudioSource loaded');
      
// //       _logger.info('▶️ Starting playback...');
// //       await _player.play();
// //       _logger.info('✅ Playback started');
// //       _logger.info('========================================');
// //     } catch (e) {
// //       _logger.error('❌ Error playing queue: $e');
// //       rethrow;
// //     }
// //   }

// //   Future<void> togglePlayPause() async {
// //     _logger.info('🔄 togglePlayPause() called - Currently playing: ${_player.playing}');
// //     try {
// //       if (_player.playing) {
// //         await _player.pause();
// //         _logger.info('⏸️ Playback PAUSED');
// //       } else {
// //         await _player.play();
// //         _logger.info('▶️ Playback RESUMED');
// //       }
// //     } catch (e) {
// //       _logger.error('❌ Error toggling play/pause: $e');
// //     }
// //   }

// //   Future<void> play() async {
// //     _logger.info('▶️ play() called');
// //     try {
// //       await _player.play();
// //       _logger.info('✅ Play started');
// //     } catch (e) {
// //       _logger.error('❌ Error playing: $e');
// //     }
// //   }

// //   Future<void> pause() async {
// //     _logger.info('⏸️ pause() called');
// //     try {
// //       await _player.pause();
// //       _logger.info('✅ Paused');
// //     } catch (e) {
// //       _logger.error('❌ Error pausing: $e');
// //     }
// //   }

// //   Future<void> stop() async {
// //     _logger.info('⏹️ stop() called');
// //     try {
// //       await _player.stop();
// //       _logger.info('✅ Stopped');
// //     } catch (e) {
// //       _logger.error('❌ Error stopping: $e');
// //     }
// //   }

// //   Future<void> seek(Duration position) async {
// //     _logger.info('⏱️ seek() called - Position: ${position.inSeconds}s');
// //     try {
// //       await _player.seek(position);
// //       _logger.info('✅ Seek complete');
// //     } catch (e) {
// //       _logger.error('❌ Error seeking: $e');
// //     }
// //   }

// //   Future<void> next() async {
// //     _logger.info('⏭️ next() called');
// //     try {
// //       if (hasNext) {
// //         _logger.info('⏭️ Moving to next track');
// //         _queueIndex++;
// //         _queueIndexSubject.add(_queueIndex);
// //         final media = _queue[_queueIndex];
// //         _currentMediaId = media.id;
// //         _currentMediaSubject.add(media);
        
// //         _logger.info('🎵 Loading next track: ${media.title}');
// //         await _player.setAudioSource(
// //           AudioSource.file(media.filePath),
// //         );
// //         await _player.play();
// //         _logger.info('✅ Next track playing');
// //       } else {
// //         _logger.info('⏭️ No next track available');
// //       }
// //     } catch (e) {
// //       _logger.error('❌ Error playing next: $e');
// //     }
// //   }

// //   Future<void> previous() async {
// //     _logger.info('⏮️ previous() called');
// //     try {
// //       if (hasPrevious) {
// //         _logger.info('⏮️ Moving to previous track');
// //         _queueIndex--;
// //         _queueIndexSubject.add(_queueIndex);
// //         final media = _queue[_queueIndex];
// //         _currentMediaId = media.id;
// //         _currentMediaSubject.add(media);
        
// //         _logger.info('🎵 Loading previous track: ${media.title}');
// //         await _player.setAudioSource(
// //           AudioSource.file(media.filePath),
// //         );
// //         await _player.play();
// //         _logger.info('✅ Previous track playing');
// //       } else {
// //         _logger.info('⏮️ No previous track available');
// //       }
// //     } catch (e) {
// //       _logger.error('❌ Error playing previous: $e');
// //     }
// //   }

// //   Future<void> setVolume(double volume) async {
// //     _logger.info('🔊 setVolume() called - Volume: $volume');
// //     try {
// //       await _player.setVolume(volume);
// //       _logger.info('✅ Volume set');
// //     } catch (e) {
// //       _logger.error('❌ Error setting volume: $e');
// //     }
// //   }

// //   Future<void> setSpeed(double speed) async {
// //     _logger.info('⚡ setSpeed() called - Speed: $speed');
// //     try {
// //       await _player.setSpeed(speed);
// //       _logger.info('✅ Speed set');
// //     } catch (e) {
// //       _logger.error('❌ Error setting speed: $e');
// //     }
// //   }

// //   Future<void> setRepeatMode(RepeatMode mode) async {
// //     _logger.info('🔁 setRepeatMode() called - Mode: $mode');
// //     try {
// //       final loopMode = _convertToLoopMode(mode);
// //       await _player.setLoopMode(loopMode);
// //       _logger.info('✅ Repeat mode set to: $loopMode');
// //     } catch (e) {
// //       _logger.error('❌ Error setting repeat mode: $e');
// //     }
// //   }

// //   LoopMode _convertToLoopMode(RepeatMode mode) {
// //     _logger.debug('🔄 Converting RepeatMode: $mode');
// //     switch (mode) {
// //       case RepeatMode.off:
// //         return LoopMode.off;
// //       case RepeatMode.one:
// //         return LoopMode.one;
// //       case RepeatMode.all:
// //         return LoopMode.all;
// //     }
// //   }

// //   Future<void> setShuffle(bool enabled) async {
// //     _logger.info('🔀 setShuffle() called - Enabled: $enabled');
// //     try {
// //       await _player.setShuffleModeEnabled(enabled);
// //       _logger.info('✅ Shuffle set');
// //     } catch (e) {
// //       _logger.error('❌ Error setting shuffle: $e');
// //     }
// //   }

// //   Future<void> removeFromQueue(int index) async {
// //     _logger.info('🗑️ removeFromQueue() called - Index: $index');
// //     try {
// //       if (index >= 0 && index < _queue.length) {
// //         _queue.removeAt(index);
// //         _queueSubject.add(_queue);
// //         _logger.info('✅ Removed item at index $index');
        
// //         if (_queueIndex >= index && _queueIndex > 0) {
// //           _queueIndex--;
// //           _queueIndexSubject.add(_queueIndex);
// //           _logger.info('📌 Updated queue index to $_queueIndex');
// //         }
        
// //         if (_queue.isEmpty) {
// //           _logger.info('📋 Queue is now empty, stopping playback');
// //           await stop();
// //         }
// //       } else {
// //         _logger.warning('⚠️ Invalid index: $index (queue length: ${_queue.length})');
// //       }
// //     } catch (e) {
// //       _logger.error('❌ Error removing from queue: $e');
// //     }
// //   }

// //   Future<void> clearQueue() async {
// //     _logger.info('🧹 clearQueue() called');
// //     try {
// //       _queue.clear();
// //       _queueIndex = -1;
// //       _currentMediaId = null;
// //       _queueSubject.add([]);
// //       _queueIndexSubject.add(-1);
// //       _currentMediaSubject.add(null);
// //       await stop();
// //       _logger.info('✅ Queue cleared');
// //     } catch (e) {
// //       _logger.error('❌ Error clearing queue: $e');
// //     }
// //   }

// //   void dispose() {
// //     _logger.info('🗑️ dispose() called');
// //     try {
// //       _logger.info('Disposing AudioPlayerService');
// //       _player.dispose();
// //       _queueSubject.close();
// //       _queueIndexSubject.close();
// //       _currentMediaSubject.close(); 
// //       _isDisposed = true;
// //       _instance = null;
// //       _logger.info('✅ AudioPlayerService disposed successfully');
// //     } catch (e) {
// //       _logger.error('❌ Error disposing: $e');
// //     }
// //   }

// //   // Reset the service (call before creating a new one if needed)
// //   static void reset() {
// //     //_logger.info('🔄 reset() called');
// //     if (_instance != null) {
// //       //_logger.info('Disposing existing instance');
// //       _instance!.dispose();
// //     }
// //     _instance = null;
// //     _isDisposed = false;
// //     //_logger.info('✅ Service reset complete');
// //   }
  
// //   // Add a debug method to check player state
// //   Future<void> debugPlayerState() async {
// //     _logger.info('========================================');
// //     _logger.info('🔍 PLAYER DEBUG INFO');
// //     _logger.info('========================================');
// //     _logger.info('Playing: ${_player.playing}');
// //     _logger.info('Position: ${_player.position.inSeconds}s');
// //     _logger.info('Duration: ${_player.duration?.inSeconds ?? 'null'}s');
// //     _logger.info('Volume: ${_player.volume}');
// //     _logger.info('Speed: ${_player.speed}');
// //     _logger.info('Processing State: ${_player.playerState.processingState}');
// //     _logger.info('Queue Length: ${_queue.length}');
// //     _logger.info('Queue Index: $_queueIndex');
// //     _logger.info('Current Media: $_currentMediaId');
// //     _logger.info('========================================');
// //   }
// // }

// // // // lib/features/audio_player/data/services/audio_player_service.dart
// // // import 'dart:async';
// // // import 'dart:io';
// // // import 'package:flutter/material.dart' hide RepeatMode;
// // // import 'package:just_audio/just_audio.dart';
// // // import 'package:media/features/mediadetection/domain/entities/media.dart';
// // // import 'package:rxdart/rxdart.dart';
// // // import '../../domain/entities/repeat_mode.dart';
// // // import '../../../../core/utils/helpers/logger_helper.dart';

// // // class AudioPlayerService {
// // //   // Remove the _instance pattern and use a simpler approach
// // //   static AudioPlayerService? _instance;
// // //   static bool _isDisposed = false;
  
// // //   final AudioPlayer _player = AudioPlayer();
// // //   final LoggerHelper _logger = LoggerHelper();
  
// // //   List<Media> _queue = [];
// // //   int _queueIndex = -1;
// // //   String? _currentMediaId;
  
// // //   // Stream controllers
// // //   final BehaviorSubject<List<Media>> _queueSubject = BehaviorSubject.seeded([]);
// // //   final BehaviorSubject<int> _queueIndexSubject = BehaviorSubject.seeded(-1);
// // //   final BehaviorSubject<Media?> _currentMediaSubject = BehaviorSubject.seeded(null);
  
// // //   // Private constructor
// // //   AudioPlayerService._internal() {
// // //     _initializePlayer();
// // //   }

// // //   // Factory to get the single instance
// // //   factory AudioPlayerService() {
// // //     if (_instance == null || _isDisposed) {
// // //       _instance = AudioPlayerService._internal();
// // //       _isDisposed = false;
// // //     }
// // //     return _instance!;
// // //   }

// // //   void _initializePlayer() {
// // //     try {
// // //       // Listen to player state changes
// // //       _player.playerStateStream.listen((state) {
// // //         _logger.debug('Player state: ${state.processingState}, ${state.playing}');
// // //       });

// // //       // Listen to position changes
// // //       _player.positionStream.listen((position) {
// // //         // Update position
// // //       });

// // //       // Listen to duration changes
// // //       _player.durationStream.listen((duration) {
// // //         // Update duration
// // //       });

// // //       // Listen to current index changes
// // //       _player.currentIndexStream.listen((index) {
// // //         if (index != null) {
// // //           _queueIndex = index;
// // //           _queueIndexSubject.add(index);
// // //           if (index < _queue.length) {
// // //             _currentMediaId = _queue[index].id;
// // //             _currentMediaSubject.add(_queue[index]);
// // //           }
// // //         }
// // //       });
// // //     } catch (e) {
// // //       _logger.error('Error initializing player: $e');
// // //     }
// // //   }
  

// // //   // Getters
// // //   Stream<PlayerState> get playerStateStream => _player.playerStateStream;
// // //   Stream<Duration> get positionStream => _player.positionStream;
// // //   Stream<Duration?> get durationStream => _player.durationStream;
// // //   Stream<List<Media>> get queueStream => _queueSubject.stream;
// // //   Stream<int> get queueIndexStream => _queueIndexSubject.stream;
// // //   Stream<Media?> get currentMediaStream => _currentMediaSubject.stream;
  
// // //   bool get isPlaying => _player.playing;
// // //   bool get isBuffering => _player.playerState.processingState == ProcessingState.buffering;
// // //   Duration get position => _player.position;
// // //   Duration? get duration => _player.duration;
// // //   double get volume => _player.volume;
// // //   double get speed => _player.speed;
// // //   int get queueLength => _queue.length;
// // //   bool get hasNext => _queueIndex < _queue.length - 1;
// // //   bool get hasPrevious => _queueIndex > 0;

// // //   Future<void> playMedia(Media media, {List<Media>? queue}) async {
// // //     try {
// // //       _logger.info('Playing media: ${media.title}');
// // //       _logger.info('File path: ${media.filePath}');
      
// // //       // Set up the queue
// // //       if (queue != null) {
// // //         _queue = queue;
// // //         _queueIndex = _queue.indexWhere((m) => m.id == media.id);
// // //         _queueSubject.add(_queue);
// // //       } else if (_queue.isEmpty || _queueIndex == -1) {
// // //         _queue = [media];
// // //         _queueIndex = 0;
// // //         _queueSubject.add(_queue);
// // //       } else {
// // //         final existingIndex = _queue.indexWhere((m) => m.id == media.id);
// // //         if (existingIndex == -1) {
// // //           _queue.add(media);
// // //           _queueIndex = _queue.length - 1;
// // //         } else {
// // //           _queueIndex = existingIndex;
// // //         }
// // //         _queueSubject.add(_queue);
// // //       }

// // //       _currentMediaId = media.id;
// // //       _currentMediaSubject.add(media);
// // //       _queueIndexSubject.add(_queueIndex);

// // //       // Check if file exists first
// // //       final file = File(media.filePath);
// // //       if (!await file.exists()) {
// // //         _logger.error('File does not exist: ${media.filePath}');
// // //         throw Exception('File not found');
// // //       }

// // //       // Load and play the audio
// // //       await _player.setAudioSource(
// // //         AudioSource.file(media.filePath),
// // //       );
      
// // //       await _player.play();
// // //       _logger.info('Playback started successfully');
// // //     } catch (e) {
// // //       _logger.error('Error playing media: $e');
// // //       rethrow;
// // //     }
// // //   }

// // //   Future<void> playQueue(List<Media> queue, {int startIndex = 0}) async {
// // //     try {
// // //       _logger.info('Playing queue with ${queue.length} items');
      
// // //       if (queue.isEmpty) {
// // //         _logger.warning('Queue is empty');
// // //         return;
// // //       }

// // //       _queue = queue;
// // //       _queueIndex = startIndex.clamp(0, queue.length - 1);
// // //       _queueSubject.add(_queue);
// // //       _queueIndexSubject.add(_queueIndex);
      
// // //       final media = queue[_queueIndex];
// // //       _currentMediaId = media.id;
// // //       _currentMediaSubject.add(media);

// // //       await _player.setAudioSource(
// // //         AudioSource.file(media.filePath),
// // //       );
      
// // //       await _player.play();
// // //       _logger.info('Queue playback started');
// // //     } catch (e) {
// // //       _logger.error('Error playing queue: $e');
// // //       rethrow;
// // //     }
// // //   }

// // //   Future<void> togglePlayPause() async {
// // //     try {
// // //       if (_player.playing) {
// // //         await _player.pause();
// // //         _logger.debug('Playback paused');
// // //       } else {
// // //         await _player.play();
// // //         _logger.debug('Playback resumed');
// // //       }
// // //     } catch (e) {
// // //       _logger.error('Error toggling play/pause: $e');
// // //     }
// // //   }

// // //   Future<void> play() async {
// // //     try {
// // //       await _player.play();
// // //     } catch (e) {
// // //       _logger.error('Error playing: $e');
// // //     }
// // //   }

// // //   Future<void> pause() async {
// // //     try {
// // //       await _player.pause();
// // //     } catch (e) {
// // //       _logger.error('Error pausing: $e');
// // //     }
// // //   }

// // //   Future<void> stop() async {
// // //     try {
// // //       await _player.stop();
// // //     } catch (e) {
// // //       _logger.error('Error stopping: $e');
// // //     }
// // //   }

// // //   Future<void> seek(Duration position) async {
// // //     try {
// // //       await _player.seek(position);
// // //     } catch (e) {
// // //       _logger.error('Error seeking: $e');
// // //     }
// // //   }

// // //   Future<void> next() async {
// // //     try {
// // //       if (hasNext) {
// // //         _queueIndex++;
// // //         _queueIndexSubject.add(_queueIndex);
// // //         final media = _queue[_queueIndex];
// // //         _currentMediaId = media.id;
// // //         _currentMediaSubject.add(media);
        
// // //         await _player.setAudioSource(
// // //           AudioSource.file(media.filePath),
// // //         );
// // //         await _player.play();
// // //         _logger.debug('Playing next track: ${media.title}');
// // //       }
// // //     } catch (e) {
// // //       _logger.error('Error playing next: $e');
// // //     }
// // //   }

// // //   Future<void> previous() async {
// // //     try {
// // //       if (hasPrevious) {
// // //         _queueIndex--;
// // //         _queueIndexSubject.add(_queueIndex);
// // //         final media = _queue[_queueIndex];
// // //         _currentMediaId = media.id;
// // //         _currentMediaSubject.add(media);
        
// // //         await _player.setAudioSource(
// // //           AudioSource.file(media.filePath),
// // //         );
// // //         await _player.play();
// // //         _logger.debug('Playing previous track: ${media.title}');
// // //       }
// // //     } catch (e) {
// // //       _logger.error('Error playing previous: $e');
// // //     }
// // //   }

// // //   Future<void> setVolume(double volume) async {
// // //     try {
// // //       await _player.setVolume(volume);
// // //     } catch (e) {
// // //       _logger.error('Error setting volume: $e');
// // //     }
// // //   }

// // //   Future<void> setSpeed(double speed) async {
// // //     try {
// // //       await _player.setSpeed(speed);
// // //     } catch (e) {
// // //       _logger.error('Error setting speed: $e');
// // //     }
// // //   }

// // //   Future<void> setRepeatMode(RepeatMode mode) async {
// // //     try {
// // //       final loopMode = _convertToLoopMode(mode);
// // //       await _player.setLoopMode(loopMode);
// // //     } catch (e) {
// // //       _logger.error('Error setting repeat mode: $e');
// // //     }
// // //   }

// // //   LoopMode _convertToLoopMode(RepeatMode mode) {
// // //     switch (mode) {
// // //       case RepeatMode.off:
// // //         return LoopMode.off;
// // //       case RepeatMode.one:
// // //         return LoopMode.one;
// // //       case RepeatMode.all:
// // //         return LoopMode.all;
// // //     }
// // //   }

// // //   Future<void> setShuffle(bool enabled) async {
// // //     try {
// // //       await _player.setShuffleModeEnabled(enabled);
// // //     } catch (e) {
// // //       _logger.error('Error setting shuffle: $e');
// // //     }
// // //   }

// // //   Future<void> removeFromQueue(int index) async {
// // //     try {
// // //       if (index >= 0 && index < _queue.length) {
// // //         _queue.removeAt(index);
// // //         _queueSubject.add(_queue);
        
// // //         if (_queueIndex >= index && _queueIndex > 0) {
// // //           _queueIndex--;
// // //           _queueIndexSubject.add(_queueIndex);
// // //         }
        
// // //         if (_queue.isEmpty) {
// // //           await stop();
// // //         }
// // //       }
// // //     } catch (e) {
// // //       _logger.error('Error removing from queue: $e');
// // //     }
// // //   }

// // //   Future<void> clearQueue() async {
// // //     try {
// // //       _queue.clear();
// // //       _queueIndex = -1;
// // //       _currentMediaId = null;
// // //       _queueSubject.add([]);
// // //       _queueIndexSubject.add(-1);
// // //       _currentMediaSubject.add(null);
// // //       await stop();
// // //     } catch (e) {
// // //       _logger.error('Error clearing queue: $e');
// // //     }
// // //   }

// // //   void dispose() {
// // //     try {
// // //       _logger.info('Disposing AudioPlayerService');
// // //       _player.dispose();
// // //       _queueSubject.close();
// // //       _queueIndexSubject.close();
// // //       _currentMediaSubject.close(); 
// // //       _isDisposed = true;
// // //       _instance = null;
// // //     } catch (e) {
// // //       _logger.error('Error disposing: $e');
// // //     }
// // //   }

// // //   // Reset the service (call before creating a new one if needed)
// // //   static void reset() {
// // //     if (_instance != null) {
// // //       _instance!.dispose();
// // //     }
// // //     _instance = null;
// // //     _isDisposed = false;
// // //   }
  
// // // }
