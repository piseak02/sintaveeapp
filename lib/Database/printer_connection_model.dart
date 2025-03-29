import 'package:hive/hive.dart';

part 'printer_connection_model.g.dart';

@HiveType(typeId: 7)
class PrinterConnectionModel extends HiveObject {
  @HiveField(0)
  final String printerName; // ชื่อเครื่องปริ้น

  @HiveField(1)
  final String ipAddress;   // IP Address ของเครื่องปริ้น

  @HiveField(2)
  final int port;           // พอร์ตสำหรับเชื่อมต่อ

  @HiveField(3)
  final bool isConnected;   // สถานะการเชื่อมต่อ (เชื่อมต่อหรือไม่)

  @HiveField(4)
  final DateTime lastConnectedTime; // เวลาที่เชื่อมต่อครั้งล่าสุด

  PrinterConnectionModel({
    required this.printerName,
    required this.ipAddress,
    required this.port,
    this.isConnected = false,
    DateTime? lastConnectedTime,
  }) : lastConnectedTime = lastConnectedTime ?? DateTime.now();

  /// สร้างสำเนา model พร้อมปรับปรุง field ที่ต้องการ
  PrinterConnectionModel copyWith({
    String? printerName,
    String? ipAddress,
    int? port,
    bool? isConnected,
    DateTime? lastConnectedTime,
  }) {
    return PrinterConnectionModel(
      printerName: printerName ?? this.printerName,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      isConnected: isConnected ?? this.isConnected,
      lastConnectedTime: lastConnectedTime ?? this.lastConnectedTime,
    );
  }
}
