// lib/features/audio_player/presentation/bloc/audio_player_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:media/features/mediadetection/domain/entities/media.dart';
import '../../domain/entities/repeat_mode.dart';

class AudioPlayerState extends Equatable {
  final Media? currentMedia;
  final List<Media> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration? duration;
  final Duration position;
  final double volume;
  final double speed;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final bool hasError;
  final String? errorMessage;

  const AudioPlayerState({
    this.currentMedia,
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.duration,
    this.position = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.repeatMode = RepeatMode.off,
    this.isShuffleEnabled = false,
    this.hasError = false,
    this.errorMessage,
  });

  AudioPlayerState copyWith({
    Media? currentMedia,
    List<Media>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? duration,
    Duration? position,
    double? volume,
    double? speed,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    bool? hasError,
    String? errorMessage,
  }) {
    return AudioPlayerState(
      currentMedia: currentMedia ?? this.currentMedia,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;
  bool get isEmpty => queue.isEmpty;
  bool get isNotEmpty => queue.isNotEmpty;
  
  double get progress => duration != null && duration!.inMilliseconds > 0
      ? position.inMilliseconds / duration!.inMilliseconds
      : 0.0;
      
  String get formattedPosition => _formatDuration(position);
  
  String get formattedDuration => duration != null 
      ? _formatDuration(duration!) 
      : '--:--';
      
  String get formattedProgress => '$formattedPosition / $formattedDuration';

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        currentMedia,
        queue,
        currentIndex,
        isPlaying,
        isBuffering,
        duration,
        position,
        volume,
        speed,
        repeatMode,
        isShuffleEnabled,
        hasError,
        errorMessage,
      ];
}

// import 'package:equatable/equatable.dart';
// import 'package:flutter/material.dart' hide RepeatMode;
// import 'package:media/features/mediadetection/domain/entities/media.dart';
// import '../../domain/entities/repeat_mode.dart';

// class AudioPlayerState extends Equatable {
//   final Media? currentMedia;
//   final List<Media> queue;
//   final int currentIndex;
//   final bool isPlaying;
//   final bool isBuffering;
//   final Duration? duration;
//   final Duration position;
//   final double volume;
//   final double speed;
//   final RepeatMode repeatMode;
//   final bool isShuffleEnabled;
//   final bool hasError;
//   final String? errorMessage;

//   const AudioPlayerState({
//     this.currentMedia,
//     this.queue = const [],
//     this.currentIndex = -1,
//     this.isPlaying = false,
//     this.isBuffering = false,
//     this.duration,
//     this.position = Duration.zero,
//     this.volume = 1.0,
//     this.speed = 1.0,
//     this.repeatMode = RepeatMode.off,
//     this.isShuffleEnabled = false,
//     this.hasError = false,
//     this.errorMessage,
//   });

//   AudioPlayerState copyWith({
//     Media? currentMedia,
//     List<Media>? queue,
//     int? currentIndex,
//     bool? isPlaying,
//     bool? isBuffering,
//     Duration? duration,
//     Duration? position,
//     double? volume,
//     double? speed,
//     RepeatMode? repeatMode,
//     bool? isShuffleEnabled,
//     bool? hasError,
//     String? errorMessage,
//   }) {
//     return AudioPlayerState(
//       currentMedia: currentMedia ?? this.currentMedia,
//       queue: queue ?? this.queue,
//       currentIndex: currentIndex ?? this.currentIndex,
//       isPlaying: isPlaying ?? this.isPlaying,
//       isBuffering: isBuffering ?? this.isBuffering,
//       duration: duration ?? this.duration,
//       position: position ?? this.position,
//       volume: volume ?? this.volume,
//       speed: speed ?? this.speed,
//       repeatMode: repeatMode ?? this.repeatMode,
//       isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
//       hasError: hasError ?? this.hasError,
//       errorMessage: errorMessage ?? this.errorMessage,
//     );
//   }

//   bool get hasNext => currentIndex < queue.length - 1;
//   bool get hasPrevious => currentIndex > 0;
//   bool get isEmpty => queue.isEmpty;
//   bool get isNotEmpty => queue.isNotEmpty;
  
//   double get progress => duration != null && duration!.inMilliseconds > 0
//       ? position.inMilliseconds / duration!.inMilliseconds
//       : 0.0;
      
//   String get formattedPosition => _formatDuration(position);
  
//   String get formattedDuration => duration != null 
//       ? _formatDuration(duration!) 
//       : '--:--';
      
//   String get formattedProgress => '$formattedPosition / $formattedDuration';

//   String _formatDuration(Duration duration) {
//     final minutes = duration.inMinutes.remainder(60);
//     final seconds = duration.inSeconds.remainder(60);
//     return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//   }

//   @override
//   List<Object?> get props => [
//         currentMedia,
//         queue,
//         currentIndex,
//         isPlaying,
//         isBuffering,
//         duration,
//         position,
//         volume,
//         speed,
//         repeatMode,
//         isShuffleEnabled,
//         hasError,
//         errorMessage,
//       ];
// }