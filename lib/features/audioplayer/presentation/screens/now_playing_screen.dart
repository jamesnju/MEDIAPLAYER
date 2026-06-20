// Hide Flutter's RepeatMode at the top
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import '../bloc/audio_player_bloc.dart';
import '../bloc/audio_player_event.dart';
import '../bloc/audio_player_state.dart';
import '../../domain/entities/repeat_mode.dart'; // Now this is the only RepeatMode
import '../../../../core/themes/color_palette.dart';
import '../../../../core/themes/typography.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, state) {
          if (state.currentMedia == null) {
            return const Center(
              child: Text(
                'No media playing',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _buildAlbumArt(state),
                ),
                _buildSongInfo(state),
                _buildProgress(context, state),
                _buildControls(context, state),
                _buildExtraControls(context, state),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(AudioPlayerState state) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: state.currentMedia?.albumArt != null
            ? Image.network(
                state.currentMedia!.albumArt!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
              )
            : _buildPlaceholderArt(),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primary.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.music_note,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSongInfo(AudioPlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song Title with Marquee
          SizedBox(
            height: 30,
            child: state.currentMedia!.title.length > 30
                ? Marquee(
                    text: state.currentMedia!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 20,
                    velocity: 30,
                  )
                : Text(
                    state.currentMedia!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            state.currentMedia!.artist,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, AudioPlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                pressedElevation: 8,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.shade800,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: state.progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final position = Duration(
                  milliseconds: (value * (state.duration?.inMilliseconds ?? 0)).round(),
                );
                context.read<AudioPlayerBloc>().add(Seek(position));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.formattedPosition,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                state.formattedDuration,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AudioPlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.shuffle,
            color: state.isShuffleEnabled ? AppColors.primary : Colors.grey,
            onTap: () {
              context.read<AudioPlayerBloc>().add(ToggleShuffle());
            },
          ),
          const SizedBox(width: 20),
          _buildControlButton(
            icon: Icons.skip_previous,
            onTap: state.hasPrevious
                ? () {
                    context.read<AudioPlayerBloc>().add(PreviousTrack());
                  }
                : null,
          ),
          const SizedBox(width: 20),
          _buildPlayButton(context, state),
          const SizedBox(width: 20),
          _buildControlButton(
            icon: Icons.skip_next,
            onTap: state.hasNext
                ? () {
                    context.read<AudioPlayerBloc>().add(NextTrack());
                  }
                : null,
          ),
          const SizedBox(width: 20),
          _buildControlButton(
            icon: _getRepeatIcon(state.repeatMode),
            color: state.repeatMode != RepeatMode.off ? AppColors.primary : Colors.grey,
            onTap: () {
              final modes = [RepeatMode.off, RepeatMode.one, RepeatMode.all];
              final currentIndex = modes.indexOf(state.repeatMode);
              final nextIndex = (currentIndex + 1) % modes.length;
              context.read<AudioPlayerBloc>().add(SetRepeatMode(modes[nextIndex]));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, AudioPlayerState state) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          state.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
        onPressed: () {
          context.read<AudioPlayerBloc>().add(TogglePlayPause());
        },
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: color ?? Colors.white,
        size: 28,
      ),
      onPressed: onTap,
      splashRadius: 24,
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat;
      default:
        return Icons.repeat;
    }
  }

  Widget _buildExtraControls(BuildContext context, AudioPlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildExtraControlButton(
            icon: Icons.favorite_border,
            label: 'Favorite',
            onTap: () {
              // TODO: Add to favorites
            },
          ),
          _buildExtraControlButton(
            icon: Icons.playlist_add,
            label: 'Add to',
            onTap: () {
              // TODO: Add to playlist
            },
          ),
          _buildExtraControlButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () {
              // TODO: Download
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtraControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}