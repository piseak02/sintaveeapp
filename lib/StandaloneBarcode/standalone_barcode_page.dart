import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/StandaloneBarcode/barcode_label_widget.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
// [แก้ไข] เปลี่ยนมาใช้ image_gallery_saver_plus
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'standalone_label_model.dart';
import 'standalone_print_preview.dart';
import 'saved_label_model.dart';
import 'package:device_info_plus/device_info_plus.dart';


class StandaloneBarcodePage extends StatefulWidget {
  const StandaloneBarcodePage({Key? key}) : super(key: key);

  @override
  _StandaloneBarcodePageState createState() => _StandaloneBarcodePageState();
}

class _StandaloneBarcodePageState extends State<StandaloneBarcodePage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<StandaloneLabel> _printQueue = [];
  final Map<String, ScreenshotController> _screenshotControllers = {};
  int _selectedIndex = 0;

  final Box<SavedLabelModel> _savedLabelsBox =
      Hive.box<SavedLabelModel>('saved_labels');

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _addToQueue() async {
    if (_formKey.currentState!.validate()) {
      final settingsBox = await Hive.openBox('settings');
      int counter =
          settingsBox.get('standaloneBarcodeCounter', defaultValue: 0);
      counter++;
      final String newBarcode = "STV-${counter.toString().padLeft(8, '0')}";
      await settingsBox.put('standaloneBarcodeCounter', counter);

      setState(() {
        final newLabel = StandaloneLabel(
          name: _nameController.text,
          price: _priceController.text,
          barcode: newBarcode,
        );
        _printQueue.add(newLabel);
        _screenshotControllers[newLabel.id] = ScreenshotController();
        _nameController.clear();
        _priceController.clear();
        FocusScope.of(context).unfocus();
      });
    }
  }

  Future<void> _saveQueueToHive() async {
    if (_printQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่มีฉลากในคิวให้บันทึก')));
      return;
    }
    for (final label in _printQueue) {
      final newSavedLabel = SavedLabelModel()
        ..name = label.name
        ..price = label.price
        ..barcode = label.barcode;
      await _savedLabelsBox.put(newSavedLabel.id, newSavedLabel);
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกฉลากทั้งหมดลงในสมุดแล้ว!')));
    setState(() {
      _printQueue.clear();
      _screenshotControllers.clear();
    });
  }

  void _loadLabelToQueue(SavedLabelModel savedLabel) {
    if (_printQueue.any((label) => label.barcode == savedLabel.barcode)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${savedLabel.name}" อยู่ในคิวแล้ว')));
      return;
    }

    setState(() {
      final newLabel = StandaloneLabel(
        name: savedLabel.name,
        price: savedLabel.price,
        barcode: savedLabel.barcode,
      );
      _printQueue.add(newLabel);
      _screenshotControllers[newLabel.id] = ScreenshotController();
    });
    Navigator.of(context).pop();
  }

  void _showSavedLabelsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('สมุดบันทึกฉลาก',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _savedLabelsBox.listenable(),
                    builder: (context, Box<SavedLabelModel> box, _) {
                      if (box.values.isEmpty) {
                        return const Center(
                            child: Text('สมุดบันทึกยังว่างอยู่'));
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final savedLabel = box.getAt(index)!;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(savedLabel.name),
                              subtitle: Text("บาร์โค้ด: ${savedLabel.barcode}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_forever,
                                    color: Colors.red),
                                onPressed: () => savedLabel.delete(),
                              ),
                              onTap: () => _loadLabelToQueue(savedLabel),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveToGallery(String labelId) async {
    // [แก้ไข] เปลี่ยนมาขอสิทธิ์สำหรับรูปภาพโดยเฉพาะสำหรับ Android 13+
    // และขอสิทธิ์ storage สำหรับเวอร์ชันเก่า
    final PermissionStatus status;
    if (await DeviceInfoPlugin()
            .androidInfo
            .then((info) => info.version.sdkInt) >=
        33) {
      status = await Permission.photos.request();
    } else {
      status = await Permission.storage.request();
    }

    // [ปรับปรุง] เพิ่มการตรวจสอบกรณีผู้ใช้ปฏิเสธสิทธิ์ถาวร
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'คุณได้ปฏิเสธสิทธิ์การเข้าถึงรูปภาพอย่างถาวร กรุณาไปที่การตั้งค่าเพื่อเปิดใช้งาน'),
            action: SnackBarAction(
              label: 'เปิดตั้งค่า',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return;
    }

    if (status.isGranted) {
      final controller = _screenshotControllers[labelId];
      if (controller == null) return;
      final Uint8List? imageBytes = await controller.capture(pixelRatio: 3.0);
      if (imageBytes == null) return;

      final result = await ImageGallerySaverPlus.saveImage(imageBytes,
          quality: 100, name: "barcode-$labelId");

      if (mounted && result != null && result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกภาพลงแกลเลอรีสำเร็จ!')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ')));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตสิทธิ์เพื่อบันทึกภาพ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const TPrimaryHeaderContainer(
              child: Center(
                child: Text('เครื่องมือสร้างฉลาก',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
                      decoration:
                          const InputDecoration(labelText: 'ชื่อสินค้า'),
                      validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration:
                          const InputDecoration(labelText: 'ราคาขายปลีก'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'กรุณากรอกราคา' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addToQueue,
                      child: const Text('เพิ่มฉลาก'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ฉลากล่าสุด',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('ในคิวทั้งหมด: ${_printQueue.length} รายการ',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _printQueue.isEmpty
                  ? const Center(child: Text('ยังไม่มีฉลากในคิว'))
                  : Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListTile(
                        title: Screenshot(
                          controller:
                              _screenshotControllers[_printQueue.last.id]!,
                          child: BarcodeLabelWidget(
                            name: _printQueue.last.name,
                            price: _printQueue.last.price,
                            barcode: _printQueue.last.barcode,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.save_alt,
                                  color: Colors.blue),
                              tooltip: 'บันทึกลงแกลเลอรี',
                              onPressed: () =>
                                  _saveToGallery(_printQueue.last.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() {
                                _screenshotControllers
                                    .remove(_printQueue.last.id);
                                _printQueue.removeLast();
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const Divider(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.book_outlined, color: Colors.green),
                      label: const Text('เปิดสมุดบันทึก',
                          style: TextStyle(color: Colors.green)),
                      onPressed: _showSavedLabelsDialog,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.save_outlined, color: Colors.blue),
                      label: const Text('บันทึกคิวทั้งหมด',
                          style: TextStyle(color: Colors.blue)),
                      onPressed: _saveQueueToHive,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final List<SavedLabelModel> allSavedLabels =
              _savedLabelsBox.values.toList();

          if (allSavedLabels.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('ยังไม่มีฉลากที่บันทึกไว้ในสมุด')));
            return;
          }

          final List<StandaloneLabel> labelsToPrint =
              allSavedLabels.map((saved) {
            return StandaloneLabel(
                name: saved.name, price: saved.price, barcode: saved.barcode);
          }).toList();

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      StandalonePrintPreview(labels: labelsToPrint)));
        },
        label: const Text('พิมพ์จากสมุดบันทึก'),
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
