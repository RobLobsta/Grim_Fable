// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adventure.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StorySegmentAdapter extends TypeAdapter<StorySegment> {
  @override
  final int typeId = 1;

  @override
  StorySegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StorySegment(
      playerInput: fields[0] as String,
      aiResponse: fields[1] as String,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StorySegment obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.playerInput)
      ..writeByte(1)
      ..write(obj.aiResponse)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorySegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AdventureAdapter extends TypeAdapter<Adventure> {
  @override
  final int typeId = 2;

  @override
  Adventure read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Adventure(
      id: fields[0] as String,
      characterId: fields[1] as String,
      title: fields[2] as String,
      storyHistory: (fields[3] as List).cast<StorySegment>(),
      createdAt: fields[4] as DateTime,
      lastPlayedAt: fields[5] as DateTime,
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Adventure obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.characterId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.storyHistory)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastPlayedAt)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdventureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
