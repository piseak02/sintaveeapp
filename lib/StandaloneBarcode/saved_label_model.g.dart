// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_label_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedLabelModelAdapter extends TypeAdapter<SavedLabelModel> {
  @override
  final int typeId = 8;

  @override
  SavedLabelModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedLabelModel()
      ..name = fields[0] as String
      ..price = fields[1] as String
      ..barcode = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, SavedLabelModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.barcode)
      ..writeByte(3)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLabelModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
