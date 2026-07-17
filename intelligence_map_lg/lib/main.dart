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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive type adapters (manual, no code generation needed)
  Hive.registerAdapter(EventSeverityAdapter());
  Hive.registerAdapter(EventCategoryAdapter());
  Hive.registerAdapter(EventSourceAdapter());
  Hive.registerAdapter(GlobalEventAdapter());

  // Open settings box
  await Hive.openBox('settings_box');

  // Create shared service instances
  final sshService = SSHService();
  final kmlService = KMLService();
  final eventRepository = EventRepository();
  final ttsService = TTSService();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: sshService),
        RepositoryProvider.value(value: kmlService),
        RepositoryProvider.value(value: eventRepository),
        RepositoryProvider.value(value: ttsService),
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
  );
}
