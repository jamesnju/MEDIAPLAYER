import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media/core/themes/color_palette.dart';
import 'package:media/core/themes/typography.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_bloc.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_event.dart';
import 'package:media/features/audioplayer/presentation/screens/now_playing_screen.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';
import 'package:media/features/mediadetection/presentation/bloc/media_bloc.dart';
import 'package:media/features/mediadetection/presentation/bloc/media_state.dart';

class MediaItemWidget extends StatelessWidget {
  final Media media;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool showPlayButton;

  const MediaItemWidget({
    super.key,
    required this.media,
    this.onTap,
    this.onFavoriteTap,
    this.showPlayButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildAlbumArt(),
        title: Text(
          media.title,
          style: AppTypography.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              media.artist,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              media.formattedDuration,
              style: AppTypography.labelMedium,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPlayButton)
              IconButton(
                icon:  Icon(
                  Icons.play_arrow,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  _playMedia(context);
                },
              ),
            IconButton(
              icon: Icon(
                media.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: media.isFavorite ? AppColors.secondary : null,
              ),
              onPressed: onFavoriteTap,
            ),
          ],
        ),
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            _playMedia(context);
          }
        },
      ),
    );
  }

  void _playMedia(BuildContext context) {
    // Get the current media list from the MediaBloc
    final mediaBloc = context.read<MediaBloc>();
    final state = mediaBloc.state;
    
    if (state is MediaLoaded) {
      // Play the selected media with the current list as queue
      context.read<AudioPlayerBloc>().add(
        PlayMedia(media, queue: state.media),
      );
      
      // Navigate to now playing screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NowPlayingScreen(),
        ),
      );
    } else {
      // Play just the single media
      context.read<AudioPlayerBloc>().add(
        PlayMedia(media),
      );
      
      // Navigate to now playing screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NowPlayingScreen(),
        ),
      );
    }
  }

  Widget _buildAlbumArt() {
    if (media.albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: media.albumArt!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: const Icon(Icons.music_note),
          ),
          errorWidget: (context, url, error) => Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: const Icon(Icons.music_note),
          ),
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.primary,
      ),
    );
  }
}