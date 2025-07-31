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
  final TextEditingController _footerLine1Controller = TextEditingController();
  final TextEditingController _footerLine2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // โหลดค่าที่เคยบันทึกไว้
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('bill_logo_path');
    if (logoPath != null) {
      setState(() {
        _logoFile = File(logoPath);
      });
    }
    _footerLine1Controller.text = prefs.getString('bill_footer_line1') ??
        "เวลาทำการ: เปิดทุกวัน 04.00 - 18.00";
    _footerLine2Controller.text =
        prefs.getString('bill_footer_line2') ?? "ขอบคุณที่ใช้บริการ";
  }

  // เลือกรูปภาพ
  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  // [แก้ไข] 2. ฟังก์ชันสำหรับลบโลโก้
  Future<void> _deleteLogo() async {
    // แสดงกล่องข้อความเพื่อยืนยันการลบ
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

    // ถ้าผู้ใช้ยืนยันการลบ
    if (confirmDelete == true) {
      setState(() {
        _logoFile = null; // ทำให้รูปที่แสดงผลหายไป
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bill_logo_path'); // ลบ path ออกจาก SharedPreferences
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบรูปภาพสำเร็จ")),
      );
    }
  }

  // บันทึกการตั้งค่า
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // [แก้ไข] 3. ตรวจสอบว่า _logoFile ยังมีค่าอยู่หรือไม่ก่อนบันทึก
    if (_logoFile != null) {
      await prefs.setString('bill_logo_path', _logoFile!.path);
    } else {
      // ถ้า _logoFile เป็น null (ถูกลบไปแล้ว) ให้ลบ path ออกจาก SharedPreferences ด้วย
      await prefs.remove('bill_logo_path');
    }

    await prefs.setString('bill_footer_line1', _footerLine1Controller.text);
    await prefs.setString('bill_footer_line2', _footerLine2Controller.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("บันทึกการตั้งค่าสำเร็จ!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตั้งค่าใบเสร็จ"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("โลโก้บนหัวบิล",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: _logoFile != null
                  ? Image.file(_logoFile!, height: 150)
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
                // [แก้ไข] 1. เพิ่มปุ่มลบรูปภาพ จะแสดงก็ต่อเมื่อมีรูปภาพอยู่แล้ว
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
