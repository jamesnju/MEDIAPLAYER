import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_bloc.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_event.dart';
import 'package:media/features/audioplayer/presentation/screens/now_playing_screen.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';
import 'package:media/features/mediadetection/presentation/widgets/common/video_item_widget.dart';
import 'package:media/features/mediadetection/presentation/widgets/loading/loading_widget.dart';
import '../bloc/media_bloc.dart';
import '../bloc/media_event.dart';
import '../bloc/media_state.dart';
import '../../../../core/themes/color_palette.dart';
import '../../../../core/themes/typography.dart';

class VideoLibraryScreen extends StatelessWidget {
  const VideoLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Library'),
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
          }
        },
        builder: (context, state) {
          if (state is MediaLoading) {
            return const LoadingWidget();
          }

          if (state is MediaLoaded) {
            final videoFiles = state.media.where((m) => m.isVideo).toList();
            
            if (videoFiles.isEmpty) {
              return _buildEmptyState(context);
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: videoFiles.length,
              itemBuilder: (context, index) {
                final media = videoFiles[index];
                return VideoItemWidget(
                  media: media,
                  onTap: () {
                    // FIXED: Play the video when tapped
                    _playMedia(context, media, videoFiles);
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

  // Add this method to handle video playback
  void _playMedia(BuildContext context, Media media, List<Media> queue) {
    // Get the AudioPlayerBloc and dispatch PlayMedia event
    final audioBloc = context.read<AudioPlayerBloc>();
    
    // Play the selected media with the full queue
    audioBloc.add(PlayMedia(media, queue: queue));
    
    // Navigate to Now Playing screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NowPlayingScreen(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.video_library,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Videos Found',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the refresh button to scan for video files',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MediaBloc>().add( ScanMedia());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Scan for Videos'),
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
              context.read<MediaBloc>().add(const LoadMedia(mediaType: 'video'));
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
// import 'package:media/features/mediadetection/presentation/widgets/common/video_item_widget.dart';
// import 'package:media/features/mediadetection/presentation/widgets/loading/loading_widget.dart';
// import '../bloc/media_bloc.dart';
// import '../bloc/media_event.dart';
// import '../bloc/media_state.dart';
// import '../../../../core/themes/color_palette.dart';
// import '../../../../core/themes/typography.dart';

// class VideoLibraryScreen extends StatelessWidget {
//   const VideoLibraryScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Video Library'),
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
//           }
//         },
//         builder: (context, state) {
//           if (state is MediaLoading) {
//             return const LoadingWidget();
//           }

//           if (state is MediaLoaded) {
//             final videoFiles = state.media.where((m) => m.isVideo).toList();
            
//             if (videoFiles.isEmpty) {
//               return _buildEmptyState(context);
//             }

//             return GridView.builder(
//               padding: const EdgeInsets.all(16),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 0.75,
//                 crossAxisSpacing: 8,
//                 mainAxisSpacing: 8,
//               ),
//               itemCount: videoFiles.length,
//               itemBuilder: (context, index) {
//                 final media = videoFiles[index];
//                 return VideoItemWidget(
//                   media: media,
//                   onTap: () {
//                     // TODO: Navigate to video player
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
//               gradient: AppColors.accentGradient,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.video_library,
//               size: 40,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No Videos Found',
//             style: AppTypography.headlineSmall,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tap the refresh button to scan for video files',
//             style: AppTypography.bodyMedium,
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () {
//               context.read<MediaBloc>().add( ScanMedia());
//             },
//             icon: const Icon(Icons.refresh),
//             label: const Text('Scan for Videos'),
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
//               context.read<MediaBloc>().add(const LoadMedia(mediaType: 'video'));
//             },
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }
// }