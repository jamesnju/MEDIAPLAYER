import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media/core/themes/color_palette.dart';
import 'package:media/core/themes/typography.dart';
import 'package:media/features/mediadetection/domain/entities/media.dart';


class VideoItemWidget extends StatelessWidget {
  final Media media;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const VideoItemWidget({
    super.key,
    required this.media,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildThumbnail(),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      media.formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      media.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: media.isFavorite ? AppColors.secondary : Colors.white,
                      size: 20,
                    ),
                    onPressed: onFavoriteTap,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    media.artist,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (media.albumArt != null) {
      return CachedNetworkImage(
        imageUrl: media.albumArt!,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 120,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.video_library, size: 40),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 120,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.video_library, size: 40),
          ),
        ),
      );
    }

    return Container(
      height: 120,
      color: AppColors.primary.withOpacity(0.1),
      child:  Center(
        child: Icon(
          Icons.video_library,
          size: 40,
          color: AppColors.primary,
        ),
      ),
    );
  }
}