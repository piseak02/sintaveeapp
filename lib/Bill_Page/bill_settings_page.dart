import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillSettingsPage extends StatefulWidget {
  const BillSettingsPage({Key? key}) : super(key: key);

  @override
  _BillSettingsPageState createState() => _BillSettingsPageState();
}

class _BillSettingsPageState extends State<BillSettingsPage> {
  final ImagePicker _picker = ImagePicker();
  File? _logoFile;

  // Controllers for store information
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _footerLine1Controller = TextEditingController();
  final TextEditingController _footerLine2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('bill_logo_path');
    if (logoPath != null) {
      setState(() {
        _logoFile = File(logoPath);
      });
    }
    // Load store information
    _shopNameController.text =
        prefs.getString('bill_shop_name') ?? 'ร้านค้าตัวอย่าง';
    _addressController.text =
        prefs.getString('bill_address') ?? '123 ถนนตัวอย่าง ต.ตัวอย่าง อ.เมือง';
    _phoneController.text = prefs.getString('bill_phone') ?? '081-234-5678';
    _footerLine1Controller.text = prefs.getString('bill_footer_line1') ??
        "เวลาทำการ: เปิดทุกวัน 04.00 - 18.00";
    _footerLine2Controller.text =
        prefs.getString('bill_footer_line2') ?? "ขอบคุณที่ใช้บริการ";
  }

  /// Picks a logo from the gallery
  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  /// Deletes the current logo
  Future<void> _deleteLogo() async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณต้องการลบรูปภาพโลโก้ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("ลบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() {
        _logoFile = null;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bill_logo_path');

      // Check if the widget is still mounted before showing a SnackBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบรูปภาพสำเร็จ")),
      );
    }
  }

  /// Saves all settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_logoFile != null) {
      await prefs.setString('bill_logo_path', _logoFile!.path);
    } else {
      await prefs.remove('bill_logo_path');
    }

    // Save store information
    await prefs.setString('bill_shop_name', _shopNameController.text);
    await prefs.setString('bill_address', _addressController.text);
    await prefs.setString('bill_phone', _phoneController.text);
    await prefs.setString('bill_footer_line1', _footerLine1Controller.text);
    await prefs.setString('bill_footer_line2', _footerLine2Controller.text);

    // Check if the widget is still mounted before showing a SnackBar or popping the navigator
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("บันทึกการตั้งค่าสำเร็จ!")),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerLine1Controller.dispose();
    _footerLine2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตั้งค่าใบเสร็จ"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ข้อมูลร้านค้า (สำหรับใบเสร็จ)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: "ชื่อร้านค้า",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "ที่อยู่",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "เบอร์โทรศัพท์",
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 40),
            const Text("โลโก้บนหัวบิล",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: _logoFile != null
                  ? Image.file(_logoFile!, height: 150, fit: BoxFit.contain)
                  : Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text("ยังไม่มีโลโก้")),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.image),
                  label: const Text("เลือกโลโก้"),
                ),
                if (_logoFile != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: "ลบรูปภาพ",
                      onPressed: _deleteLogo,
                    ),
                  ),
              ],
            ),
            const Divider(height: 40),
            const Text("ข้อความท้ายบิล",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _footerLine1Controller,
              decoration: const InputDecoration(
                labelText: "บรรทัดที่ 1",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _footerLine2Controller,
              decoration: const InputDecoration(
                labelText: "บรรทัดที่ 2",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("บันทึกการตั้งค่า",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
