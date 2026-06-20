import 'package:flutter/material.dart';
import 'package:media/features/mediadetection/presentation/screens/music_library_screen.dart';
import 'package:media/features/mediadetection/presentation/screens/video_library_screen.dart';
import 'route_names.dart';
import '../../features/home/presentation/screens/home_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _buildRoute(const HomeScreen(), settings);
      
      case RouteNames.musicLibrary:
        return _buildRoute(const MusicLibraryScreen(), settings);
      
      case RouteNames.videoLibrary:
        return _buildRoute(const VideoLibraryScreen(), settings);
      
      case RouteNames.nowPlaying:
        // TODO: Return NowPlayingScreen when implemented
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Now Playing - Coming Soon')),
          ),
          settings,
        );
      
      case RouteNames.videoPlayer:
        // TODO: Return VideoPlayerScreen when implemented
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Video Player - Coming Soon')),
          ),
          settings,
        );
      
      case RouteNames.playlists:
        // TODO: Return PlaylistsScreen when implemented
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Playlists - Coming Soon')),
          ),
          settings,
        );
      
      case RouteNames.favorites:
        // TODO: Return FavoritesScreen when implemented
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Favorites - Coming Soon')),
          ),
          settings,
        );
      
      case RouteNames.search:
        // TODO: Return SearchScreen when implemented
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Search - Coming Soon')),
          ),
          settings,
        );
      
      case RouteNames.settings:
        // TODO: Return SettingsScreen when implemented
        return _buildRoute(
          const Scaffold(
            body: Center(child: Text('Settings - Coming Soon')),
          ),
          settings,
        );
      
      default:
        return _buildRoute(
          const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
          settings,
        );
    }
  }
  
  static Route<dynamic> _buildRoute(Widget widget, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => widget,
      settings: settings,
    );
  }
}