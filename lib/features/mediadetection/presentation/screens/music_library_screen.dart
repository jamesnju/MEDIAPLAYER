// lib/features/mediadetection/presentation/screens/music_library_screen.dart
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

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  String _searchQuery = '';
  SortOption _sortOption = SortOption.title;
  FilterOption _filterOption = FilterOption.all;
  final List<String> _selectedIds = [];
  bool _isSelectionMode = false;
  bool _showFilteredOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
            if (_selectedIds.isNotEmpty) {
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
            }
          }
        },
        builder: (context, state) {
          if (state is MediaLoading) {
            return const LoadingWidget();
          }

          if (state is MediaLoaded) {
            var audioFiles = state.media
                .where((m) => m.isAudio && (_showFilteredOut || !m.isFilteredOut))
                .toList();
            
            if (_searchQuery.isNotEmpty) {
              audioFiles = audioFiles.where((m) =>
                m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                m.artist.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (m.album.toLowerCase().contains(_searchQuery.toLowerCase()))
              ).toList();
            }
            
            audioFiles = _applyFilter(audioFiles);
            audioFiles = _applySort(audioFiles);
            
            if (audioFiles.isEmpty) {
              return _buildEmptyState(context, state);
            }

            return Column(
              children: [
                _buildFilterBar(context, state),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: audioFiles.length,
                    itemBuilder: (context, index) {
                      final media = audioFiles[index];
                      return MediaItemWidget(
                        media: media,
                        isSelected: _selectedIds.contains(media.id),
                        isSelectionMode: _isSelectionMode,
                        onTap: _isSelectionMode
                            ? () => _toggleSelection(media.id)
                            : () => _playMedia(context, media, audioFiles),
                        onFavoriteTap: () {
                          context.read<MediaBloc>().add(ToggleFavorite(media.id));
                        },
                        onLongPress: () => _toggleSelection(media.id),
                        showDuration: true,
                      );
                    },
                  ),
                ),
                if (_isSelectionMode) _buildSelectionActions(context),
              ],
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

  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _selectedIds.clear();
              _isSelectionMode = false;
            });
          },
        ),
        title: Text('${_selectedIds.length} selected'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _selectedIds.isNotEmpty
                ? () => _showFilterOutConfirmation(context)
                : null,
            tooltip: 'Filter out selected',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () => _showUnfilterAllConfirmation(context),
            tooltip: 'Restore all filtered music',
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: _selectedIds.isNotEmpty
                ? () => _addSelectedToFavorites(context)
                : null,
          ),
        ],
      );
    }

    return AppBar(
      title: _searchQuery.isEmpty
          ? const Text('Music Library')
          : TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search music...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
      actions: [
        IconButton(
          icon: Icon(
            _showFilteredOut ? Icons.visibility : Icons.visibility_off,
            color: _showFilteredOut ? AppColors.primary : null,
          ),
          onPressed: () {
            setState(() {
              _showFilteredOut = !_showFilteredOut;
            });
          },
          tooltip: _showFilteredOut ? 'Hide filtered' : 'Show filtered',
        ),
        if (_searchQuery.isEmpty) ...[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchQuery = ' ';
              });
            },
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
        ],
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<MediaBloc>().add( RescanMedia());
          },
        ),
        PopupMenuButton<SortOption>(
          icon: const Icon(Icons.sort),
          onSelected: (value) {
            setState(() {
              _sortOption = value;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: SortOption.title,
              child: Text('Sort by Title (A-Z)'),
            ),
            const PopupMenuItem(
              value: SortOption.titleDesc,
              child: Text('Sort by Title (Z-A)'),
            ),
            const PopupMenuItem(
              value: SortOption.artist,
              child: Text('Sort by Artist'),
            ),
            const PopupMenuItem(
              value: SortOption.duration,
              child: Text('Sort by Duration'),
            ),
            const PopupMenuItem(
              value: SortOption.dateModified,
              child: Text('Sort by Date Modified'),
            ),
            const PopupMenuItem(
              value: SortOption.dateAdded,
              child: Text('Sort by Date Added'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, MediaLoaded state) {
    final filteredCount = state.media.where((m) => m.isAudio && m.isFilteredOut).length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Filter: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FilterOption.values.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(option.label),
                      selected: _filterOption == option,
                      onSelected: (_) {
                        setState(() {
                          _filterOption = option;
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.3),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (filteredCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$filteredCount filtered',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.select_all,
            label: 'Select All',
            onPressed: () => _selectAll(context),
          ),
          _buildActionButton(
            icon: Icons.filter_alt,
            label: 'Filter Out',
            onPressed: _selectedIds.isNotEmpty
                ? () => _showFilterOutConfirmation(context)
                : null,
          ),
          _buildActionButton(
            icon: Icons.favorite,
            label: 'Favorite',
            onPressed: _selectedIds.isNotEmpty
                ? () => _addSelectedToFavorites(context)
                : null,
          ),
          _buildActionButton(
            icon: Icons.clear,
            label: 'Clear',
            onPressed: () {
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: onPressed != null ? null : Colors.grey,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: onPressed != null ? null : Colors.grey,
          ),
        ),
      ],
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _isSelectionMode = _selectedIds.isNotEmpty;
    });
  }

  void _selectAll(BuildContext context) {
    final state = context.read<MediaBloc>().state;
    if (state is MediaLoaded) {
      final audioFiles = state.media
          .where((m) => m.isAudio && (_showFilteredOut || !m.isFilteredOut))
          .toList();
      setState(() {
        _selectedIds.clear();
        _selectedIds.addAll(audioFiles.map((m) => m.id));
        _isSelectionMode = true;
      });
    }
  }

  void _showFilterOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Out Music'),
        content: Text(
          'Are you sure you want to filter out ${_selectedIds.length} selected music file(s)?\n\nThey will be hidden from your library but not deleted. You can restore them anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _filterOutSelected(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Filter Out'),
          ),
        ],
      ),
    );
  }

  void _filterOutSelected(BuildContext context) {
    final state = context.read<MediaBloc>().state;
    if (state is MediaLoaded) {
      final selectedMedia = state.media
          .where((m) => _selectedIds.contains(m.id))
          .toList();
      
      for (final media in selectedMedia) {
        context.read<MediaBloc>().add(ToggleFilterOut(media.id));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtered out ${selectedMedia.length} music file(s)'),
          backgroundColor: Colors.orange,
        ),
      );
      
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _showUnfilterAllConfirmation(BuildContext context) {
    final state = context.read<MediaBloc>().state;
    if (state is MediaLoaded) {
      final filteredCount = state.media.where((m) => m.isAudio && m.isFilteredOut).length;
      
      if (filteredCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No filtered music to restore'),
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore All Music'),
          content: Text(
            'Are you sure you want to restore all $filteredCount filtered music file(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _unfilterAll(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Restore All'),
            ),
          ],
        ),
      );
    }
  }

  void _unfilterAll(BuildContext context) {
    final state = context.read<MediaBloc>().state;
    if (state is MediaLoaded) {
      final filteredMedia = state.media.where((m) => m.isAudio && m.isFilteredOut).toList();
      
      for (final media in filteredMedia) {
        context.read<MediaBloc>().add(ToggleFilterOut(media.id));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored ${filteredMedia.length} music file(s)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addSelectedToFavorites(BuildContext context) {
    final state = context.read<MediaBloc>().state;
    if (state is MediaLoaded) {
      final selectedMedia = state.media
          .where((m) => _selectedIds.contains(m.id))
          .toList();
      
      for (final media in selectedMedia) {
        if (!media.isFavorite) {
          context.read<MediaBloc>().add(ToggleFavorite(media.id));
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${selectedMedia.length} to favorites'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  List<Media> _applyFilter(List<Media> media) {
    switch (_filterOption) {
      case FilterOption.all:
        return media;
      case FilterOption.favorites:
        return media.where((m) => m.isFavorite).toList();
      case FilterOption.recent:
        final sorted = List<Media>.from(media)
          ..sort((a, b) => (b.lastPlayed).compareTo(a.lastPlayed));
        return sorted.take(20).toList();
      case FilterOption.artists:
        final artists = <String, Media>{};
        for (final m in media) {
          if (!artists.containsKey(m.artist)) {
            artists[m.artist] = m;
          }
        }
        return artists.values.toList();
      case FilterOption.albums:
        final albums = <String, Media>{};
        for (final m in media) {
          if (!albums.containsKey(m.album)) {
            albums[m.album] = m;
          }
        }
        return albums.values.toList();
    }
  }

  List<Media> _applySort(List<Media> media) {
    final sorted = List<Media>.from(media);
    switch (_sortOption) {
      case SortOption.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.titleDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOption.artist:
        sorted.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SortOption.duration:
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case SortOption.dateModified:
        sorted.sort((a, b) => (b.dateModified).compareTo(a.dateModified));
        break;
      case SortOption.dateAdded:
        sorted.sort((a, b) => (b.dateAdded).compareTo(a.dateAdded));
        break;
    }
    return sorted;
  }

  void _playMedia(BuildContext context, Media media, List<Media> queue) {
    try {
      final audioBloc = context.read<AudioPlayerBloc>();
      audioBloc.add(PlayMedia(media, queue: queue));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading...'),
          duration: Duration(seconds: 1),
        ),
      );
      
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

  Widget _buildEmptyState(BuildContext context, MediaLoaded state) {
    final filteredCount = state.media.where((m) => m.isAudio && m.isFilteredOut).length;
    
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
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : _showFilteredOut && filteredCount > 0
                    ? 'Showing filtered music'
                    : 'No Music Found',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : _showFilteredOut && filteredCount > 0
                    ? 'These music files are currently filtered out'
                    : 'Tap the refresh button to scan for music files',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (_showFilteredOut && filteredCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$filteredCount music file(s) filtered out',
              style: AppTypography.labelMedium,
            ),
          ],
          const SizedBox(height: 24),
          if (filteredCount > 0 && !_showFilteredOut)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showFilteredOut = true;
                });
              },
              icon: const Icon(Icons.visibility),
              label: Text('Show $filteredCount filtered music'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          if (_searchQuery.isEmpty)
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
          if (_searchQuery.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
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

enum SortOption {
  title,
  titleDesc,
  artist,
  duration,
  dateModified,
  dateAdded,
}

enum FilterOption {
  all,
  favorites,
  recent,
  artists,
  albums,
}

extension FilterOptionLabel on FilterOption {
  String get label {
    switch (this) {
      case FilterOption.all:
        return 'All';
      case FilterOption.favorites:
        return '⭐ Favorites';
      case FilterOption.recent:
        return '🕐 Recent';
      case FilterOption.artists:
        return '🎤 Artists';
      case FilterOption.albums:
        return '💿 Albums';
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:media/features/audioplayer/presentation/bloc/audio_player_bloc.dart';
// import 'package:media/features/audioplayer/presentation/bloc/audio_player_event.dart';
// import 'package:media/features/audioplayer/presentation/screens/now_playing_screen.dart';
// import 'package:media/features/mediadetection/domain/entities/media.dart';
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
//                     // FIXED: Play the media when tapped
//                     _playMedia(context, media, audioFiles);
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
// // In music_library_screen.dart
// void _playMedia(BuildContext context, Media media, List<Media> queue) {
//   try {
//     final audioBloc = context.read<AudioPlayerBloc>();
//     audioBloc.add(PlayMedia(media, queue: queue));
    
//     // Show a loading indicator
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Loading...'),
//         duration: Duration(seconds: 1),
//       ),
//     );
    
//     // Navigate to Now Playing screen
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const NowPlayingScreen(),
//       ),
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Error: ${e.toString()}'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }
 

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
