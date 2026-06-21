// Hide Flutter's RepeatMode at the top
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import '../bloc/audio_player_bloc.dart';
import '../bloc/audio_player_event.dart';
import '../bloc/audio_player_state.dart';
import '../../domain/entities/repeat_mode.dart'; // Now this is the only RepeatMode
import '../../../../core/themes/color_palette.dart';

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenSize = MediaQuery.of(context).size;
                final isSmallScreen = screenSize.width < 360;
                final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
                final isLargeScreen = screenSize.width >= 600;
                
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildHeader(context),
                          Expanded(
                            flex: isSmallScreen ? 2 : 3,
                            child: _buildAlbumArt(state, screenSize),
                          ),
                          _buildSongInfo(state, isSmallScreen),
                          _buildProgress(context, state, isSmallScreen),
                          _buildControls(context, state, isSmallScreen),
                          _buildExtraControls(context, state, isSmallScreen),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_downward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Flexible(
            child: Text(
              'Now Playing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(AudioPlayerState state, Size screenSize) {
    final double size = screenSize.width * 0.75;
    final double maxSize = screenSize.height * 0.45;
    final double albumSize = size > maxSize ? maxSize : size;
    
    return Container(
      margin: EdgeInsets.all(screenSize.width * 0.04),
      constraints: BoxConstraints(
        maxWidth: albumSize,
        maxHeight: albumSize,
      ),
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
      child: AspectRatio(
        aspectRatio: 1,
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

  Widget _buildSongInfo(AudioPlayerState state, bool isSmallScreen) {
    final double titleFontSize = isSmallScreen ? 18.0 : 22.0;
    final double artistFontSize = isSmallScreen ? 14.0 : 16.0;
    final int marqueeThreshold = isSmallScreen ? 20 : 30;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 24.0,
        vertical: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song Title with Marquee
          SizedBox(
            height: isSmallScreen ? 26.0 : 30.0,
            child: state.currentMedia!.title.length > marqueeThreshold
                ? Marquee(
                    text: state.currentMedia!.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 20.0,
                    velocity: 30.0,
                  )
                : Text(
                    state.currentMedia!.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          SizedBox(height: isSmallScreen ? 2.0 : 4.0),
          Text(
            state.currentMedia!.artist,
            style: TextStyle(
              color: Colors.grey,
              fontSize: artistFontSize,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
    final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
    final double thumbRadius = isSmallScreen ? 6.0 : 8.0;
    final double overlayRadius = isSmallScreen ? 12.0 : 16.0;
    final double fontSize = isSmallScreen ? 10.0 : 12.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4.0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: isSmallScreen ? 3.0 : 4.0,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: thumbRadius,
                pressedElevation: 8.0,
              ),
              overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: fontSize,
                ),
              ),
              Text(
                state.formattedDuration,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
    final double spacing = isSmallScreen ? 8.0 : 14.0; // Reduced spacing
    final double iconSize = isSmallScreen ? 22.0 : 26.0;
    final double buttonSize = isSmallScreen ? 48.0 : 60.0;
    final double playIconSize = isSmallScreen ? 26.0 : 30.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0, // Reduced horizontal padding
        vertical: isSmallScreen ? 4.0 : 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shuffle button
          _buildControlButton(
            icon: Icons.shuffle,
            color: state.isShuffleEnabled ? AppColors.primary : Colors.grey,
            onTap: () {
              context.read<AudioPlayerBloc>().add(ToggleShuffle());
            },
            iconSize: iconSize,
          ),
          SizedBox(width: spacing),
          
          // Previous button
          _buildControlButton(
            icon: Icons.skip_previous,
            onTap: state.hasPrevious
                ? () {
                    context.read<AudioPlayerBloc>().add(PreviousTrack());
                  }
                : null,
            iconSize: iconSize,
          ),
          SizedBox(width: spacing),
          
          // Play/Pause button
          _buildPlayButton(context, state, buttonSize, playIconSize),
          SizedBox(width: spacing),
          
          // Next button
          _buildControlButton(
            icon: Icons.skip_next,
            onTap: state.hasNext
                ? () {
                    context.read<AudioPlayerBloc>().add(NextTrack());
                  }
                : null,
            iconSize: iconSize,
          ),
          SizedBox(width: spacing),
          
          // Repeat button - with flexible to prevent overflow
          Flexible(
            child: _buildControlButton(
              icon: _getRepeatIcon(state.repeatMode),
              color: state.repeatMode != RepeatMode.off ? AppColors.primary : Colors.grey,
              onTap: () {
                final modes = [RepeatMode.off, RepeatMode.one, RepeatMode.all];
                final currentIndex = modes.indexOf(state.repeatMode);
                final nextIndex = (currentIndex + 1) % modes.length;
                context.read<AudioPlayerBloc>().add(SetRepeatMode(modes[nextIndex]));
              },
              iconSize: iconSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, AudioPlayerState state, double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          state.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: iconSize,
        ),
        onPressed: () {
          context.read<AudioPlayerBloc>().add(TogglePlayPause());
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
    double iconSize = 26.0,
  }) {
    return SizedBox(
      width: iconSize + 16.0, // Ensure consistent touch target
      height: iconSize + 16.0,
      child: IconButton(
        icon: Icon(
          icon,
          color: color ?? Colors.white,
          size: iconSize,
        ),
        onPressed: onTap,
        splashRadius: 20.0,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
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

  Widget _buildExtraControls(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
    final double iconSize = isSmallScreen ? 18.0 : 22.0;
    final double labelSize = isSmallScreen ? 9.0 : 11.0;
    final double spacing = isSmallScreen ? 4.0 : 12.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.0 : 24.0,
        vertical: isSmallScreen ? 4.0 : 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildExtraControlButton(
            icon: Icons.favorite_border,
            label: 'Favorite',
            onTap: () {
              // TODO: Add to favorites
            },
            iconSize: iconSize,
            labelSize: labelSize,
          ),
          SizedBox(width: spacing),
          _buildExtraControlButton(
            icon: Icons.playlist_add,
            label: 'Add to',
            onTap: () {
              // TODO: Add to playlist
            },
            iconSize: iconSize,
            labelSize: labelSize,
          ),
          SizedBox(width: spacing),
          _buildExtraControlButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () {
              // TODO: Download
            },
            iconSize: iconSize,
            labelSize: labelSize,
          ),
        ],
      ),
    );
  }

  Widget _buildExtraControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double iconSize = 22.0,
    double labelSize = 11.0,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.grey,
            size: iconSize,
          ),
          SizedBox(height: labelSize * 0.4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: labelSize,
            ),
          ),
        ],
      ),
    );
  }
}


// // Hide Flutter's RepeatMode at the top
// import 'package:flutter/material.dart' hide RepeatMode;
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:marquee/marquee.dart';
// import '../bloc/audio_player_bloc.dart';
// import '../bloc/audio_player_event.dart';
// import '../bloc/audio_player_state.dart';
// import '../../domain/entities/repeat_mode.dart'; // Now this is the only RepeatMode
// import '../../../../core/themes/color_palette.dart';
// import '../../../../core/themes/typography.dart';

// class NowPlayingScreen extends StatelessWidget {
//   const NowPlayingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
//         builder: (context, state) {
//           if (state.currentMedia == null) {
//             return const Center(
//               child: Text(
//                 'No media playing',
//                 style: TextStyle(color: Colors.white),
//               ),
//             );
//           }

//           return SafeArea(
//             child: Column(
//               children: [
//                 _buildHeader(context),
//                 Expanded(
//                   child: _buildAlbumArt(state),
//                 ),
//                 _buildSongInfo(state),
//                 _buildProgress(context, state),
//                 _buildControls(context, state),
//                 _buildExtraControls(context, state),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_downward, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const Text(
//             'Now Playing',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert, color: Colors.white),
//             onPressed: () {
//               // Show options
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAlbumArt(AudioPlayerState state) {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.5),
//             blurRadius: 20,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: state.currentMedia?.albumArt != null
//             ? Image.network(
//                 state.currentMedia!.albumArt!,
//                 fit: BoxFit.cover,
//                 width: double.infinity,
//                 height: double.infinity,
//                 errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
//               )
//             : _buildPlaceholderArt(),
//       ),
//     );
//   }

//   Widget _buildPlaceholderArt() {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       color: AppColors.primary.withOpacity(0.3),
//       child: const Center(
//         child: Icon(
//           Icons.music_note,
//           size: 80,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }

//   Widget _buildSongInfo(AudioPlayerState state) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Song Title with Marquee
//           SizedBox(
//             height: 30,
//             child: state.currentMedia!.title.length > 30
//                 ? Marquee(
//                     text: state.currentMedia!.title,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     scrollAxis: Axis.horizontal,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     blankSpace: 20,
//                     velocity: 30,
//                   )
//                 : Text(
//                     state.currentMedia!.title,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             state.currentMedia!.artist,
//             style: const TextStyle(
//               color: Colors.grey,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProgress(BuildContext context, AudioPlayerState state) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: Column(
//         children: [
//           SliderTheme(
//             data: SliderThemeData(
//               trackHeight: 4,
//               thumbShape: const RoundSliderThumbShape(
//                 enabledThumbRadius: 8,
//                 pressedElevation: 8,
//               ),
//               overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
//               activeTrackColor: AppColors.primary,
//               inactiveTrackColor: Colors.grey.shade800,
//               thumbColor: AppColors.primary,
//               overlayColor: AppColors.primary.withOpacity(0.2),
//             ),
//             child: Slider(
//               value: state.progress.clamp(0.0, 1.0),
//               onChanged: (value) {
//                 final position = Duration(
//                   milliseconds: (value * (state.duration?.inMilliseconds ?? 0)).round(),
//                 );
//                 context.read<AudioPlayerBloc>().add(Seek(position));
//               },
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 state.formattedPosition,
//                 style: const TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                 ),
//               ),
//               Text(
//                 state.formattedDuration,
//                 style: const TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControls(BuildContext context, AudioPlayerState state) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _buildControlButton(
//             icon: Icons.shuffle,
//             color: state.isShuffleEnabled ? AppColors.primary : Colors.grey,
//             onTap: () {
//               context.read<AudioPlayerBloc>().add(ToggleShuffle());
//             },
//           ),
//           const SizedBox(width: 20),
//           _buildControlButton(
//             icon: Icons.skip_previous,
//             onTap: state.hasPrevious
//                 ? () {
//                     context.read<AudioPlayerBloc>().add(PreviousTrack());
//                   }
//                 : null,
//           ),
//           const SizedBox(width: 20),
//           _buildPlayButton(context, state),
//           const SizedBox(width: 20),
//           _buildControlButton(
//             icon: Icons.skip_next,
//             onTap: state.hasNext
//                 ? () {
//                     context.read<AudioPlayerBloc>().add(NextTrack());
//                   }
//                 : null,
//           ),
//           const SizedBox(width: 20),
//           _buildControlButton(
//             icon: _getRepeatIcon(state.repeatMode),
//             color: state.repeatMode != RepeatMode.off ? AppColors.primary : Colors.grey,
//             onTap: () {
//               final modes = [RepeatMode.off, RepeatMode.one, RepeatMode.all];
//               final currentIndex = modes.indexOf(state.repeatMode);
//               final nextIndex = (currentIndex + 1) % modes.length;
//               context.read<AudioPlayerBloc>().add(SetRepeatMode(modes[nextIndex]));
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPlayButton(BuildContext context, AudioPlayerState state) {
//     return Container(
//       width: 64,
//       height: 64,
//       decoration: const BoxDecoration(
//         color: AppColors.primary,
//         shape: BoxShape.circle,
//       ),
//       child: IconButton(
//         icon: Icon(
//           state.isPlaying ? Icons.pause : Icons.play_arrow,
//           color: Colors.white,
//           size: 32,
//         ),
//         onPressed: () {
//           context.read<AudioPlayerBloc>().add(TogglePlayPause());
//         },
//         padding: EdgeInsets.zero,
//       ),
//     );
//   }

//   Widget _buildControlButton({
//     required IconData icon,
//     Color? color,
//     VoidCallback? onTap,
//   }) {
//     return IconButton(
//       icon: Icon(
//         icon,
//         color: color ?? Colors.white,
//         size: 28,
//       ),
//       onPressed: onTap,
//       splashRadius: 24,
//     );
//   }

//   IconData _getRepeatIcon(RepeatMode mode) {
//     switch (mode) {
//       case RepeatMode.off:
//         return Icons.repeat;
//       case RepeatMode.one:
//         return Icons.repeat_one;
//       case RepeatMode.all:
//         return Icons.repeat;
//       default:
//         return Icons.repeat;
//     }
//   }

//   Widget _buildExtraControls(BuildContext context, AudioPlayerState state) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildExtraControlButton(
//             icon: Icons.favorite_border,
//             label: 'Favorite',
//             onTap: () {
//               // TODO: Add to favorites
//             },
//           ),
//           _buildExtraControlButton(
//             icon: Icons.playlist_add,
//             label: 'Add to',
//             onTap: () {
//               // TODO: Add to playlist
//             },
//           ),
//           _buildExtraControlButton(
//             icon: Icons.download,
//             label: 'Download',
//             onTap: () {
//               // TODO: Download
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExtraControlButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             color: Colors.grey,
//             size: 24,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.grey,
//               fontSize: 11,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }