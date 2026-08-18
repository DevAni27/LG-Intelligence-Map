import 'package:equatable/equatable.dart';
import '../../../data/models/global_event.dart';

/// Events that can be dispatched to the EventsBloc.
/// BLoC pattern: Event in → State out.
abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch events from all enabled data sources in parallel.
class FetchAllEvents extends EventsEvent {}

/// Refresh a specific data source (e.g., retry after failure).
class RefreshSource extends EventsEvent {
  final EventSource source;

  const RefreshSource(this.source);

  @override
  List<Object?> get props => [source];
}

/// Apply category filter on the current events.
class FilterByCategory extends EventsEvent {
  final Set<EventCategory> categories;

  const FilterByCategory(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// Apply severity filter on the current events.
class FilterBySeverity extends EventsEvent {
  final Set<EventSeverity> severities;

  const FilterBySeverity(this.severities);

  @override
  List<Object?> get props => [severities];
}

/// Toggle a specific data source on or off.
class ToggleSource extends EventsEvent {
  final EventSource source;
  final bool enabled;

  const ToggleSource({required this.source, required this.enabled});

  @override
  List<Object?> get props => [source, enabled];
}

/// Select a specific event (e.g., user taps on a marker).
class SelectEvent extends EventsEvent {
  final GlobalEvent? event;

  const SelectEvent(this.event);

  @override
  List<Object?> get props => [event];
}
