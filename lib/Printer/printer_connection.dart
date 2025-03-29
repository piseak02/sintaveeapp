import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/Database/printer_connection_model.dart';


class PrinterConnectionPage extends StatefulWidget {
  const PrinterConnectionPage({Key? key}) : super(key: key);

  @override
  _PrinterConnectionPageState createState() => _PrinterConnectionPageState();
}

class _PrinterConnectionPageState extends State<PrinterConnectionPage> {
  // รายการเครื่องปริ้นที่โหลดมาจาก Hive
  List<PrinterConnectionModel> _printerList = [];
  bool _isConnecting = false;
  String _statusMessage = "";

  // Hive Box สำหรับเก็บ PrinterConnectionModel
  late Box<PrinterConnectionModel> printerBox;

  @override
  void initState() {
    super.initState();
    _openBoxAndLoadPrinters();
  }

  Future<void> _openBoxAndLoadPrinters() async {
    printerBox = Hive.box<PrinterConnectionModel>('printerBox');
    _loadPrinters();
  }

  void _loadPrinters() {
    setState(() {
      _printerList = printerBox.values.toList();
    });
  }

  /// แสดง Dialog สำหรับเพิ่มเครื่องปริ้นใหม่
  Future<void> _showAddPrinterDialog() async {
    final _printerNameController = TextEditingController();
    final _ipController = TextEditingController();
    final _portController = TextEditingController(text: "9100");

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("เพิ่มเครื่องปริ้น"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _printerNameController,
                  decoration: InputDecoration(labelText: "ชื่อเครื่องปริ้น"),
                ),
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(labelText: "IP Address"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _portController,
                  decoration:
                      InputDecoration(labelText: "Port (ค่าเริ่มต้น 9100)"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () {
                String name = _printerNameController.text.trim();
                String ip = _ipController.text.trim();
                int port = int.tryParse(_portController.text) ?? 9100;
                if (name.isNotEmpty && ip.isNotEmpty) {
                  final newPrinter = PrinterConnectionModel(
                    printerName: name,
                    ipAddress: ip,
                    port: port,
                  );
                  // บันทึกข้อมูลลงใน Hive
                  printerBox.add(newPrinter);
                  setState(() {
                    _printerList.add(newPrinter);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text("เพิ่ม"),
            ),
          ],
        );
      },
    );
  }

  /// ฟังก์ชันเชื่อมต่อกับเครื่องปริ้นที่เลือก
  Future<void> _connectToPrinter(PrinterConnectionModel printer) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = "กำลังเชื่อมต่อกับ ${printer.printerName}...";
    });
    try {
      Socket socket = await Socket.connect(printer.ipAddress, printer.port,
          timeout: const Duration(seconds: 5));
      // เมื่อเชื่อมต่อสำเร็จ ให้ปรับปรุงสถานะของเครื่องปริ้น
      final updatedPrinter = printer.copyWith(
        isConnected: true,
        lastConnectedTime: DateTime.now(),
      );
      // อัปเดตข้อมูลใน Hive Box ตาม index
      int index = _printerList.indexOf(printer);
      if (index != -1) {
        printerBox.putAt(index, updatedPrinter);
        setState(() {
          _printerList[index] = updatedPrinter;
          _statusMessage = "เชื่อมต่อ ${printer.printerName} สำเร็จ!";
        });
      }
      // ส่งคำสั่ง initialize (ESC @)
      List<int> initCmd = [27, 64];
      socket.add(initCmd);
      await socket.flush();
      socket.destroy();
    } catch (e) {
      setState(() {
        _statusMessage = "เชื่อมต่อ ${printer.printerName} ไม่สำเร็จ: $e";
      });
    }
    setState(() {
      _isConnecting = false;
    });
  }

  /// ฟังก์ชันทดลองปริ้นสำหรับเครื่องปริ้นที่เลือก
  Future<void> _testPrint(PrinterConnectionModel printer) async {
    if (!printer.isConnected) {
      setState(() {
        _statusMessage =
            "เครื่องปริ้น ${printer.printerName} ยังไม่ได้เชื่อมต่อ";
      });
      return;
    }
    try {
      Socket socket = await Socket.connect(printer.ipAddress, printer.port,
          timeout: const Duration(seconds: 5));
      // ส่งคำสั่ง initialize
      List<int> initCmd = [27, 64];
      socket.add(initCmd);
      // ส่งข้อความทดสอบ
      String testMessage = "ทดลองปริ้นจากแอป\n\n";
      socket.add(utf8.encode(testMessage));
      // ส่งคำสั่งตัดกระดาษ (GS V B 0)
      List<int> cutCmd = [29, 86, 66, 0];
      socket.add(cutCmd);
      await socket.flush();
      socket.destroy();
      setState(() {
        _statusMessage = "ส่งคำสั่งปริ้นของ ${printer.printerName} สำเร็จ!";
      });
    } catch (e) {
      setState(() {
        _statusMessage =
            "การส่งคำสั่งปริ้นของ ${printer.printerName} ล้มเหลว: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("เครื่องปริ้นที่เพิ่ม"),
      ),
      body: Column(
        children: [
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _printerList.isEmpty
                ? Center(child: Text("ยังไม่มีเครื่องปริ้นที่เพิ่ม"))
                : ListView.builder(
                    itemCount: _printerList.length,
                    itemBuilder: (context, index) {
                      final printer = _printerList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(printer.printerName),
                          subtitle:
                              Text("${printer.ipAddress}:${printer.port}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.wifi),
                                onPressed: () => _connectToPrinter(printer),
                                tooltip: "เชื่อมต่อ",
                              ),
                              IconButton(
                                icon: Icon(Icons.print),
                                onPressed: () => _testPrint(printer),
                                tooltip: "ทดลองปริ้น",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPrinterDialog,
        child: Icon(Icons.add),
        tooltip: "เพิ่มเครื่องปริ้น",
      ),
    );
  }
}
