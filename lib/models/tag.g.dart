// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagAdapter extends TypeAdapter<Tag> {
  @override
  final int typeId = 12;

  @override
  Tag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tag(
      id: fields[0] as String,
      name: fields[1] as String,
      group: fields[2] as TagGroup,
      keywords: (fields[3] as List).cast<String>(),
      isEnabled: fields[4] as bool,
      caseSensitive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Tag obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.group)
      ..writeByte(3)
      ..write(obj.keywords)
      ..writeByte(4)
      ..write(obj.isEnabled)
      ..writeByte(5)
      ..write(obj.caseSensitive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TagGroupAdapter extends TypeAdapter<TagGroup> {
  @override
  final int typeId = 11;

  @override
  TagGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TagGroup.needs;
      case 1:
        return TagGroup.wants;
      case 2:
        return TagGroup.loans;
      case 3:
        return TagGroup.interest;
      default:
        return TagGroup.needs;
    }
  }

  @override
  void write(BinaryWriter writer, TagGroup obj) {
    switch (obj) {
      case TagGroup.needs:
        writer.writeByte(0);
        break;
      case TagGroup.wants:
        writer.writeByte(1);
        break;
      case TagGroup.loans:
        writer.writeByte(2);
        break;
      case TagGroup.interest:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
