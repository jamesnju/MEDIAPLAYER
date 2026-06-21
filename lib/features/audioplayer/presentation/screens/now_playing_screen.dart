import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import 'dart:math';
import 'dart:async';
import '../bloc/audio_player_bloc.dart';
import '../bloc/audio_player_event.dart';
import '../bloc/audio_player_state.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../../../core/themes/color_palette.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _visualizerTimer;
  List<double> _amplitudes = List.generate(30, (_) => 0.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Rotation animation controller
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addListener(() {
      if (mounted) setState(() {});
    });
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
    
    // Start audio visualizer timer
    _startVisualizer();
  }

  void _startVisualizer() {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          // Generate random amplitude values that simulate audio waves
          _amplitudes = List.generate(30, (index) {
            // Create wave-like patterns with random variations
            final base = 0.2 + 0.8 * (1 - (index / 30));
            final variation = _random.nextDouble() * 0.8;
            final peak = sin(index * 0.5 + timer.tick * 0.1) * 0.5 + 0.5;
            return (base * variation * peak).clamp(0.0, 1.0);
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    _visualizerTimer?.cancel();
    super.dispose();
  }

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

          // Control rotation based on playing state
          if (state.isPlaying) {
            if (!_rotationController.isAnimating) {
              _rotationController.repeat();
            }
          } else {
            if (_rotationController.isAnimating) {
              _rotationController.stop();
            }
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary800.withOpacity(0.3),
                      AppColors.secondary800.withOpacity(0.2),
                      Colors.black,
                    ],
                  ),
                ),
                child: SafeArea(
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
                                _buildHeader(context, state),
                                Expanded(
                                  flex: isSmallScreen ? 2 : 3,
                                  child: _buildAlbumArt(state, screenSize, isSmallScreen),
                                ),
                                _buildSongInfo(state, isSmallScreen),
                                _buildAudioVisualizer(state, isSmallScreen),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AudioPlayerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            onPressed: () {
              _showOptionsBottomSheet(context, state);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(AudioPlayerState state, Size screenSize, bool isSmallScreen) {
    final double size = screenSize.width * 0.75;
    final double maxSize = screenSize.height * 0.45;
    final double albumSize = size > maxSize ? maxSize : size;
    final isPlaying = state.isPlaying;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.all(screenSize.width * 0.04),
      constraints: BoxConstraints(
        maxWidth: albumSize,
        maxHeight: albumSize,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isPlaying 
                ? AppColors.primary500.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: isPlaying ? 5 : 2,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPlaying
              ? [
                  AppColors.primary400.withOpacity(0.3),
                  AppColors.secondary400.withOpacity(0.3),
                ]
              : [
                  Colors.grey.shade800.withOpacity(0.3),
                  Colors.grey.shade900.withOpacity(0.3),
                ],
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
            // Animated overlay gradient for playing state
            if (isPlaying)
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.transparent,
                      AppColors.primary500.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            // Status indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPlaying ? AppColors.primary500.withOpacity(0.3) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isPlaying ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPlaying ? 'Playing' : 'Paused',
                      style: TextStyle(
                        color: isPlaying ? Colors.green : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withOpacity(0.4),
            AppColors.secondary500.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: RotationTransition(
          turns: _rotationController,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary400.withOpacity(0.6),
                  AppColors.secondary400.withOpacity(0.6),
                  AppColors.accent400.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring animation
                RotationTransition(
                  turns: _rotationController,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Music note icon
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.white70],
                  ).createShader(bounds),
                  child: Icon(
                    Icons.music_note,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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
          // Song Title with gradient and marquee
          SizedBox(
            height: isSmallScreen ? 28.0 : 34.0,
            child: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
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
          ),
          SizedBox(height: isSmallScreen ? 2.0 : 4.0),
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.currentMedia!.artist,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: artistFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer(AudioPlayerState state, bool isSmallScreen) {
    if (!state.isPlaying) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
        child: Text(
          'Tap play to see the music come alive 🎵',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: isSmallScreen ? 11 : 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 8 : 12,
      ),
      child: Column(
        children: [
          // Animated bar visualizer
          AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            height: isSmallScreen ? 40 : 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                30,
                (index) => _buildVisualizerBar(index, isSmallScreen),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Frequency labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bass',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 8 : 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Mid',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 8 : 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Treble',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 8 : 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerBar(int index, bool isSmallScreen) {
    final amplitude = _amplitudes[index];
    final height = 10 + (amplitude * (isSmallScreen ? 30 : 40));
    final colorIndex = (index / _amplitudes.length) * 2.0;
    final isEven = index % 2 == 0;
    
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isEven ? Alignment.bottomCenter : Alignment.topCenter,
              end: isEven ? Alignment.topCenter : Alignment.bottomCenter,
              colors: _getGradientColors(amplitude, colorIndex),
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withOpacity(amplitude * 0.3),
                blurRadius: 4,
                spreadRadius: amplitude * 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(double amplitude, double index) {
    final primaryColor = AppColors.primary500;
    final secondaryColor = AppColors.secondary500;
    final accentColor = AppColors.accent500;

    if (index < 0.7) {
      // Low frequencies - blue/primary
      return [
        primaryColor.withOpacity(0.3 + amplitude * 0.7),
        primaryColor.withOpacity(0.5 + amplitude * 0.5),
      ];
    } else if (index < 1.4) {
      // Mid frequencies - green/secondary
      return [
        secondaryColor.withOpacity(0.3 + amplitude * 0.7),
        secondaryColor.withOpacity(0.5 + amplitude * 0.5),
      ];
    } else {
      // High frequencies - purple/accent
      return [
        accentColor.withOpacity(0.3 + amplitude * 0.7),
        accentColor.withOpacity(0.5 + amplitude * 0.5),
      ];
    }
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
              activeTrackColor: AppColors.primary500,
              inactiveTrackColor: Colors.grey.shade800,
              thumbColor: AppColors.primary500,
              overlayColor: AppColors.primary500.withOpacity(0.2),
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
                  color: Colors.grey[400],
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                state.formattedDuration,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
    final double spacing = isSmallScreen ? 8.0 : 14.0;
    final double iconSize = isSmallScreen ? 22.0 : 26.0;
    final double buttonSize = isSmallScreen ? 48.0 : 60.0;
    final double playIconSize = isSmallScreen ? 26.0 : 30.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0,
        vertical: isSmallScreen ? 4.0 : 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shuffle button
          _buildAnimatedControlButton(
            icon: Icons.shuffle_rounded,
            color: state.isShuffleEnabled ? AppColors.primary500 : Colors.grey[600]!,
            onTap: () {
              context.read<AudioPlayerBloc>().add(ToggleShuffle());
            },
            iconSize: iconSize,
            isActive: state.isShuffleEnabled,
          ),
          SizedBox(width: spacing),
          
          // Previous button
          _buildAnimatedControlButton(
            icon: Icons.skip_previous_rounded,
            color: state.hasPrevious ? Colors.white : Colors.grey[600]!,
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
          _buildAnimatedControlButton(
            icon: Icons.skip_next_rounded,
            color: state.hasNext ? Colors.white : Colors.grey[600]!,
            onTap: state.hasNext
                ? () {
                    context.read<AudioPlayerBloc>().add(NextTrack());
                  }
                : null,
            iconSize: iconSize,
          ),
          SizedBox(width: spacing),
          
          // Repeat button
          Flexible(
            child: _buildAnimatedControlButton(
              icon: _getRepeatIcon(state.repeatMode),
              color: state.repeatMode != RepeatMode.off ? AppColors.primary500 : Colors.grey[600]!,
              onTap: () {
                final modes = [RepeatMode.off, RepeatMode.one, RepeatMode.all];
                final currentIndex = modes.indexOf(state.repeatMode);
                final nextIndex = (currentIndex + 1) % modes.length;
                context.read<AudioPlayerBloc>().add(SetRepeatMode(modes[nextIndex]));
              },
              iconSize: iconSize,
              isActive: state.repeatMode != RepeatMode.off,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedControlButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    double iconSize = 26.0,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: iconSize + 20.0,
        height: iconSize + 20.0,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
        ),
        child: Icon(
          icon,
          color: onTap != null ? color : color.withOpacity(0.4),
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, AudioPlayerState state, double size, double iconSize) {
    return GestureDetector(
      onTap: () {
        context.read<AudioPlayerBloc>().add(TogglePlayPause());
        // Control rotation when play/pause toggled
        if (!state.isPlaying) {
          _rotationController.repeat();
          _startVisualizer();
        } else {
          _rotationController.stop();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary500.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat_rounded;
      case RepeatMode.one:
        return Icons.repeat_one_rounded;
      case RepeatMode.all:
        return Icons.repeat_rounded;
      default:
        return Icons.repeat_rounded;
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
            icon: Icons.favorite_border_rounded,
            label: 'Like',
            onTap: () {
              _showSnackBar(context, 'Added to favorites ❤️');
            },
            iconSize: iconSize,
            labelSize: labelSize,
          ),
          SizedBox(width: spacing),
          _buildExtraControlButton(
            icon: Icons.playlist_add_rounded,
            label: 'Playlist',
            onTap: () {
              _showSnackBar(context, 'Add to playlist 📋');
            },
            iconSize: iconSize,
            labelSize: labelSize,
          ),
          SizedBox(width: spacing),
          _buildExtraControlButton(
            icon: Icons.download_rounded,
            label: 'Download',
            onTap: () {
              _showSnackBar(context, 'Downloading... 📥');
            },
            iconSize: iconSize,
            labelSize: labelSize,
          ),
          SizedBox(width: spacing),
          _buildExtraControlButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: () {
              _showSnackBar(context, 'Share coming soon! 📤');
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.grey[400],
              size: iconSize,
            ),
          ),
          SizedBox(height: labelSize * 0.4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, AudioPlayerState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.playlist_play_rounded, color: AppColors.primary500),
              title: const Text(
                'Add to Playlist',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Add to playlist 📋');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded, color: Colors.red),
              title: const Text(
                'Add to Favorites',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Added to favorites ❤️');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.blue),
              title: const Text(
                'Download',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Downloading... 📥');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.green),
              title: const Text(
                'Share',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, 'Share coming soon! 📤');
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline_rounded, color: Colors.grey[400]),
              title: const Text(
                'Song Info',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(context, '${state.currentMedia?.title} - ${state.currentMedia?.artist}');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[900],
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// import 'package:flutter/material.dart' hide RepeatMode;
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:marquee/marquee.dart';
// import 'dart:math';
// import 'dart:async';
// import '../bloc/audio_player_bloc.dart';
// import '../bloc/audio_player_event.dart';
// import '../bloc/audio_player_state.dart';
// import '../../domain/entities/repeat_mode.dart';
// import '../../../../core/themes/color_palette.dart';

// class NowPlayingScreen extends StatefulWidget {
//   const NowPlayingScreen({super.key});

//   @override
//   State<NowPlayingScreen> createState() => _NowPlayingScreenState();
// }

// class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   Timer? _visualizerTimer;
//   List<double> _amplitudes = List.generate(30, (_) => 0.0);
//   final Random _random = Random();

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
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeOutCubic,
//       ),
//     );
//     _animationController.forward();
    
//     // Start audio visualizer timer
//     _startVisualizer();
//   }

//   void _startVisualizer() {
//     _visualizerTimer?.cancel();
//     _visualizerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
//       if (mounted) {
//         setState(() {
//           // Generate random amplitude values that simulate audio waves
//           _amplitudes = List.generate(30, (index) {
//             // Create wave-like patterns with random variations
//             final base = 0.2 + 0.8 * (1 - (index / 30));
//             final variation = _random.nextDouble() * 0.8;
//             final peak = sin(index * 0.5 + timer.tick * 0.1) * 0.5 + 0.5;
//             return (base * variation * peak).clamp(0.0, 1.0);
//           });
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _visualizerTimer?.cancel();
//     super.dispose();
//   }

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

//           return FadeTransition(
//             opacity: _fadeAnimation,
//             child: ScaleTransition(
//               scale: _scaleAnimation,
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       AppColors.primary800.withOpacity(0.3),
//                       AppColors.secondary800.withOpacity(0.2),
//                       Colors.black,
//                     ],
//                   ),
//                 ),
//                 child: SafeArea(
//                   child: LayoutBuilder(
//                     builder: (context, constraints) {
//                       final screenSize = MediaQuery.of(context).size;
//                       final isSmallScreen = screenSize.width < 360;
//                       final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
//                       final isLargeScreen = screenSize.width >= 600;
                      
//                       return SingleChildScrollView(
//                         child: ConstrainedBox(
//                           constraints: BoxConstraints(
//                             minHeight: constraints.maxHeight,
//                           ),
//                           child: IntrinsicHeight(
//                             child: Column(
//                               children: [
//                                 _buildHeader(context, state),
//                                 Expanded(
//                                   flex: isSmallScreen ? 2 : 3,
//                                   child: _buildAlbumArt(state, screenSize, isSmallScreen),
//                                 ),
//                                 _buildSongInfo(state, isSmallScreen),
//                                 _buildAudioVisualizer(state, isSmallScreen),
//                                 _buildProgress(context, state, isSmallScreen),
//                                 _buildControls(context, state, isSmallScreen),
//                                 _buildExtraControls(context, state, isSmallScreen),
//                                 const SizedBox(height: 16),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context, AudioPlayerState state) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
//             ),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const Flexible(
//             child: Text(
//               'Now Playing',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           IconButton(
//             icon: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
//             ),
//             onPressed: () {
//               _showOptionsBottomSheet(context, state);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAlbumArt(AudioPlayerState state, Size screenSize, bool isSmallScreen) {
//     final double size = screenSize.width * 0.75;
//     final double maxSize = screenSize.height * 0.45;
//     final double albumSize = size > maxSize ? maxSize : size;
//     final isPlaying = state.isPlaying;
    
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       margin: EdgeInsets.all(screenSize.width * 0.04),
//       constraints: BoxConstraints(
//         maxWidth: albumSize,
//         maxHeight: albumSize,
//       ),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: isPlaying 
//                 ? AppColors.primary500.withOpacity(0.3)
//                 : Colors.black.withOpacity(0.3),
//             blurRadius: 30,
//             spreadRadius: isPlaying ? 5 : 2,
//           ),
//         ],
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: isPlaying
//               ? [
//                   AppColors.primary400.withOpacity(0.3),
//                   AppColors.secondary400.withOpacity(0.3),
//                 ]
//               : [
//                   Colors.grey.shade800.withOpacity(0.3),
//                   Colors.grey.shade900.withOpacity(0.3),
//                 ],
//         ),
//       ),
//       child: AspectRatio(
//         aspectRatio: 1,
//         child: Stack(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(24),
//               child: state.currentMedia?.albumArt != null
//                   ? Image.network(
//                       state.currentMedia!.albumArt!,
//                       fit: BoxFit.cover,
//                       width: double.infinity,
//                       height: double.infinity,
//                       errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
//                     )
//                   : _buildPlaceholderArt(),
//             ),
//             // Animated overlay gradient for playing state
//             if (isPlaying)
//               AnimatedContainer(
//                 duration: const Duration(seconds: 2),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(24),
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       Colors.transparent,
//                       AppColors.primary500.withOpacity(0.1),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//               ),
//             // Status indicator
//             Positioned(
//               top: 8,
//               right: 8,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.6),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: isPlaying ? AppColors.primary500.withOpacity(0.3) : Colors.transparent,
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: 6,
//                       height: 6,
//                       decoration: BoxDecoration(
//                         color: isPlaying ? Colors.green : Colors.grey,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       isPlaying ? 'Playing' : 'Paused',
//                       style: TextStyle(
//                         color: isPlaying ? Colors.green : Colors.grey,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPlaceholderArt() {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColors.primary500.withOpacity(0.4),
//             AppColors.secondary500.withOpacity(0.2),
//           ],
//         ),
//       ),
//       child: Center(
//         child: Icon(
//           Icons.music_note,
//           size: 80,
//           color: Colors.white.withOpacity(0.6),
//         ),
//       ),
//     );
//   }

//   Widget _buildSongInfo(AudioPlayerState state, bool isSmallScreen) {
//     final double titleFontSize = isSmallScreen ? 18.0 : 22.0;
//     final double artistFontSize = isSmallScreen ? 14.0 : 16.0;
//     final int marqueeThreshold = isSmallScreen ? 20 : 30;
    
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: isSmallScreen ? 16.0 : 24.0,
//         vertical: 4.0,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Song Title with gradient and marquee
//           SizedBox(
//             height: isSmallScreen ? 28.0 : 34.0,
//             child: ShaderMask(
//               shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
//               child: state.currentMedia!.title.length > marqueeThreshold
//                   ? Marquee(
//                       text: state.currentMedia!.title,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: titleFontSize,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       scrollAxis: Axis.horizontal,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       blankSpace: 20.0,
//                       velocity: 30.0,
//                     )
//                   : Text(
//                       state.currentMedia!.title,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: titleFontSize,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//             ),
//           ),
//           SizedBox(height: isSmallScreen ? 2.0 : 4.0),
//           Row(
//             children: [
//               Container(
//                 width: 4,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: AppColors.primary500,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   state.currentMedia!.artist,
//                   style: TextStyle(
//                     color: Colors.grey[400],
//                     fontSize: artistFontSize,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAudioVisualizer(AudioPlayerState state, bool isSmallScreen) {
//     if (!state.isPlaying) {
//       return Padding(
//         padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
//         child: Text(
//           'Tap play to see the music come alive 🎵',
//           style: TextStyle(
//             color: Colors.grey[500],
//             fontSize: isSmallScreen ? 11 : 13,
//             fontWeight: FontWeight.w400,
//             letterSpacing: 0.5,
//           ),
//         ),
//       );
//     }

//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: isSmallScreen ? 16 : 24,
//         vertical: isSmallScreen ? 8 : 12,
//       ),
//       child: Column(
//         children: [
//           // Animated bar visualizer
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 50),
//             height: isSmallScreen ? 40 : 50,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(
//                 30,
//                 (index) => _buildVisualizerBar(index, isSmallScreen),
//               ),
//             ),
//           ),
//           const SizedBox(height: 4),
//           // Frequency labels
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Bass',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: isSmallScreen ? 8 : 10,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               Text(
//                 'Mid',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: isSmallScreen ? 8 : 10,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               Text(
//                 'Treble',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: isSmallScreen ? 8 : 10,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVisualizerBar(int index, bool isSmallScreen) {
//     final amplitude = _amplitudes[index];
//     final height = 10 + (amplitude * (isSmallScreen ? 30 : 40));
//     final colorIndex = (index / _amplitudes.length) * 2.0;
//     final isEven = index % 2 == 0;
    
//     return Expanded(
//       child: Container(
//         margin: EdgeInsets.symmetric(horizontal: 1.5),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 50),
//           height: height,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: isEven ? Alignment.bottomCenter : Alignment.topCenter,
//               end: isEven ? Alignment.topCenter : Alignment.bottomCenter,
//               colors: _getGradientColors(amplitude, colorIndex),
//             ),
//             borderRadius: BorderRadius.circular(3),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.primary500.withOpacity(amplitude * 0.3),
//                 blurRadius: 4,
//                 spreadRadius: amplitude * 2,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   List<Color> _getGradientColors(double amplitude, double index) {
//     final primaryColor = AppColors.primary500;
//     final secondaryColor = AppColors.secondary500;
//     final accentColor = AppColors.accent500;

//     if (index < 0.7) {
//       // Low frequencies - blue/primary
//       return [
//         primaryColor.withOpacity(0.3 + amplitude * 0.7),
//         primaryColor.withOpacity(0.5 + amplitude * 0.5),
//       ];
//     } else if (index < 1.4) {
//       // Mid frequencies - green/secondary
//       return [
//         secondaryColor.withOpacity(0.3 + amplitude * 0.7),
//         secondaryColor.withOpacity(0.5 + amplitude * 0.5),
//       ];
//     } else {
//       // High frequencies - purple/accent
//       return [
//         accentColor.withOpacity(0.3 + amplitude * 0.7),
//         accentColor.withOpacity(0.5 + amplitude * 0.5),
//       ];
//     }
//   }

//   Widget _buildProgress(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
//     final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
//     final double thumbRadius = isSmallScreen ? 6.0 : 8.0;
//     final double overlayRadius = isSmallScreen ? 12.0 : 16.0;
//     final double fontSize = isSmallScreen ? 10.0 : 12.0;
    
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4.0),
//       child: Column(
//         children: [
//           SliderTheme(
//             data: SliderThemeData(
//               trackHeight: isSmallScreen ? 3.0 : 4.0,
//               thumbShape: RoundSliderThumbShape(
//                 enabledThumbRadius: thumbRadius,
//                 pressedElevation: 8.0,
//               ),
//               overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
//               activeTrackColor: AppColors.primary500,
//               inactiveTrackColor: Colors.grey.shade800,
//               thumbColor: AppColors.primary500,
//               overlayColor: AppColors.primary500.withOpacity(0.2),
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
//                 style: TextStyle(
//                   color: Colors.grey[400],
//                   fontSize: fontSize,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Text(
//                 state.formattedDuration,
//                 style: TextStyle(
//                   color: Colors.grey[400],
//                   fontSize: fontSize,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControls(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
//     final double spacing = isSmallScreen ? 8.0 : 14.0;
//     final double iconSize = isSmallScreen ? 22.0 : 26.0;
//     final double buttonSize = isSmallScreen ? 48.0 : 60.0;
//     final double playIconSize = isSmallScreen ? 26.0 : 30.0;
    
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: isSmallScreen ? 8.0 : 16.0,
//         vertical: isSmallScreen ? 4.0 : 8.0,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Shuffle button
//           _buildAnimatedControlButton(
//             icon: Icons.shuffle_rounded,
//             color: state.isShuffleEnabled ? AppColors.primary500 : Colors.grey[600]!,
//             onTap: () {
//               context.read<AudioPlayerBloc>().add(ToggleShuffle());
//             },
//             iconSize: iconSize,
//             isActive: state.isShuffleEnabled,
//           ),
//           SizedBox(width: spacing),
          
//           // Previous button
//           _buildAnimatedControlButton(
//             icon: Icons.skip_previous_rounded,
//             color: state.hasPrevious ? Colors.white : Colors.grey[600]!,
//             onTap: state.hasPrevious
//                 ? () {
//                     context.read<AudioPlayerBloc>().add(PreviousTrack());
//                   }
//                 : null,
//             iconSize: iconSize,
//           ),
//           SizedBox(width: spacing),
          
//           // Play/Pause button
//           _buildPlayButton(context, state, buttonSize, playIconSize),
//           SizedBox(width: spacing),
          
//           // Next button
//           _buildAnimatedControlButton(
//             icon: Icons.skip_next_rounded,
//             color: state.hasNext ? Colors.white : Colors.grey[600]!,
//             onTap: state.hasNext
//                 ? () {
//                     context.read<AudioPlayerBloc>().add(NextTrack());
//                   }
//                 : null,
//             iconSize: iconSize,
//           ),
//           SizedBox(width: spacing),
          
//           // Repeat button
//           Flexible(
//             child: _buildAnimatedControlButton(
//               icon: _getRepeatIcon(state.repeatMode),
//               color: state.repeatMode != RepeatMode.off ? AppColors.primary500 : Colors.grey[600]!,
//               onTap: () {
//                 final modes = [RepeatMode.off, RepeatMode.one, RepeatMode.all];
//                 final currentIndex = modes.indexOf(state.repeatMode);
//                 final nextIndex = (currentIndex + 1) % modes.length;
//                 context.read<AudioPlayerBloc>().add(SetRepeatMode(modes[nextIndex]));
//               },
//               iconSize: iconSize,
//               isActive: state.repeatMode != RepeatMode.off,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnimatedControlButton({
//     required IconData icon,
//     required Color color,
//     VoidCallback? onTap,
//     double iconSize = 26.0,
//     bool isActive = false,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: iconSize + 20.0,
//         height: iconSize + 20.0,
//         decoration: BoxDecoration(
//           color: isActive ? color.withOpacity(0.15) : Colors.transparent,
//           shape: BoxShape.circle,
//           border: isActive ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
//         ),
//         child: Icon(
//           icon,
//           color: onTap != null ? color : color.withOpacity(0.4),
//           size: iconSize,
//         ),
//       ),
//     );
//   }

//   Widget _buildPlayButton(BuildContext context, AudioPlayerState state, double size, double iconSize) {
//     return GestureDetector(
//       onTap: () {
//         context.read<AudioPlayerBloc>().add(TogglePlayPause());
//         // Restart visualizer when playing
//         if (!state.isPlaying) {
//           _startVisualizer();
//         }
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           gradient: AppColors.primaryGradient,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primary500.withOpacity(0.4),
//               blurRadius: 20,
//               spreadRadius: 5,
//             ),
//           ],
//         ),
//         child: Center(
//           child: Icon(
//             state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
//             color: Colors.white,
//             size: iconSize,
//           ),
//         ),
//       ),
//     );
//   }

//   IconData _getRepeatIcon(RepeatMode mode) {
//     switch (mode) {
//       case RepeatMode.off:
//         return Icons.repeat_rounded;
//       case RepeatMode.one:
//         return Icons.repeat_one_rounded;
//       case RepeatMode.all:
//         return Icons.repeat_rounded;
//       default:
//         return Icons.repeat_rounded;
//     }
//   }

//   Widget _buildExtraControls(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
//     final double iconSize = isSmallScreen ? 18.0 : 22.0;
//     final double labelSize = isSmallScreen ? 9.0 : 11.0;
//     final double spacing = isSmallScreen ? 4.0 : 12.0;
    
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: isSmallScreen ? 12.0 : 24.0,
//         vertical: isSmallScreen ? 4.0 : 8.0,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildExtraControlButton(
//             icon: Icons.favorite_border_rounded,
//             label: 'Like',
//             onTap: () {
//               _showSnackBar(context, 'Added to favorites ❤️');
//             },
//             iconSize: iconSize,
//             labelSize: labelSize,
//           ),
//           SizedBox(width: spacing),
//           _buildExtraControlButton(
//             icon: Icons.playlist_add_rounded,
//             label: 'Playlist',
//             onTap: () {
//               _showSnackBar(context, 'Add to playlist 📋');
//             },
//             iconSize: iconSize,
//             labelSize: labelSize,
//           ),
//           SizedBox(width: spacing),
//           _buildExtraControlButton(
//             icon: Icons.download_rounded,
//             label: 'Download',
//             onTap: () {
//               _showSnackBar(context, 'Downloading... 📥');
//             },
//             iconSize: iconSize,
//             labelSize: labelSize,
//           ),
//           SizedBox(width: spacing),
//           _buildExtraControlButton(
//             icon: Icons.share_rounded,
//             label: 'Share',
//             onTap: () {
//               _showSnackBar(context, 'Share coming soon! 📤');
//             },
//             iconSize: iconSize,
//             labelSize: labelSize,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExtraControlButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     double iconSize = 22.0,
//     double labelSize = 11.0,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.05),
//                 width: 1,
//               ),
//             ),
//             child: Icon(
//               icon,
//               color: Colors.grey[400],
//               size: iconSize,
//             ),
//           ),
//           SizedBox(height: labelSize * 0.4),
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.grey[500],
//               fontSize: labelSize,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showOptionsBottomSheet(BuildContext context, AudioPlayerState state) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.grey[900],
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(top: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[600],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: Icon(Icons.playlist_play_rounded, color: AppColors.primary500),
//               title: const Text(
//                 'Add to Playlist',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showSnackBar(context, 'Add to playlist 📋');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.favorite_border_rounded, color: Colors.red),
//               title: const Text(
//                 'Add to Favorites',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showSnackBar(context, 'Added to favorites ❤️');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.download_rounded, color: Colors.blue),
//               title: const Text(
//                 'Download',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showSnackBar(context, 'Downloading... 📥');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.share_rounded, color: Colors.green),
//               title: const Text(
//                 'Share',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showSnackBar(context, 'Share coming soon! 📤');
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.info_outline_rounded, color: Colors.grey[400]),
//               title: const Text(
//                 'Song Info',
//                 style: TextStyle(color: Colors.white),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showSnackBar(context, '${state.currentMedia?.title} - ${state.currentMedia?.artist}');
//               },
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.grey[900],
//         duration: const Duration(seconds: 2),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
// }

// // // Hide Flutter's RepeatMode at the top
// // import 'package:flutter/material.dart' hide RepeatMode;
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:marquee/marquee.dart';
// // import '../bloc/audio_player_bloc.dart';
// // import '../bloc/audio_player_event.dart';
// // import '../bloc/audio_player_state.dart';
// // import '../../domain/entities/repeat_mode.dart'; // Now this is the only RepeatMode
// // import '../../../../core/themes/color_palette.dart';

// // class NowPlayingScreen extends StatelessWidget {
// //   const NowPlayingScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       body: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
// //         builder: (context, state) {
// //           if (state.currentMedia == null) {
// //             return const Center(
// //               child: Text(
// //                 'No media playing',
// //                 style: TextStyle(color: Colors.white),
// //               ),
// //             );
// //           }

// //           return SafeArea(
// //             child: LayoutBuilder(
// //               builder: (context, constraints) {
// //                 final screenSize = MediaQuery.of(context).size;
// //                 final isSmallScreen = screenSize.width < 360;
// //                 final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
// //                 final isLargeScreen = screenSize.width >= 600;
                
// //                 return SingleChildScrollView(
// //                   child: ConstrainedBox(
// //                     constraints: BoxConstraints(
// //                       minHeight: constraints.maxHeight,
// //                     ),
// //                     child: IntrinsicHeight(
// //                       child: Column(
// //                         children: [
// //                           _buildHeader(context),
// //                           Expanded(
// //                             flex: isSmallScreen ? 2 : 3,
// //                             child: _buildAlbumArt(state, screenSize),
// //                           ),
// //                           _buildSongInfo(state, isSmallScreen),
// //                           _buildProgress(context, state, isSmallScreen),
// //                           _buildControls(context, state, isSmallScreen),
// //                           _buildExtraControls(context, state, isSmallScreen),
// //                           const SizedBox(height: 16),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildHeader(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           IconButton(
// //             icon: const Icon(Icons.arrow_downward, color: Colors.white),
// //             onPressed: () => Navigator.pop(context),
// //             padding: EdgeInsets.zero,
// //             constraints: const BoxConstraints(),
// //           ),
// //           const Flexible(
// //             child: Text(
// //               'Now Playing',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.w600,
// //               ),
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.more_vert, color: Colors.white),
// //             onPressed: () {
// //               // Show options
// //             },
// //             padding: EdgeInsets.zero,
// //             constraints: const BoxConstraints(),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildAlbumArt(AudioPlayerState state, Size screenSize) {
// //     final double size = screenSize.width * 0.75;
// //     final double maxSize = screenSize.height * 0.45;
// //     final double albumSize = size > maxSize ? maxSize : size;
    
// //     return Container(
// //       margin: EdgeInsets.all(screenSize.width * 0.04),
// //       constraints: BoxConstraints(
// //         maxWidth: albumSize,
// //         maxHeight: albumSize,
// //       ),
// //       decoration: BoxDecoration(
// //         borderRadius: BorderRadius.circular(20),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.5),
// //             blurRadius: 20,
// //             spreadRadius: 5,
// //           ),
// //         ],
// //       ),
// //       child: AspectRatio(
// //         aspectRatio: 1,
// //         child: ClipRRect(
// //           borderRadius: BorderRadius.circular(20),
// //           child: state.currentMedia?.albumArt != null
// //               ? Image.network(
// //                   state.currentMedia!.albumArt!,
// //                   fit: BoxFit.cover,
// //                   width: double.infinity,
// //                   height: double.infinity,
// //                   errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
// //                 )
// //               : _buildPlaceholderArt(),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildPlaceholderArt() {
// //     return Container(
// //       width: double.infinity,
// //       height: double.infinity,
// //       color: AppColors.primary.withOpacity(0.3),
// //       child: const Center(
// //         child: Icon(
// //           Icons.music_note,
// //           size: 80,
// //           color: Colors.white,
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSongInfo(AudioPlayerState state, bool isSmallScreen) {
// //     final double titleFontSize = isSmallScreen ? 18.0 : 22.0;
// //     final double artistFontSize = isSmallScreen ? 14.0 : 16.0;
// //     final int marqueeThreshold = isSmallScreen ? 20 : 30;
    
// //     return Padding(
// //       padding: EdgeInsets.symmetric(
// //         horizontal: isSmallScreen ? 16.0 : 24.0,
// //         vertical: 4.0,
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // Song Title with Marquee
// //           SizedBox(
// //             height: isSmallScreen ? 26.0 : 30.0,
// //             child: state.currentMedia!.title.length > marqueeThreshold
// //                 ? Marquee(
// //                     text: state.currentMedia!.title,
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: titleFontSize,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                     scrollAxis: Axis.horizontal,
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     blankSpace: 20.0,
// //                     velocity: 30.0,
// //                   )
// //                 : Text(
// //                     state.currentMedia!.title,
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: titleFontSize,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //           ),
// //           SizedBox(height: isSmallScreen ? 2.0 : 4.0),
// //           Text(
// //             state.currentMedia!.artist,
// //             style: TextStyle(
// //               color: Colors.grey,
// //               fontSize: artistFontSize,
// //             ),
// //             overflow: TextOverflow.ellipsis,
// //             maxLines: 1,
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildProgress(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
// //     final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
// //     final double thumbRadius = isSmallScreen ? 6.0 : 8.0;
// //     final double overlayRadius = isSmallScreen ? 12.0 : 16.0;
// //     final double fontSize = isSmallScreen ? 10.0 : 12.0;
    
// //     return Padding(
// //       padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4.0),
// //       child: Column(
// //         children: [
// //           SliderTheme(
// //             data: SliderThemeData(
// //               trackHeight: isSmallScreen ? 3.0 : 4.0,
// //               thumbShape: RoundSliderThumbShape(
// //                 enabledThumbRadius: thumbRadius,
// //                 pressedElevation: 8.0,
// //               ),
// //               overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
// //               activeTrackColor: AppColors.primary,
// //               inactiveTrackColor: Colors.grey.shade800,
// //               thumbColor: AppColors.primary,
// //               overlayColor: AppColors.primary.withOpacity(0.2),
// //             ),
// //             child: Slider(
// //               value: state.progress.clamp(0.0, 1.0),
// //               onChanged: (value) {
// //                 final position = Duration(
// //                   milliseconds: (value * (state.duration?.inMilliseconds ?? 0)).round(),
// //                 );
// //                 context.read<AudioPlayerBloc>().add(Seek(position));
// //               },
// //             ),
// //           ),
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               Text(
// //                 state.formattedPosition,
// //                 style: TextStyle(
// //                   color: Colors.grey,
// //                   fontSize: fontSize,
// //                 ),
// //               ),
// //               Text(
// //                 state.formattedDuration,
// //                 style: TextStyle(
// //                   color: Colors.grey,
// //                   fontSize: fontSize,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildControls(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
// //     final double spacing = isSmallScreen ? 8.0 : 14.0; // Reduced spacing
// //     final double iconSize = isSmallScreen ? 22.0 : 26.0;
// //     final double buttonSize = isSmallScreen ? 48.0 : 60.0;
// //     final double playIconSize = isSmallScreen ? 26.0 : 30.0;
    
// //     return Padding(
// //       padding: EdgeInsets.symmetric(
// //         horizontal: isSmallScreen ? 8.0 : 16.0, // Reduced horizontal padding
// //         vertical: isSmallScreen ? 4.0 : 8.0,
// //       ),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           // Shuffle button
// //           _buildControlButton(
// //             icon: Icons.shuffle,
// //             color: state.isShuffleEnabled ? AppColors.primary : Colors.grey,
// //             onTap: () {
// //               context.read<AudioPlayerBloc>().add(ToggleShuffle());
// //             },
// //             iconSize: iconSize,
// //           ),
// //           SizedBox(width: spacing),
          
// //           // Previous button
// //           _buildControlButton(
// //             icon: Icons.skip_previous,
// //             onTap: state.hasPrevious
// //                 ? () {
// //                     context.read<AudioPlayerBloc>().add(PreviousTrack());
// //                   }
// //                 : null,
// //             iconSize: iconSize,
// //           ),
// //           SizedBox(width: spacing),
          
// //           // Play/Pause button
// //           _buildPlayButton(context, state, buttonSize, playIconSize),
// //           SizedBox(width: spacing),
          
// //           // Next button
// //           _buildControlButton(
// //             icon: Icons.skip_next,
// //             onTap: state.hasNext
// //                 ? () {
// //                     context.read<AudioPlayerBloc>().add(NextTrack());
// //                   }
// //                 : null,
// //             iconSize: iconSize,
// //           ),
// //           SizedBox(width: spacing),
          
// //           // Repeat button - with flexible to prevent overflow
// //           Flexible(
// //             child: _buildControlButton(
// //               icon: _getRepeatIcon(state.repeatMode),
// //               color: state.repeatMode != RepeatMode.off ? AppColors.primary : Colors.grey,
// //               onTap: () {
// //                 final modes = [RepeatMode.off, RepeatMode.one, RepeatMode.all];
// //                 final currentIndex = modes.indexOf(state.repeatMode);
// //                 final nextIndex = (currentIndex + 1) % modes.length;
// //                 context.read<AudioPlayerBloc>().add(SetRepeatMode(modes[nextIndex]));
// //               },
// //               iconSize: iconSize,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildPlayButton(BuildContext context, AudioPlayerState state, double size, double iconSize) {
// //     return Container(
// //       width: size,
// //       height: size,
// //       decoration:  BoxDecoration(
// //         color: AppColors.primary,
// //         shape: BoxShape.circle,
// //       ),
// //       child: IconButton(
// //         icon: Icon(
// //           state.isPlaying ? Icons.pause : Icons.play_arrow,
// //           color: Colors.white,
// //           size: iconSize,
// //         ),
// //         onPressed: () {
// //           context.read<AudioPlayerBloc>().add(TogglePlayPause());
// //         },
// //         padding: EdgeInsets.zero,
// //         constraints: const BoxConstraints(),
// //       ),
// //     );
// //   }

// //   Widget _buildControlButton({
// //     required IconData icon,
// //     Color? color,
// //     VoidCallback? onTap,
// //     double iconSize = 26.0,
// //   }) {
// //     return SizedBox(
// //       width: iconSize + 16.0, // Ensure consistent touch target
// //       height: iconSize + 16.0,
// //       child: IconButton(
// //         icon: Icon(
// //           icon,
// //           color: color ?? Colors.white,
// //           size: iconSize,
// //         ),
// //         onPressed: onTap,
// //         splashRadius: 20.0,
// //         padding: EdgeInsets.zero,
// //         constraints: const BoxConstraints(),
// //       ),
// //     );
// //   }

// //   IconData _getRepeatIcon(RepeatMode mode) {
// //     switch (mode) {
// //       case RepeatMode.off:
// //         return Icons.repeat;
// //       case RepeatMode.one:
// //         return Icons.repeat_one;
// //       case RepeatMode.all:
// //         return Icons.repeat;
// //       default:
// //         return Icons.repeat;
// //     }
// //   }

// //   Widget _buildExtraControls(BuildContext context, AudioPlayerState state, bool isSmallScreen) {
// //     final double iconSize = isSmallScreen ? 18.0 : 22.0;
// //     final double labelSize = isSmallScreen ? 9.0 : 11.0;
// //     final double spacing = isSmallScreen ? 4.0 : 12.0;
    
// //     return Padding(
// //       padding: EdgeInsets.symmetric(
// //         horizontal: isSmallScreen ? 12.0 : 24.0,
// //         vertical: isSmallScreen ? 4.0 : 8.0,
// //       ),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //         children: [
// //           _buildExtraControlButton(
// //             icon: Icons.favorite_border,
// //             label: 'Favorite',
// //             onTap: () {
// //               // TODO: Add to favorites
// //             },
// //             iconSize: iconSize,
// //             labelSize: labelSize,
// //           ),
// //           SizedBox(width: spacing),
// //           _buildExtraControlButton(
// //             icon: Icons.playlist_add,
// //             label: 'Add to',
// //             onTap: () {
// //               // TODO: Add to playlist
// //             },
// //             iconSize: iconSize,
// //             labelSize: labelSize,
// //           ),
// //           SizedBox(width: spacing),
// //           _buildExtraControlButton(
// //             icon: Icons.download,
// //             label: 'Download',
// //             onTap: () {
// //               // TODO: Download
// //             },
// //             iconSize: iconSize,
// //             labelSize: labelSize,
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildExtraControlButton({
// //     required IconData icon,
// //     required String label,
// //     required VoidCallback onTap,
// //     double iconSize = 22.0,
// //     double labelSize = 11.0,
// //   }) {
// //     return InkWell(
// //       onTap: onTap,
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Icon(
// //             icon,
// //             color: Colors.grey,
// //             size: iconSize,
// //           ),
// //           SizedBox(height: labelSize * 0.4),
// //           Text(
// //             label,
// //             style: TextStyle(
// //               color: Colors.grey,
// //               fontSize: labelSize,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
