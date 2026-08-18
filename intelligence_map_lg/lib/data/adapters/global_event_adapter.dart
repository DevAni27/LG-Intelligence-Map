import 'package:hive/hive.dart';
import '../models/global_event.dart';

/// Manual Hive adapters for GlobalEvent and its enums.
/// This replaces hive_generator code generation to avoid
/// dependency conflicts with build_runner.

class EventSeverityAdapter extends TypeAdapter<EventSeverity> {
  @override
  final int typeId = 0;

  @override
  EventSeverity read(BinaryReader reader) {
    return EventSeverity.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, EventSeverity obj) {
    writer.writeInt(obj.index);
  }
}

class EventCategoryAdapter extends TypeAdapter<EventCategory> {
  @override
  final int typeId = 1;

  @override
  EventCategory read(BinaryReader reader) {
    return EventCategory.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, EventCategory obj) {
    writer.writeInt(obj.index);
  }
}

class EventSourceAdapter extends TypeAdapter<EventSource> {
  @override
  final int typeId = 2;

  @override
  EventSource read(BinaryReader reader) {
    return EventSource.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, EventSource obj) {
    writer.writeInt(obj.index);
  }
}

class GlobalEventAdapter extends TypeAdapter<GlobalEvent> {
  @override
  final int typeId = 3;

  @override
  GlobalEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return GlobalEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as EventCategory,
      severity: fields[4] as EventSeverity,
      latitude: fields[5] as double,
      longitude: fields[6] as double,
      locationName: fields[7] as String,
      timestamp: fields[8] as DateTime,
      source: fields[9] as EventSource,
      sourceUrl: fields[10] as String?,
      metadata: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, GlobalEvent obj) {
    writer
      ..writeByte(12) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.locationName)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.source)
      ..writeByte(10)
      ..write(obj.sourceUrl)
      ..writeByte(11)
      ..write(obj.metadata);
  }
}
