import 'package:equatable/equatable.dart';
import '../../../data/models/global_event.dart';
import '../../../data/repositories/event_repository.dart';

/// The overall loading status of the events system.
enum EventsStatus { initial, loading, loaded, error }

/// Immutable state for the EventsBloc.
/// Contains all events, filter settings, source statuses, and the
/// currently selected event.
class EventsState extends Equatable {
  /// Overall status of the events system.
  final EventsStatus status;

  /// All events from all sources, merged and deduplicated.
  final List<GlobalEvent> allEvents;

  /// Events after applying active filters (category + severity).
  final List<GlobalEvent> filteredEvents;

  /// Per-source status for the API status indicators in Settings.
  final Map<EventSource, SourceResult> sourceResults;

  /// Currently enabled data sources.
  final Set<EventSource> enabledSources;

  /// Active category filters (empty = show all).
  final Set<EventCategory> activeCategories;

  /// Active severity filters (empty = show all).
  final Set<EventSeverity> activeSeverities;

  /// Currently selected event (user tapped a marker or card).
  final GlobalEvent? selectedEvent;

  /// Error message for display.
  final String? errorMessage;

  const EventsState({
    this.status = EventsStatus.initial,
    this.allEvents = const [],
    this.filteredEvents = const [],
    this.sourceResults = const {},
    this.enabledSources = const {
      EventSource.usgs,
      EventSource.nasaEonet,
      EventSource.who,
    },
    this.activeCategories = const {},
    this.activeSeverities = const {},
    this.selectedEvent,
    this.errorMessage,
  });

  /// Quick stats for the Home dashboard.
  int get totalEvents => filteredEvents.length;

  int get earthquakeCount =>
      filteredEvents.where((e) => e.category == EventCategory.earthquake).length;

  int get disasterCount => filteredEvents
      .where((e) =>
          e.category == EventCategory.floodStorm ||
          e.category == EventCategory.wildfire)
      .length;

  int get diseaseCount => filteredEvents
      .where((e) => e.category == EventCategory.diseaseOutbreak)
      .length;

  int get criticalCount =>
      filteredEvents.where((e) => e.severity == EventSeverity.critical).length;

  int get highCount =>
      filteredEvents.where((e) => e.severity == EventSeverity.high).length;

  int get mediumCount =>
      filteredEvents.where((e) => e.severity == EventSeverity.medium).length;

  int get lowCount =>
      filteredEvents.where((e) => e.severity == EventSeverity.low).length;

  EventsState copyWith({
    EventsStatus? status,
    List<GlobalEvent>? allEvents,
    List<GlobalEvent>? filteredEvents,
    Map<EventSource, SourceResult>? sourceResults,
    Set<EventSource>? enabledSources,
    Set<EventCategory>? activeCategories,
    Set<EventSeverity>? activeSeverities,
    GlobalEvent? selectedEvent,
    String? errorMessage,
    bool clearSelectedEvent = false,
  }) {
    return EventsState(
      status: status ?? this.status,
      allEvents: allEvents ?? this.allEvents,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      sourceResults: sourceResults ?? this.sourceResults,
      enabledSources: enabledSources ?? this.enabledSources,
      activeCategories: activeCategories ?? this.activeCategories,
      activeSeverities: activeSeverities ?? this.activeSeverities,
      selectedEvent:
          clearSelectedEvent ? null : (selectedEvent ?? this.selectedEvent),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allEvents,
        filteredEvents,
        sourceResults,
        enabledSources,
        activeCategories,
        activeSeverities,
        selectedEvent,
        errorMessage,
      ];
}
