import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- [แก้ไข] เปลี่ยน import มาใช้ package ตัวใหม่ ---
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
// เพิ่ม import สำหรับ SocketException

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({Key? key}) : super(key: key);

  @override
  _PrinterSettingsPageState createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  bool _autoCutPaper = true;
  bool _isSaving = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('printer_ip') ?? '';
      _autoCutPaper = prefs.getBool('auto_cut_paper') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_ip', _ipController.text.trim());
    await prefs.setBool('auto_cut_paper', _autoCutPaper);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('บันทึกการตั้งค่าเรียบร้อยแล้ว'),
            backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _testPrint() async {
    final printerIp = _ipController.text.trim();
    if (printerIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('กรุณากรอก IP Address ก่อนทดสอบ'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isTesting = true);
    await _saveSettings();

    try {
      const PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paper, profile);
      final PosPrintResult res = await printer.connect(printerIp,
          port: 9100, timeout: const Duration(seconds: 10));

      if (res == PosPrintResult.success) {
        printer.text('Test Print Success!',
            styles: const PosStyles(
                align: PosAlign.center, bold: true, height: PosTextSize.size2));
        printer.text('IP: $printerIp',
            styles: const PosStyles(align: PosAlign.center));
        printer.feed(2);
        if (_autoCutPaper) {
          printer.cut();
        }
        printer.disconnect();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ส่งข้อมูลทดสอบไปที่เครื่องพิมพ์แล้ว'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('เชื่อมต่อไม่สำเร็จ: ${res.msg}'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าเครื่องพิมพ์ใบเสร็จ'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('การเชื่อมต่อ (Network/WiFi)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP Address เครื่องพิมพ์',
              border: OutlineInputBorder(),
              hintText: 'เช่น 192.168.1.100',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text('การตั้งค่ากระดาษ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('ตัดกระดาษอัตโนมัติ'),
            subtitle: const Text('สั่งตัดกระดาษหลังพิมพ์เสร็จ'),
            value: _autoCutPaper,
            onChanged: (bool value) {
              setState(() {
                _autoCutPaper = value;
              });
            },
          ),
          const Divider(height: 40),
          if (_isTesting)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton.icon(
              onPressed: _testPrint,
              icon: const Icon(Icons.print_outlined),
              label: const Text('ทดสอบการพิมพ์'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          const SizedBox(height: 16),
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกการตั้งค่า'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
        ],
      ),
    );
  }
}
