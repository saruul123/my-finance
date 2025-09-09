// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 5;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      defaultExportFormat: fields[1] as FileFormat,
      exportFolderPath: fields[2] as String,
      fileNamingScheme: fields[3] as String,
      autoBackupEnabled: fields[4] as bool,
      reminderDaysBefore: fields[5] as int,
      notificationsEnabled: fields[6] as bool,
      appLockEnabled: fields[7] as bool,
      googleDriveFolderId: fields[8] as String,
      lastSyncDate: fields[9] as DateTime,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(11)
      ..writeByte(1)
      ..write(obj.defaultExportFormat)
      ..writeByte(2)
      ..write(obj.exportFolderPath)
      ..writeByte(3)
      ..write(obj.fileNamingScheme)
      ..writeByte(4)
      ..write(obj.autoBackupEnabled)
      ..writeByte(5)
      ..write(obj.reminderDaysBefore)
      ..writeByte(6)
      ..write(obj.notificationsEnabled)
      ..writeByte(7)
      ..write(obj.appLockEnabled)
      ..writeByte(8)
      ..write(obj.googleDriveFolderId)
      ..writeByte(9)
      ..write(obj.lastSyncDate)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FileFormatAdapter extends TypeAdapter<FileFormat> {
  @override
  final int typeId = 4;

  @override
  FileFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FileFormat.csv;
      case 1:
        return FileFormat.json;
      case 2:
        return FileFormat.excel;
      default:
        return FileFormat.csv;
    }
  }

  @override
  void write(BinaryWriter writer, FileFormat obj) {
    switch (obj) {
      case FileFormat.csv:
        writer.writeByte(0);
        break;
      case FileFormat.json:
        writer.writeByte(1);
        break;
      case FileFormat.excel:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
