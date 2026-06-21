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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background950 : AppColors.background50,
      body: BlocBuilder<MediaBloc, MediaState>(
        builder: (context, state) {
          if (state is MediaLoading) {
            return const LoadingWidget(message: 'Loading media library...');
          }

          if (state is MediaLoaded) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Stack(
                  children: [
                    // Animated Background
                    _buildAnimatedBackground(isDark),
                    
                    // Main Content
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          expandedHeight: isMobile ? 180 : 220,
                          floating: true,
                          pinned: true,
                          stretch: true,
                          backgroundColor: Colors.transparent,
                          flexibleSpace: FlexibleSpaceBar(
                            title: _buildAppBarTitle(isDark, isMobile),
                            centerTitle: false,
                            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                            background: _buildAppBarBackground(isDark, isMobile),
                          ),
                          actions: [
                            _buildActionButton(
                              icon: isDark ? Icons.light_mode : Icons.dark_mode,
                              onTap: () {
                                // Toggle theme logic
                              },
                              isDark: isDark,
                            ),
                            _buildActionButton(
                              icon: Icons.search_rounded,
                              onTap: () {
                                // TODO: Navigate to search
                              },
                              isDark: isDark,
                            ),
                            _buildActionButton(
                              icon: Icons.settings_rounded,
                              onTap: () {
                                // TODO: Navigate to settings
                              },
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: 8,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Stats Section
                              _buildStatsSection(state, isDark, isMobile, isTablet),
                              const SizedBox(height: 24),
                              
                              // Quick Access Section
                              _buildQuickAccessSection(isDark, isMobile, isTablet),
                              const SizedBox(height: 24),
                              
                              // Recently Played Section
                              if (state.media.isNotEmpty)
                                _buildRecentlyPlayedSection(state, isDark, isMobile),
                              const SizedBox(height: 20),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    
                    // Mini Player
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildMiniPlayer(context),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MediaError) {
            return _buildErrorWidget(state, isDark);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.background950,
                  AppColors.background900,
                  AppColors.background800,
                ]
              : [
                  AppColors.background50,
                  AppColors.background100,
                  AppColors.background200.withOpacity(0.3),
                ],
        ),
      ),
    );
  }

  Widget _buildAppBarBackground(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary800.withOpacity(0.3),
                  AppColors.secondary800.withOpacity(0.2),
                  AppColors.background900,
                ]
              : [
                  AppColors.primary100.withOpacity(0.3),
                  AppColors.secondary100.withOpacity(0.2),
                  AppColors.background50,
                ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary500.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary500.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(bool isDark, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: isDark ? AppColors.text950 : AppColors.text50,
            size: isMobile ? 20 : 24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'MediaPlayer',
          style: AppTypography.headlineMedium.copyWith(
            color: isDark ? AppColors.text50 : AppColors.text900,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary500.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Pro',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary500,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.background800 : AppColors.background50).withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? AppColors.text100 : AppColors.text700,
          size: 22,
        ),
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildStatsSection(MediaLoaded state, bool isDark, bool isMobile, bool isTablet) {
    final stats = [
      _StatItem(
        icon: Icons.music_note_rounded,
        label: 'Songs',
        value: state.audioCount,
        color: AppColors.primary500,
        gradient: AppColors.primaryGradient,
      ),
      _StatItem(
        icon: Icons.video_library_rounded,
        label: 'Videos',
        value: state.videoCount,
        color: AppColors.secondary500,
        gradient: AppColors.secondaryGradient,
      ),
      _StatItem(
        icon: Icons.folder_rounded,
        label: 'Albums',
        value: state.media.where((m) => m.album != null).map((m) => m.album).toSet().length,
        color: AppColors.accent500,
        gradient: AppColors.accentGradient,
      ),
      _StatItem(
        icon: Icons.access_time_rounded,
        label: 'Played Today',
        value: state.media.where((m) => m.lastPlayed != null).length,
        color: Colors.orange,
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.orangeAccent],
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Overview',
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.text50 : AppColors.text900,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 18 : 22,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: isMobile ? 8 : 12,
          runSpacing: isMobile ? 8 : 12,
          children: stats.map((stat) => 
            _buildStatCard(stat, isDark, isMobile, isTablet)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatItem stat, bool isDark, bool isMobile, bool isTablet) {
    final width = isTablet 
      ? (MediaQuery.of(context).size.width - 60) / 4 
      : isMobile 
        ? (MediaQuery.of(context).size.width - 48) / 2 
        : 120.0;

    return Container(
      width: width,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  stat.color.withOpacity(0.12),
                  stat.color.withOpacity(0.04),
                ]
              : [
                  stat.color.withOpacity(0.08),
                  stat.color.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stat.color.withOpacity(isDark ? 0.2 : 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: stat.gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: stat.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              stat.icon,
              color: isDark ? AppColors.text950 : AppColors.text50,
              size: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stat.value.toString(),
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.text50 : AppColors.text900,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.text300 : AppColors.text600,
              fontSize: isMobile ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(bool isDark, bool isMobile, bool isTablet) {
    final items = [
      _QuickAccessItem(
        icon: Icons.music_note_rounded,
        label: 'Music',
        color: AppColors.primary500,
        gradient: AppColors.primaryGradient,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MusicLibraryScreen()),
        ),
      ),
      _QuickAccessItem(
        icon: Icons.video_library_rounded,
        label: 'Videos',
        color: AppColors.secondary500,
        gradient: AppColors.secondaryGradient,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VideoLibraryScreen()),
        ),
      ),
      _QuickAccessItem(
        icon: Icons.playlist_play_rounded,
        label: 'Playlists',
        color: AppColors.accent500,
        gradient: AppColors.accentGradient,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlists coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      _QuickAccessItem(
        icon: Icons.favorite_rounded,
        label: 'Favorites',
        color: Colors.red,
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.redAccent],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favorites coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Access',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.text50 : AppColors.text900,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 22,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                ),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: isMobile ? 8 : 12,
          runSpacing: isMobile ? 8 : 12,
          children: items.map((item) => 
            _buildQuickAccessCard(item, isDark, isMobile, isTablet)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(_QuickAccessItem item, bool isDark, bool isMobile, bool isTablet) {
    final width = isTablet 
        ? (MediaQuery.of(context).size.width - 60) / 4 
        : isMobile 
            ? (MediaQuery.of(context).size.width - 48) / 2 
            : 140.0;

    return Container(
      width: width,
      height: isMobile ? 80 : 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  item.color.withOpacity(0.12),
                  item.color.withOpacity(0.04),
                ]
              : [
                  item.color.withOpacity(0.08),
                  Colors.transparent,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.color.withOpacity(isDark ? 0.2 : 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: item.color.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: item.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color: isDark ? AppColors.text950 : AppColors.text50,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark ? AppColors.text50 : AppColors.text800,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 13 : 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse all',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.text300 : AppColors.text600,
                          fontSize: isMobile ? 10 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.text300 : AppColors.text600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayedSection(MediaLoaded state, bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Played',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.text50 : AppColors.text900,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 22,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('History coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                ),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isMobile ? 130 : 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: state.media.take(10).length,
            itemBuilder: (context, index) {
              final media = state.media[index];
              final isAudio = media.isAudio;
              final color = isAudio ? AppColors.primary500 : AppColors.secondary500;
              final gradient = isAudio ? AppColors.primaryGradient : AppColors.secondaryGradient;

              return Container(
                width: isMobile ? 100 : 120,
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  color.withOpacity(0.12),
                                  color.withOpacity(0.04),
                                ]
                              : [
                                  color.withOpacity(0.08),
                                  Colors.transparent,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withOpacity(isDark ? 0.2 : 0.1),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Now playing: ${media.title}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: gradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isAudio 
                                        ? Icons.music_note_rounded 
                                        : Icons.play_arrow_rounded,
                                    color: isDark ? AppColors.text950 : AppColors.text50,
                                    size: isMobile ? 20 : 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  media.title,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark ? AppColors.text100 : AppColors.text800,
                                    fontWeight: FontWeight.w500,
                                    fontSize: isMobile ? 10 : 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Positioned badge for audio/video type
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.background900 : AppColors.background50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          isAudio ? '🎵' : '🎬',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(MediaError state, bool isDark) {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.background900 : AppColors.background50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark ? AppColors.text50 : AppColors.text900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.text300 : AppColors.text600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<MediaBloc>().add(const LoadMedia());
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isPlaying = state.isPlaying;

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 100),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.background800,
                        AppColors.background900,
                      ]
                    : [
                        AppColors.background50,
                        AppColors.background100,
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.background800 : AppColors.text200).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border.all(
                color: (isDark ? AppColors.primary800 : AppColors.primary200).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NowPlayingScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Album Art
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: isPlaying
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary500,
                                      AppColors.secondary500,
                                    ],
                                  )
                                : null,
                            boxShadow: [
                              if (isPlaying)
                                BoxShadow(
                                  color: AppColors.primary500.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isDark ? AppColors.background800 : AppColors.background50,
                            ),
                            child: state.currentMedia?.albumArt != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      state.currentMedia!.albumArt!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildDefaultAlbumArt(isDark),
                                    ),
                                  )
                                : _buildDefaultAlbumArt(isDark),
                          ),
                        ),
                        if (isPlaying)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.volume_up_rounded,
                                size: 10,
                                color: isDark ? AppColors.text950 : AppColors.text50,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    
                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.currentMedia!.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark ? AppColors.text50 : AppColors.text900,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            state.currentMedia!.artist,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.text300 : AppColors.text600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Controls
                    Row(
                      children: [
                        IconButton(
                          iconSize: 22,
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: state.hasPrevious 
                                ? (isDark ? AppColors.text100 : AppColors.text700)
                                : (isDark ? AppColors.text600 : AppColors.text300),
                          ),
                          onPressed: state.hasPrevious
                              ? () {
                                  context.read<AudioPlayerBloc>().add( PreviousTrack());
                                }
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary500.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: isDark ? AppColors.text950 : AppColors.text50,
                              size: 26,
                            ),
                            onPressed: () {
                              context.read<AudioPlayerBloc>().add( TogglePlayPause());
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                        IconButton(
                          iconSize: 22,
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: state.hasNext 
                                ? (isDark ? AppColors.text100 : AppColors.text700)
                                : (isDark ? AppColors.text600 : AppColors.text300),
                          ),
                          onPressed: state.hasNext
                              ? () {
                                  context.read<AudioPlayerBloc>().add( NextTrack());
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAlbumArt(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            AppColors.primary500.withOpacity(0.2),
            AppColors.secondary500.withOpacity(0.2),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: isDark ? AppColors.text300 : AppColors.text600,
        size: 28,
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final LinearGradient gradient;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });
}

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final Color color;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.onTap,
  });
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:media/features/audioplayer/presentation/bloc/audio_player_bloc.dart';
// import 'package:media/features/audioplayer/presentation/bloc/audio_player_event.dart';
// import 'package:media/features/audioplayer/presentation/bloc/audio_player_state.dart';
// import 'package:media/features/audioplayer/presentation/screens/now_playing_screen.dart';
// import 'package:media/features/mediadetection/presentation/bloc/media_bloc.dart';
// import 'package:media/features/mediadetection/presentation/bloc/media_event.dart';
// import 'package:media/features/mediadetection/presentation/bloc/media_state.dart';
// import 'package:media/features/mediadetection/presentation/screens/music_library_screen.dart';
// import 'package:media/features/mediadetection/presentation/screens/video_library_screen.dart';
// import 'package:media/features/mediadetection/presentation/widgets/loading/loading_widget.dart';
// import '../../../../core/themes/color_palette.dart';
// import '../../../../core/themes/typography.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   int _selectedIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isMobile = screenWidth < 600;
//     final isTablet = screenWidth >= 600 && screenWidth < 1200;
//     final isDesktop = screenWidth >= 1200;

//     return Scaffold(
//       appBar: _buildAppBar(isDark, isMobile),
//       body: BlocBuilder<MediaBloc, MediaState>(
//         builder: (context, state) {
//           if (state is MediaLoading) {
//             return const LoadingWidget(message: 'Loading media library...');
//           }

//           if (state is MediaLoaded) {
//             return FadeTransition(
//               opacity: _fadeAnimation,
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   return Stack(
//                     children: [
//                       // Background gradient
//                       Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: isDark
//                                 ? [
//                                     AppColors.background950,
//                                     AppColors.background900,
//                                   ]
//                                 : [
//                                     AppColors.background50,
//                                     AppColors.background100,
//                                   ],
//                           ),
//                         ),
//                       ),
//                       SingleChildScrollView(
//                         padding: EdgeInsets.all(isMobile ? 16 : 24),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildWelcomeSection(isDark, isMobile),
//                             const SizedBox(height: 24),
//                             _buildStatsSection(state, isDark, isMobile, isTablet, isDesktop),
//                             const SizedBox(height: 24),
//                             _buildQuickAccessSection(isDark, isMobile, isTablet),
//                             const SizedBox(height: 24),
//                             if (state.media.isNotEmpty)
//                               _buildRecentlyPlayedSection(state, isDark, isMobile),
//                             const SizedBox(height: 80), // Space for mini player
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             );
//           }

//           if (state is MediaError) {
//             return _buildErrorWidget(state, isDark);
//           }

//           return const SizedBox.shrink();
//         },
//       ),
//       bottomSheet: _buildMiniPlayer(context),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(bool isDark, bool isMobile) {
//     return AppBar(
//       elevation: 0,
//       backgroundColor: Colors.transparent,
//       centerTitle: false,
//       title: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               gradient: AppColors.primaryGradient,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.primary500.withOpacity(0.3),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Icon(
//               Icons.play_arrow,
//               color: isDark ? AppColors.text950 : AppColors.text50,
//               size: isMobile ? 24 : 28,
//             ),
//           ),
//           const SizedBox(width: 12),
//           ShaderMask(
//             shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
//             child: Text(
//               'MediaPlayer',
//               style: AppTypography.headlineMedium.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: isMobile ? 20 : 24,
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           onPressed: () {
//             // Toggle theme
//             final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//             // Add your theme toggle logic here
//           },
//           icon: Icon(
//             isDark ? Icons.light_mode : Icons.dark_mode,
//             color: isDark ? AppColors.text100 : AppColors.text800,
//           ),
//           tooltip: 'Toggle Theme',
//         ),
//         IconButton(
//           icon: Icon(
//             Icons.search_rounded,
//             color: isDark ? AppColors.text100 : AppColors.text800,
//           ),
//           onPressed: () {
//             // TODO: Navigate to search
//           },
//           tooltip: 'Search',
//         ),
//         IconButton(
//           icon: Icon(
//             Icons.settings_rounded,
//             color: isDark ? AppColors.text100 : AppColors.text800,
//           ),
//           onPressed: () {
//             // TODO: Navigate to settings
//           },
//           tooltip: 'Settings',
//         ),
//       ],
//     );
//   }

//   Widget _buildWelcomeSection(bool isDark, bool isMobile) {
//     return Container(
//       padding: EdgeInsets.all(isMobile ? 20 : 24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColors.primary500.withOpacity(0.15),
//             AppColors.secondary500.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isDark ? AppColors.primary700.withOpacity(0.3) : AppColors.primary200.withOpacity(0.5),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '🎵 Welcome Back!',
//                       style: AppTypography.headlineMedium.copyWith(
//                         fontWeight: FontWeight.bold,
//                         fontSize: isMobile ? 20 : 28,
//                         color: isDark ? AppColors.text50 : AppColors.text900,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Your media library at your fingertips',
//                       style: AppTypography.bodyLarge.copyWith(
//                         color: isDark ? AppColors.text200 : AppColors.text700,
//                         fontSize: isMobile ? 14 : 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               if (!isMobile)
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary500.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     Icons.headphones_rounded,
//                     color: AppColors.primary500,
//                     size: 40,
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: isDark ? AppColors.primary800.withOpacity(0.3) : AppColors.primary100.withOpacity(0.5),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.info_outline,
//                   size: 16,
//                   color: isDark ? AppColors.primary300 : AppColors.primary700,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   '${DateTime.now().hour < 12 ? 'Good Morning' : 'Good Afternoon'} ☀️',
//                   style: AppTypography.bodySmall.copyWith(
//                     color: isDark ? AppColors.primary300 : AppColors.primary700,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsSection(MediaLoaded state, bool isDark, bool isMobile, bool isTablet, bool isDesktop) {
//     final crossAxisCount = isDesktop ? 4 : isTablet ? 3 : 2;
//     final spacing = isMobile ? 8.0 : 12.0;

//     return GridView.count(
//       crossAxisCount: crossAxisCount,
//       crossAxisSpacing: spacing,
//       mainAxisSpacing: spacing,
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       children: [
//         _buildStatCard(
//           icon: Icons.music_note_rounded,
//           label: 'Songs',
//           count: state.audioCount,
//           color: AppColors.primary500,
//           gradient: AppColors.primaryGradient,
//           isDark: isDark,
//         ),
//         _buildStatCard(
//           icon: Icons.video_library_rounded,
//           label: 'Videos',
//           count: state.videoCount,
//           color: AppColors.secondary500,
//           gradient: AppColors.secondaryGradient,
//           isDark: isDark,
//         ),
//         _buildStatCard(
//           icon: Icons.folder_rounded,
//           label: 'Albums',
//           count: state.media.where((m) => m.album != null).map((m) => m.album).toSet().length,
//           color: AppColors.accent500,
//           gradient: AppColors.accentGradient,
//           isDark: isDark,
//         ),
//         _buildStatCard(
//           icon: Icons.access_time_rounded,
//           label: 'Played Today',
//           count: state.media.where((m) => m.lastPlayed != null).length,
//           color: Colors.orange,
//           gradient: const LinearGradient(
//             colors: [Colors.orange, Colors.orangeAccent],
//           ),
//           isDark: isDark,
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard({
//     required IconData icon,
//     required String label,
//     required int count,
//     required Color color,
//     required LinearGradient gradient,
//     required bool isDark,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: isDark
//               ? [
//                   color.withOpacity(0.15),
//                   color.withOpacity(0.05),
//                 ]
//               : [
//                   color.withOpacity(0.08),
//                   color.withOpacity(0.02),
//                 ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: color.withOpacity(isDark ? 0.2 : 0.15),
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               gradient: gradient,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: color.withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Icon(
//               icon,
//               color: isDark ? AppColors.text950 : AppColors.text50,
//               size: 24,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             count.toString(),
//             style: AppTypography.headlineMedium.copyWith(
//               color: isDark ? AppColors.text50 : AppColors.text900,
//               fontWeight: FontWeight.bold,
//               fontSize: 24,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: AppTypography.labelMedium.copyWith(
//               color: isDark ? AppColors.text300 : AppColors.text600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickAccessSection(bool isDark, bool isMobile, bool isTablet) {
//     final items = [
//       _QuickAccessItem(
//         icon: Icons.music_note_rounded,
//         label: 'Music',
//         color: AppColors.primary500,
//         gradient: AppColors.primaryGradient,
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const MusicLibraryScreen()),
//         ),
//       ),
//       _QuickAccessItem(
//         icon: Icons.video_library_rounded,
//         label: 'Videos',
//         color: AppColors.secondary500,
//         gradient: AppColors.secondaryGradient,
//         onTap: () => Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const VideoLibraryScreen()),
//         ),
//       ),
//       _QuickAccessItem(
//         icon: Icons.playlist_play_rounded,
//         label: 'Playlists',
//         color: AppColors.accent500,
//         gradient: AppColors.accentGradient,
//         onTap: () {
//           // TODO: Navigate to playlists
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Playlists coming soon!')),
//           );
//         },
//       ),
//       _QuickAccessItem(
//         icon: Icons.favorite_rounded,
//         label: 'Favorites',
//         color: Colors.red,
//         gradient: const LinearGradient(
//           colors: [Colors.red, Colors.redAccent],
//         ),
//         onTap: () {
//           // TODO: Navigate to favorites
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Favorites coming soon!')),
//           );
//         },
//       ),
//     ];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Quick Access',
//               style: AppTypography.titleLarge.copyWith(
//                 color: isDark ? AppColors.text50 : AppColors.text900,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 // TODO: Show all quick access items
//               },
//               child: Text(
//                 'See All',
//                 style: AppTypography.labelMedium.copyWith(
//                   color: AppColors.primary500,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         LayoutBuilder(
//           builder: (context, constraints) {
//             final crossAxisCount = isTablet ? 4 : 2;
//             final spacing = isMobile ? 8.0 : 12.0;
            
//             return GridView.count(
//               crossAxisCount: crossAxisCount,
//               crossAxisSpacing: spacing,
//               mainAxisSpacing: spacing,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               childAspectRatio: isMobile ? 1.2 : 1.5,
//               children: items.map((item) => _buildQuickAccessCard(item, isDark)).toList(),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildQuickAccessCard(_QuickAccessItem item, bool isDark) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: InkWell(
//         onTap: item.onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: isDark
//                   ? [
//                       item.color.withOpacity(0.15),
//                       item.color.withOpacity(0.05),
//                     ]
//                   : [
//                       item.color.withOpacity(0.08),
//                       Colors.transparent,
//                     ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: item.color.withOpacity(isDark ? 0.2 : 0.1),
//               width: 1,
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   gradient: item.gradient,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: [
//                     BoxShadow(
//                       color: item.color.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   item.icon,
//                   color: isDark ? AppColors.text950 : AppColors.text50,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 item.label,
//                 style: AppTypography.titleSmall.copyWith(
//                   color: isDark ? AppColors.text100 : AppColors.text800,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentlyPlayedSection(MediaLoaded state, bool isDark, bool isMobile) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Recently Played',
//               style: AppTypography.titleLarge.copyWith(
//                 color: isDark ? AppColors.text50 : AppColors.text900,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 // TODO: Navigate to full history
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('History coming soon!')),
//                 );
//               },
//               child: Text(
//                 'See All',
//                 style: AppTypography.labelMedium.copyWith(
//                   color: AppColors.primary500,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 140,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: state.media.take(10).length,
//             itemBuilder: (context, index) {
//               final media = state.media[index];
//               final isAudio = media.isAudio;
//               final color = isAudio ? AppColors.primary500 : AppColors.secondary500;
//               final gradient = isAudio ? AppColors.primaryGradient : AppColors.secondaryGradient;

//               return Container(
//                 width: 120,
//                 margin: const EdgeInsets.only(right: 12),
//                 child: Card(
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: InkWell(
//                     onTap: () {
//                       // TODO: Play this media
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Now playing: ${media.title}')),
//                       );
//                     },
//                     borderRadius: BorderRadius.circular(12),
//                     child: Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: isDark
//                               ? [
//                                   color.withOpacity(0.15),
//                                   color.withOpacity(0.05),
//                                 ]
//                               : [
//                                   color.withOpacity(0.08),
//                                   Colors.transparent,
//                                 ],
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: color.withOpacity(isDark ? 0.2 : 0.1),
//                           width: 1,
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               gradient: gradient,
//                               borderRadius: BorderRadius.circular(10),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: color.withOpacity(0.3),
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ],
//                             ),
//                             child: Icon(
//                               isAudio ? Icons.music_note_rounded : Icons.play_arrow_rounded,
//                               color: isDark ? AppColors.text950 : AppColors.text50,
//                               size: 24,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             media.title,
//                             style: AppTypography.labelSmall.copyWith(
//                               color: isDark ? AppColors.text100 : AppColors.text800,
//                               fontWeight: FontWeight.w500,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             textAlign: TextAlign.center,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildErrorWidget(MediaError state, bool isDark) {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.all(32),
//         margin: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: isDark ? AppColors.background900 : AppColors.background50,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: Colors.red.withOpacity(0.2),
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.error_outline_rounded,
//                 size: 64,
//                 color: Colors.red[300],
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Error Loading Media',
//               style: AppTypography.headlineSmall.copyWith(
//                 color: isDark ? AppColors.text50 : AppColors.text900,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               state.message,
//               style: AppTypography.bodyMedium.copyWith(
//                 color: isDark ? AppColors.text300 : AppColors.text600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 context.read<MediaBloc>().add(const LoadMedia());
//               },
//               icon: const Icon(Icons.refresh_rounded),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 16,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMiniPlayer(BuildContext context) {
//     return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
//       builder: (context, state) {
//         if (state.currentMedia == null) {
//           return const SizedBox.shrink();
//         }

//         final isDark = Theme.of(context).brightness == Brightness.dark;
//         final isPlaying = state.isPlaying;

//         return GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => const NowPlayingScreen(),
//               ),
//             );
//           },
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: isDark
//                     ? [
//                         AppColors.background900,
//                         AppColors.background800,
//                       ]
//                     : [
//                         AppColors.background50,
//                         AppColors.background100,
//                       ],
//               ),
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(16),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: (isDark ? AppColors.background800 : AppColors.text200).withOpacity(0.2),
//                   blurRadius: 16,
//                   offset: const Offset(0, -4),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Album Art with animated border
//                 Stack(
//                   children: [
//                     Container(
//                       width: 52,
//                       height: 52,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         gradient: isPlaying
//                             ? LinearGradient(
//                                 colors: [
//                                   AppColors.primary500,
//                                   AppColors.secondary500,
//                                 ],
//                               )
//                             : null,
//                         boxShadow: [
//                           if (isPlaying)
//                             BoxShadow(
//                               color: AppColors.primary500.withOpacity(0.3),
//                               blurRadius: 12,
//                               spreadRadius: 2,
//                             ),
//                         ],
//                       ),
//                       padding: const EdgeInsets.all(2),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(10),
//                           color: isDark ? AppColors.background800 : AppColors.background50,
//                         ),
//                         child: state.currentMedia?.albumArt != null
//                             ? ClipRRect(
//                                 borderRadius: BorderRadius.circular(10),
//                                 child: Image.network(
//                                   state.currentMedia!.albumArt!,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (_, __, ___) => _buildDefaultAlbumArt(isDark),
//                                 ),
//                               )
//                             : _buildDefaultAlbumArt(isDark),
//                       ),
//                     ),
//                     if (isPlaying)
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: Container(
//                           padding: const EdgeInsets.all(3),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary500,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.volume_up_rounded,
//                             size: 12,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(width: 12),
//                 // Song Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         state.currentMedia!.title,
//                         style: AppTypography.titleSmall.copyWith(
//                           color: isDark ? AppColors.text50 : AppColors.text900,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         state.currentMedia!.artist,
//                         style: AppTypography.bodySmall.copyWith(
//                           color: isDark ? AppColors.text300 : AppColors.text600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Controls with animations
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         Icons.skip_previous_rounded,
//                         color: isDark ? AppColors.text100 : AppColors.text700,
//                       ),
//                       onPressed: state.hasPrevious
//                           ? () {
//                               context.read<AudioPlayerBloc>().add( PreviousTrack());
//                             }
//                           : null,
//                     ),
//                     Container(
//                       decoration: BoxDecoration(
//                         gradient: AppColors.primaryGradient,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.primary500.withOpacity(0.3),
//                             blurRadius: 8,
//                           ),
//                         ],
//                       ),
//                       child: IconButton(
//                         icon: Icon(
//                           isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
//                           color: isDark ? AppColors.text950 : AppColors.text50,
//                           size: 28,
//                         ),
//                         onPressed: () {
//                           context.read<AudioPlayerBloc>().add( TogglePlayPause());
//                         },
//                       ),
//                     ),
//                     IconButton(
//                       icon: Icon(
//                         Icons.skip_next_rounded,
//                         color: isDark ? AppColors.text100 : AppColors.text700,
//                       ),
//                       onPressed: state.hasNext
//                           ? () {
//                               context.read<AudioPlayerBloc>().add( NextTrack());
//                             }
//                           : null,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDefaultAlbumArt(bool isDark) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         gradient: LinearGradient(
//           colors: [
//             AppColors.primary500.withOpacity(0.2),
//             AppColors.secondary500.withOpacity(0.2),
//           ],
//         ),
//       ),
//       child: Icon(
//         Icons.music_note_rounded,
//         color: isDark ? AppColors.text300 : AppColors.text600,
//         size: 28,
//       ),
//     );
//   }
// }

// class _QuickAccessItem {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final LinearGradient gradient;
//   final VoidCallback onTap;

//   const _QuickAccessItem({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.gradient,
//     required this.onTap,
//   });
// }
