// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_name_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SupplierNameModelAdapter extends TypeAdapter<SupplierNameModel> {
  @override
  final int typeId = 6;

  @override
  SupplierNameModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SupplierNameModel(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SupplierNameModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierNameModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
