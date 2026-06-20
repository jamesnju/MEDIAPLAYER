import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:media/features/mediadetection/domain/entities/media.dart';
import '../../domain/entities/repeat_mode.dart';

abstract class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayMedia extends AudioPlayerEvent {
  final Media media;
  final List<Media>? queue;

  const PlayMedia(this.media, {this.queue});

  @override
  List<Object?> get props => [media, queue];
}

class PlayQueue extends AudioPlayerEvent {
  final List<Media> queue;
  final int startIndex;

  const PlayQueue(this.queue, {this.startIndex = 0});

  @override
  List<Object?> get props => [queue, startIndex];
}

class TogglePlayPause extends AudioPlayerEvent {}

class Play extends AudioPlayerEvent {}

class Pause extends AudioPlayerEvent {}

class Stop extends AudioPlayerEvent {}

class Seek extends AudioPlayerEvent {
  final Duration position;

  const Seek(this.position);

  @override
  List<Object?> get props => [position];
}

class NextTrack extends AudioPlayerEvent {}

class PreviousTrack extends AudioPlayerEvent {}

class SetVolume extends AudioPlayerEvent {
  final double volume;

  const SetVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

class SetSpeed extends AudioPlayerEvent {
  final double speed;

  const SetSpeed(this.speed);

  @override
  List<Object?> get props => [speed];
}

class SetRepeatMode extends AudioPlayerEvent {
  final RepeatMode mode;

  const SetRepeatMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ToggleShuffle extends AudioPlayerEvent {}

class RemoveFromQueue extends AudioPlayerEvent {
  final int index;

  const RemoveFromQueue(this.index);

  @override
  List<Object?> get props => [index];
}

class ClearQueue extends AudioPlayerEvent {}

class UpdatePosition extends AudioPlayerEvent {
  final Duration position;

  const UpdatePosition(this.position);

  @override
  List<Object?> get props => [position];
}