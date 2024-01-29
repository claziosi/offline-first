// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_storage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FormDataAdapter extends TypeAdapter<FormData> {
  @override
  final int typeId = 0;

  @override
  FormData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FormData()
      ..field1 = fields[0] as String
      ..field2 = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, FormData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.field1)
      ..writeByte(1)
      ..write(obj.field2);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
