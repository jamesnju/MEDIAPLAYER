import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_bloc.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_event.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_state.dart';
import 'package:media/features/audioplayer/presentation/screens/now_playing_screen.dart';
import 'package:media/features/mediadetection/presentation/bloc/media_bloc.dart';
import 'package:media/features/mediadetection/presentation/bloc/media_event.dart';
import 'package:media/features/mediadetection/presentation/bloc/media_state.dart';
import 'package:media/features/mediadetection/presentation/screens/music_library_screen.dart';
import 'package:media/features/mediadetection/presentation/screens/video_library_screen.dart';
import 'package:media/features/mediadetection/presentation/widgets/loading/loading_widget.dart';
import '../../../../core/themes/color_palette.dart';
import '../../../../core/themes/typography.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaPlayer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<MediaBloc, MediaState>(
              builder: (context, state) {
                if (state is MediaLoading) {
                  return const LoadingWidget(message: 'Loading media library...');
                }

                if (state is MediaLoaded) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome section
                        Text(
                          'Welcome to MediaPlayer',
                          style: AppTypography.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your media library at your fingertips',
                          style: AppTypography.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.music_note,
                                label: 'Songs',
                                count: state.audioCount,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.video_library,
                                label: 'Videos',
                                count: state.videoCount,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Quick access section
                        Text(
                          'Quick Access',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAccessCard(
                                icon: Icons.music_note,
                                label: 'Music',
                                color: AppColors.primary,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MusicLibraryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAccessCard(
                                icon: Icons.video_library,
                                label: 'Videos',
                                color: AppColors.secondary,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VideoLibraryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAccessCard(
                                icon: Icons.playlist_play,
                                label: 'Playlists',
                                color: Colors.green,
                                onTap: () {
                                  // TODO: Navigate to playlists
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAccessCard(
                                icon: Icons.favorite,
                                label: 'Favorites',
                                color: Colors.red,
                                onTap: () {
                                  // TODO: Navigate to favorites
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Recently played section
                        if (state.media.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recently Played',
                                style: AppTypography.titleLarge,
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Navigate to full history
                                },
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.media.take(10).length,
                              itemBuilder: (context, index) {
                                final media = state.media[index];
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        media.isAudio
                                            ? Icons.music_note
                                            : Icons.video_library,
                                        color: media.isAudio
                                            ? AppColors.primary
                                            : AppColors.secondary,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        media.title,
                                        style: AppTypography.labelMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                if (state is MediaError) {
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
                          'Error Loading Media',
                          style: AppTypography.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MediaBloc>().add(const LoadMedia());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          // Mini Player at the bottom
          _buildMiniPlayer(context),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: AppTypography.headlineSmall.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleSmall,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        if (state.currentMedia == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NowPlayingScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Album Art
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: state.currentMedia?.albumArt != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            state.currentMedia!.albumArt!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                          ),
                        )
                      : const Icon(Icons.music_note),
                ),
                const SizedBox(width: 12),
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentMedia!.title,
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        state.currentMedia!.artist,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Controls
                IconButton(
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    context.read<AudioPlayerBloc>().add( TogglePlayPause());
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    color: AppColors.primary,
                  ),
                  onPressed: state.hasNext
                      ? () {
                          context.read<AudioPlayerBloc>().add( NextTrack());
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('MediaPlayer'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               // TODO: Navigate to settings
//             },
//           ),
//         ],
//       ),
//       body: BlocBuilder<MediaBloc, MediaState>(
//         builder: (context, state) {
//           if (state is MediaLoading) {
//             return const LoadingWidget(message: 'Loading media library...');
//           }

//           if (state is MediaLoaded) {
//             return SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Welcome section
//                   Text(
//                     'Welcome to MediaPlayer',
//                     style: AppTypography.headlineMedium,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Your media library at your fingertips',
//                     style: AppTypography.bodyLarge,
//                   ),
//                   const SizedBox(height: 24),
                  
//                   // Stats cards
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildStatCard(
//                           icon: Icons.music_note,
//                           label: 'Songs',
//                           count: state.audioCount,
//                           color: AppColors.primary,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _buildStatCard(
//                           icon: Icons.video_library,
//                           label: 'Videos',
//                           count: state.videoCount,
//                           color: AppColors.secondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
                  
//                   // Quick access section
//                   Text(
//                     'Quick Access',
//                     style: AppTypography.titleLarge,
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildQuickAccessCard(
//                           icon: Icons.music_note,
//                           label: 'Music',
//                           color: AppColors.primary,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => const MusicLibraryScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _buildQuickAccessCard(
//                           icon: Icons.video_library,
//                           label: 'Videos',
//                           color: AppColors.secondary,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => const VideoLibraryScreen(),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildQuickAccessCard(
//                           icon: Icons.playlist_play,
//                           label: 'Playlists',
//                           color: Colors.green,
//                           onTap: () {
//                             // TODO: Navigate to playlists
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: _buildQuickAccessCard(
//                           icon: Icons.favorite,
//                           label: 'Favorites',
//                           color: Colors.red,
//                           onTap: () {
//                             // TODO: Navigate to favorites
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
                  
//                   // Recently played section
//                   if (state.media.isNotEmpty) ...[
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Recently Played',
//                           style: AppTypography.titleLarge,
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             // TODO: Navigate to full history
//                           },
//                           child: const Text('See All'),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       height: 120,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: state.media.take(10).length,
//                         itemBuilder: (context, index) {
//                           final media = state.media[index];
//                           return Container(
//                             width: 100,
//                             margin: const EdgeInsets.only(right: 12),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[200],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   media.isAudio
//                                       ? Icons.music_note
//                                       : Icons.video_library,
//                                   color: media.isAudio
//                                       ? AppColors.primary
//                                       : AppColors.secondary,
//                                   size: 32,
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   media.title,
//                                   style: AppTypography.labelMedium,
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             );
//           }

//           if (state is MediaError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.error_outline,
//                     size: 64,
//                     color: Colors.red[300],
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Error Loading Media',
//                     style: AppTypography.headlineSmall,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     state.message,
//                     style: AppTypography.bodyMedium,
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: () {
//                       context.read<MediaBloc>().add(const LoadMedia());
//                     },
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }

//   Widget _buildStatCard({
//     required IconData icon,
//     required String label,
//     required int count,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 28),
//           const SizedBox(height: 8),
//           Text(
//             count.toString(),
//             style: AppTypography.headlineSmall.copyWith(color: color),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: AppTypography.labelMedium,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickAccessCard({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 2,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   icon,
//                   color: color,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   label,
//                   style: AppTypography.titleSmall,
//                 ),
//               ),
//               const Icon(
//                 Icons.arrow_forward_ios,
//                 size: 16,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }