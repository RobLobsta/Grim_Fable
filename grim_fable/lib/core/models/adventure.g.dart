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
      recommendedChoices: (fields[3] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, StorySegment obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.playerInput)
      ..writeByte(1)
      ..write(obj.aiResponse)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.recommendedChoices);
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
      mainGoal: fields[7] == null ? '' : fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Adventure obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.mainGoal);
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
