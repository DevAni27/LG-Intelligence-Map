import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/models/global_event_adapter.dart';
import 'data/repositories/event_repository.dart';
import 'logic/blocs/events/events_bloc.dart';
import 'logic/blocs/events/events_event.dart';
import 'services/ssh_service.dart';
import 'services/kml_service.dart';
import 'services/tts_service.dart';
import 'package:provider/provider.dart';
import 'services/gemini_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  );

  final nativeSplashDelay =
      Future.delayed(const Duration(seconds: 2));

  await Hive.initFlutter();

  Hive.registerAdapter(EventSeverityAdapter());
  Hive.registerAdapter(EventCategoryAdapter());
  Hive.registerAdapter(EventSourceAdapter());
  Hive.registerAdapter(GlobalEventAdapter());

  await Hive.openBox('settings_box');

  final sshService = SSHService();
  final kmlService = KMLService();
  final eventRepository = EventRepository();
  final ttsService = TTSService();

  await nativeSplashDelay;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SSHService>(
          create: (_) => sshService,
        ),
        Provider<KMLService>(
          create: (_) => kmlService,
        ),
        Provider<TTSService>(
          create: (_) => ttsService,
        ),
        Provider<GeminiService>(
          create: (_) => GeminiService(),
        ),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(
            value: eventRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => EventsBloc(
                repository: eventRepository,
              )..add(FetchAllEvents()),
            ),
          ],
          child: const WorldIntelligenceMapApp(),
        ),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}