// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorization_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategorizationRuleAdapter extends TypeAdapter<CategorizationRule> {
  @override
  final int typeId = 10;

  @override
  CategorizationRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategorizationRule(
      id: fields[0] as String,
      name: fields[1] as String,
      keywords: (fields[2] as List).cast<String>(),
      category: fields[3] as String,
      isEnabled: fields[4] as bool,
      caseSensitive: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CategorizationRule obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.keywords)
      ..writeByte(3)
      ..write(obj.category)
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
      other is CategorizationRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
