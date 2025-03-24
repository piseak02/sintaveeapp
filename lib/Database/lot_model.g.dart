// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LotModelAdapter extends TypeAdapter<LotModel> {
  @override
  final int typeId = 4;

  @override
  LotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LotModel(
      lotId: fields[0] as String,
      productId: fields[1] as String,
      quantity: fields[2] as int,
      expiryDate: fields[3] as DateTime,
      recordDate: fields[4] as DateTime,
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LotModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.lotId)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.expiryDate)
      ..writeByte(4)
      ..write(obj.recordDate)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
