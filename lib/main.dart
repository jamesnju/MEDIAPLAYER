import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media/core/di/service_locator.dart';
import 'package:media/core/routes/app_router.dart';
import 'package:media/core/routes/route_names.dart';
import 'package:media/core/themes/app_theme.dart';
import 'package:media/features/audioplayer/presentation/bloc/audio_player_bloc.dart';
import 'package:media/features/mediadetection/presentation/bloc/media_bloc.dart';
import 'package:media/features/mediadetection/presentation/bloc/media_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await ServiceLocator.setup();
    print('Service locator setup completed successfully');
  } catch (e) {
    print('Error setting up service locator: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            try {
              return MediaBloc()..add(const LoadMedia());
            } catch (e) {
              print('Error creating MediaBloc: $e');
              return MediaBloc();
            }
          },
        ),
        BlocProvider(
          create: (_) => AudioPlayerBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'MediaPlayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: RouteNames.home,
        builder: (context, child) {
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}