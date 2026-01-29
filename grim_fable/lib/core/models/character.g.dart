// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CharacterAdapter extends TypeAdapter<Character> {
  @override
  final int typeId = 0;

  @override
  Character read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Character(
      id: fields[0] as String,
      name: fields[1] as String,
      backstory: fields[2] == null ? '' : fields[2] as String,
      createdAt: fields[3] as DateTime,
      lastPlayedAt: fields[4] as DateTime,
      inventory: fields[5] == null ? [] : (fields[5] as List).cast<String>(),
      cachedSuggestions:
          fields[6] == null ? [] : (fields[6] as List).cast<String>(),
      occupation: fields[7] == null ? '' : fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Character obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.backstory)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastPlayedAt)
      ..writeByte(5)
      ..write(obj.inventory)
      ..writeByte(6)
      ..write(obj.cachedSuggestions)
      ..writeByte(7)
      ..write(obj.occupation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
