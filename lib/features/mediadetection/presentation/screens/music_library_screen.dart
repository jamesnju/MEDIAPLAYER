import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_bloc.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_event.dart';
import 'package:media/features/audioplayer/presentation/screens/now_playing_screen.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';
import 'package:media/features/mediadetection/presentation/widgets/common/media_item_widget.dart';
import 'package:media/features/mediadetection/presentation/widgets/loading/loading_widget.dart';
import '../bloc/media_bloc.dart';
import '../bloc/media_event.dart';
import '../bloc/media_state.dart';
import '../../../../core/themes/color_palette.dart';
import '../../../../core/themes/typography.dart';

class MusicLibraryScreen extends StatelessWidget {
  const MusicLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MediaBloc>().add( RescanMedia());
            },
          ),
        ],
      ),
      body: BlocConsumer<MediaBloc, MediaState>(
        listener: (context, state) {
          if (state is MediaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MediaOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MediaLoading) {
            return const LoadingWidget();
          }

          if (state is MediaLoaded) {
            final audioFiles = state.media.where((m) => m.isAudio).toList();
            
            if (audioFiles.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: audioFiles.length,
              itemBuilder: (context, index) {
                final media = audioFiles[index];
                return MediaItemWidget(
                  media: media,
                  onTap: () {
                    // FIXED: Play the media when tapped
                    _playMedia(context, media, audioFiles);
                  },
                  onFavoriteTap: () {
                    context.read<MediaBloc>().add(ToggleFavorite(media.id));
                  },
                );
              },
            );
          }

          if (state is MediaError) {
            return _buildErrorState(context, state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
// In music_library_screen.dart
void _playMedia(BuildContext context, Media media, List<Media> queue) {
  try {
    final audioBloc = context.read<AudioPlayerBloc>();
    audioBloc.add(PlayMedia(media, queue: queue));
    
    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loading...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Navigate to Now Playing screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NowPlayingScreen(),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  // FIXED: Add this method to handle media playback
  // void _playMedia(BuildContext context, Media media, List<Media> queue) {
  //   // Get the AudioPlayerBloc and dispatch PlayMedia event
  //   final audioBloc = context.read<AudioPlayerBloc>();
    
  //   // Play the selected media with the full queue
  //   audioBloc.add(PlayMedia(media, queue: queue));
    
  //   // Navigate to Now Playing screen
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => const NowPlayingScreen(),
  //     ),
  //   );
  // }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Music Found',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the refresh button to scan for music files',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MediaBloc>().add( ScanMedia());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Scan for Music'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<MediaBloc>().add(const LoadMedia(mediaType: 'audio'));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:media/features/mediadetection/presentation/widgets/common/media_item_widget.dart';
// import 'package:media/features/mediadetection/presentation/widgets/loading/loading_widget.dart';
// import '../bloc/media_bloc.dart';
// import '../bloc/media_event.dart';
// import '../bloc/media_state.dart';
// import '../../../../core/themes/color_palette.dart';
// import '../../../../core/themes/typography.dart';

// class MusicLibraryScreen extends StatelessWidget {
//   const MusicLibraryScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Music Library'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               // TODO: Navigate to search
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               context.read<MediaBloc>().add( RescanMedia());
//             },
//           ),
//         ],
//       ),
//       body: BlocConsumer<MediaBloc, MediaState>(
//         listener: (context, state) {
//           if (state is MediaError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           } else if (state is MediaOperationSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: Colors.green,
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is MediaLoading) {
//             return const LoadingWidget();
//           }

//           if (state is MediaLoaded) {
//             final audioFiles = state.media.where((m) => m.isAudio).toList();
            
//             if (audioFiles.isEmpty) {
//               return _buildEmptyState(context);
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: audioFiles.length,
//               itemBuilder: (context, index) {
//                 final media = audioFiles[index];
//                 return MediaItemWidget(
//                   media: media,
//                   onTap: () {
//                     // TODO: Navigate to now playing
//                   },
//                   onFavoriteTap: () {
//                     context.read<MediaBloc>().add(ToggleFavorite(media.id));
//                   },
//                 );
//               },
//             );
//           }

//           if (state is MediaError) {
//             return _buildErrorState(context, state.message);
//           }

//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               gradient: AppColors.primaryGradient,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.music_note,
//               size: 40,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No Music Found',
//             style: AppTypography.headlineSmall,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tap the refresh button to scan for music files',
//             style: AppTypography.bodyMedium,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () {
//               context.read<MediaBloc>().add( ScanMedia());
//             },
//             icon: const Icon(Icons.refresh),
//             label: const Text('Scan for Music'),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 32,
//                 vertical: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(BuildContext context, String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.error_outline,
//             size: 64,
//             color: Colors.red[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Something went wrong',
//             style: AppTypography.headlineSmall,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             style: AppTypography.bodyMedium,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () {
//               context.read<MediaBloc>().add(const LoadMedia(mediaType: 'audio'));
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
// }