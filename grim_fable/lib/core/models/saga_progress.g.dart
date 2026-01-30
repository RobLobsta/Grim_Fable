// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saga_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SagaProgressAdapter extends TypeAdapter<SagaProgress> {
  @override
  final int typeId = 3;

  @override
  SagaProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SagaProgress(
      sagaId: fields[0] as String,
      currentChapterIndex: fields[1] as int,
      completedChapterIds: (fields[2] as List).cast<String>(),
      witnessedAnchors: (fields[3] as List).cast<String>(),
      adventureId: fields[4] as String,
      mechanicsState: (fields[5] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SagaProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.sagaId)
      ..writeByte(1)
      ..write(obj.currentChapterIndex)
      ..writeByte(2)
      ..write(obj.completedChapterIds)
      ..writeByte(3)
      ..write(obj.witnessedAnchors)
      ..writeByte(4)
      ..write(obj.adventureId)
      ..writeByte(5)
      ..write(obj.mechanicsState);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SagaProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
