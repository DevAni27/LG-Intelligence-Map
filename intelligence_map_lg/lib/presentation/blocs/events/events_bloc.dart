import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/global_event.dart';
import '../../../data/repositories/event_repository.dart';
import 'events_event.dart';
import 'events_state.dart';

/// The EventsBloc manages all global event data across the app.
///
/// It handles:
/// - Parallel fetching from multiple data sources
/// - Independent failure handling per source
/// - Category and severity filtering
/// - Event selection for detail views
///
/// This is the central state that feeds the Home dashboard,
/// Map markers, AI chat context, and Timeline.
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventRepository _repository;

  EventsBloc({EventRepository? repository})
      : _repository = repository ?? EventRepository(),
        super(const EventsState()) {
    on<FetchAllEvents>(_onFetchAllEvents);
    on<RefreshSource>(_onRefreshSource);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterBySeverity>(_onFilterBySeverity);
    on<ToggleSource>(_onToggleSource);
    on<SelectEvent>(_onSelectEvent);
  }

  /// Fetches events from all enabled sources in parallel.
  /// Each source reports its own loading/success/error state.
  Future<void> _onFetchAllEvents(
    FetchAllEvents event,
    Emitter<EventsState> emit,
  ) async {
    // Emit loading state with initial source statuses so Settings
    // shows "Loading..." for each API immediately
    final initialResults = <EventSource, SourceResult>{};
    for (final source in state.enabledSources) {
      initialResults[source] = SourceResult(
        source: source,
        status: SourceStatus.loading,
      );
    }
    emit(state.copyWith(
      status: EventsStatus.loading,
      sourceResults: initialResults,
    ));

    try {
      final results = await _repository.fetchAllEvents(
        enabledSources: state.enabledSources,
      );

      // Merge all successful results into one list
      final allEvents = _repository.mergeAndSort(results);
      final deduplicated = _repository.deduplicate(allEvents);
      final filtered = _applyFilters(deduplicated);

      emit(state.copyWith(
        status: EventsStatus.loaded,
        allEvents: deduplicated,
        filteredEvents: filtered,
        sourceResults: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EventsStatus.error,
        errorMessage: 'Failed to fetch events: $e',
      ));
    }
  }

  /// Refreshes a single data source without affecting others.
  Future<void> _onRefreshSource(
    RefreshSource event,
    Emitter<EventsState> emit,
  ) async {
    // Mark that source as loading
    final updatedResults = Map<EventSource, SourceResult>.from(
      state.sourceResults,
    );
    if (updatedResults.containsKey(event.source)) {
      updatedResults[event.source] = updatedResults[event.source]!.copyWith(
        status: SourceStatus.loading,
      );
      emit(state.copyWith(sourceResults: updatedResults));
    }

    // Re-fetch all (the repository handles parallelism)
    add(FetchAllEvents());
  }

  /// Applies category filter — events not in the selected categories
  /// are hidden from the map, dashboard, and timeline.
  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<EventsState> emit,
  ) {
    final filtered = _applyFilters(
      state.allEvents,
      categories: event.categories,
      severities: state.activeSeverities,
    );

    emit(state.copyWith(
      activeCategories: event.categories,
      filteredEvents: filtered,
    ));
  }

  /// Applies severity filter.
  void _onFilterBySeverity(
    FilterBySeverity event,
    Emitter<EventsState> emit,
  ) {
    final filtered = _applyFilters(
      state.allEvents,
      categories: state.activeCategories,
      severities: event.severities,
    );

    emit(state.copyWith(
      activeSeverities: event.severities,
      filteredEvents: filtered,
    ));
  }

  /// Toggles a data source on or off, then re-fetches.
  void _onToggleSource(
    ToggleSource event,
    Emitter<EventsState> emit,
  ) {
    final updatedSources = Set<EventSource>.from(state.enabledSources);

    if (event.enabled) {
      updatedSources.add(event.source);
    } else {
      updatedSources.remove(event.source);
    }

    emit(state.copyWith(enabledSources: updatedSources));

    // Re-fetch with updated source list
    add(FetchAllEvents());
  }

  /// Sets the currently selected event (for detail panel / fly-to).
  void _onSelectEvent(
    SelectEvent event,
    Emitter<EventsState> emit,
  ) {
    if (event.event == null) {
      emit(state.copyWith(clearSelectedEvent: true));
    } else {
      emit(state.copyWith(selectedEvent: event.event));
    }
  }

  /// Applies both category and severity filters to the event list.
  /// Empty filter set means "show all" for that dimension.
  List<GlobalEvent> _applyFilters(
    List<GlobalEvent> events, {
    Set<EventCategory>? categories,
    Set<EventSeverity>? severities,
  }) {
    final cats = categories ?? state.activeCategories;
    final sevs = severities ?? state.activeSeverities;

    return events.where((event) {
      final matchesCategory = cats.isEmpty || cats.contains(event.category);
      final matchesSeverity = sevs.isEmpty || sevs.contains(event.severity);
      return matchesCategory && matchesSeverity;
    }).toList();
  }
}
