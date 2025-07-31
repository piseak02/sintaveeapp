import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/StandaloneBarcode/barcode_label_widget.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'standalone_label_model.dart';
import 'standalone_print_preview.dart';
import 'package:hive_flutter/hive_flutter.dart'; // [ปรับปรุง] Import Hive เพื่อใช้เก็บตัวนับ

class StandaloneBarcodePage extends StatefulWidget {
  const StandaloneBarcodePage({Key? key}) : super(key: key);

  @override
  _StandaloneBarcodePageState createState() => _StandaloneBarcodePageState();
}

class _StandaloneBarcodePageState extends State<StandaloneBarcodePage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  // [ปรับปรุง] เอา Controller ของ barcode ออกไป
  // final _barcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<StandaloneLabel> _printQueue = [];
  final Map<String, ScreenshotController> _screenshotControllers = {};

  int _selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// [ปรับปรุง] ฟังก์ชันเพิ่มฉลาก พร้อมสร้างบาร์โค้ดอัตโนมัติ
  Future<void> _addToQueue() async {
    if (_formKey.currentState!.validate()) {
      // 1. เปิดกล่อง 'settings' เพื่ออ่านและบันทึกตัวนับ
      final settingsBox = await Hive.openBox('settings');
      int barcodeCounter =
          settingsBox.get('standaloneBarcodeCounter', defaultValue: 0);

      // 2. สร้างบาร์โค้ดใหม่ที่ไม่ซ้ำกัน
      barcodeCounter++;
      final String newBarcode =
          "STV-${barcodeCounter.toString().padLeft(8, '0')}";

      // 3. บันทึกค่า counter ล่าสุดกลับลง Hive
      await settingsBox.put('standaloneBarcodeCounter', barcodeCounter);

      setState(() {
        final newLabel = StandaloneLabel(
          name: _nameController.text,
          price: _priceController.text,
          barcode: newBarcode, // ใช้บาร์โค้ดที่ระบบสร้างขึ้น
        );
        _printQueue.add(newLabel);
        _screenshotControllers[newLabel.id] = ScreenshotController();

        // เคลียร์ฟอร์ม
        _nameController.clear();
        _priceController.clear();
        FocusScope.of(context).unfocus();
      });
    }
  }

  Future<void> _saveToGallery(String labelId) async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      final controller = _screenshotControllers[labelId];
      if (controller == null) return;

      final Uint8List? imageBytes = await controller.capture(pixelRatio: 3.0);
      if (imageBytes == null) return;

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: "barcode-$labelId",
      );

      if (mounted && result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกภาพลงแกลเลอรีสำเร็จ!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอนุญาตสิทธิ์เพื่อบันทึกภาพ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TPrimaryHeaderContainer(
            child: Center(
              child: Text(
                'เครื่องมือสร้างฉลาก',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                    validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'ราคาขายปลีก'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'กรุณากรอกราคา' : null,
                  ),
                  // [ปรับปรุง] เอา TextFormField สำหรับ barcode ออก
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addToQueue,
                    child: const Text('เพิ่มฉลากลงในคิวพิมพ์'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const Text('รายการในคิวพิมพ์',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: _printQueue.isEmpty
                ? const Center(child: Text('ยังไม่มีฉลากในคิว'))
                : ListView.builder(
                    itemCount: _printQueue.length,
                    itemBuilder: (context, index) {
                      final label = _printQueue[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Screenshot(
                            controller: _screenshotControllers[label.id]!,
                            child: BarcodeLabelWidget(
                              name: label.name,
                              price: label.price,
                              barcode: label.barcode,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.save_alt,
                                    color: Colors.blue),
                                tooltip: 'บันทึกลงแกลเลอรี',
                                onPressed: () => _saveToGallery(label.id),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() {
                                  _printQueue.removeAt(index);
                                  _screenshotControllers.remove(label.id);
                                }),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_printQueue.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กรุณาเพิ่มฉลากก่อนพิมพ์')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => StandalonePrintPreview(labels: _printQueue)),
          );
        },
        label: const Text('พิมพ์ทั้งหมด (A4)'),
        icon: const Icon(Icons.print),
        backgroundColor: Colors.orange,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
