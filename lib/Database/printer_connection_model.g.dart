// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_connection_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrinterConnectionModelAdapter
    extends TypeAdapter<PrinterConnectionModel> {
  @override
  final int typeId = 7;

  @override
  PrinterConnectionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterConnectionModel(
      printerName: fields[0] as String,
      ipAddress: fields[1] as String,
      port: fields[2] as int,
      isConnected: fields[3] as bool,
      lastConnectedTime: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PrinterConnectionModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.printerName)
      ..writeByte(1)
      ..write(obj.ipAddress)
      ..writeByte(2)
      ..write(obj.port)
      ..writeByte(3)
      ..write(obj.isConnected)
      ..writeByte(4)
      ..write(obj.lastConnectedTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterConnectionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
