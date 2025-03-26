import 'dart:typed_data';
import 'package:flutter/material.dart';
// สำหรับ PdfPageFormat
import 'package:pdf/pdf.dart';
// สำหรับสร้าง PDF
import 'package:pdf/widgets.dart' as pw;
// สำหรับแสดง PDF Preview และสั่งพิมพ์
import 'package:printing/printing.dart';
import 'package:flutter/services.dart'
    show rootBundle; // สำหรับโหลดฟอนต์จาก assets

import '../Database/bill_model.dart'; // ไฟล์ Model บิล

// เปลี่ยน BillDetailPage เป็น StatefulWidget เพื่อให้สามารถเลือกขนาดหน้ากระดาษได้
class BillDetailPage extends StatefulWidget {
  final BillModel bill;

  const BillDetailPage({Key? key, required this.bill}) : super(key: key);

  @override
  _BillDetailPageState createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  // กำหนดตัวเลือกสำหรับขนาดหน้ากระดาษ
  late PdfPageFormat _selectedFormat;
  final List<Map<String, dynamic>> _formats = [
    {
      'label': 'A4',
      'format': PdfPageFormat.a4,
    },
    {
      'label': 'Custom (80 x 210 มม.)',
      'format': PdfPageFormat(80 * PdfPageFormat.mm, 210 * PdfPageFormat.mm,
          marginAll: 10),
    },
    {
      'label': 'Custom (58 x 210 มม.)',
      'format': PdfPageFormat(58 * PdfPageFormat.mm, 210 * PdfPageFormat.mm,
          marginAll: 10),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedFormat = PdfPageFormat.a4; // ค่าเริ่มต้นเป็น A4
  }

  // ฟังก์ชันสำหรับสร้าง PDF จากข้อมูลบิล
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();

    // โหลดฟอนต์ไทยจาก assets
    final fontData = await rootBundle.load("assets/fonts/THSarabun.ttf");
    final fontThai = pw.Font.ttf(fontData.buffer.asByteData());
    final logoBytes =
        (await rootBundle.load('assets/logo1.png')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // โลโก้หัวบิล (ขนาดเล็ก)
              pw.Center(
                child: pw.Image(logoImage, width: 100, height: 100),
              ),
              pw.SizedBox(height: 10),
              pw.SizedBox(height: 10),
              pw.Text("บิลเลขที่: ${widget.bill.billId}",
                  style: pw.TextStyle(font: fontThai, fontSize: 12)),
              pw.Text("วันที่: ${widget.bill.billDate.toLocal()}",
                  style: pw.TextStyle(font: fontThai, fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Text("รายการสินค้า:",
                  style: pw.TextStyle(
                      font: fontThai,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...widget.bill.items.map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.productName,
                        style: pw.TextStyle(
                            font: fontThai,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        "ราคา: ${item.price} x ${item.quantity}",
                        style: pw.TextStyle(font: fontThai, fontSize: 12)),
                    pw.Text(
                        "ส่วนลด: ${item.discount}",
                        style: pw.TextStyle(font: fontThai, fontSize: 12)),
                    pw.Text("รวม: ${item.itemNetTotal} บาท",
                        style: pw.TextStyle(
                            font: fontThai, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                  ],
                );
              }).toList(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("รวมสุทธิ:",
                      style: pw.TextStyle(
                          font: fontThai, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${widget.bill.netTotal} บาท",
                      style: pw.TextStyle(font: fontThai)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("รับเงิน:", style: pw.TextStyle(font: fontThai)),
                  pw.Text("${widget.bill.moneyReceived} บาท",
                      style: pw.TextStyle(font: fontThai)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ทอน:", style: pw.TextStyle(font: fontThai)),
                  pw.Text("${widget.bill.change} บาท",
                      style: pw.TextStyle(font: fontThai)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              // Footer จัดกลาง
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("เวลาทำการ: เปิดทุกวัน 04.00 - 18.00",
                        style: pw.TextStyle(font: fontThai)),
                    pw.Text("ขอบคุณที่ใช้บริการ",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียดบิล: ${widget.bill.billId}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("รหัสบิล: ${widget.bill.billId}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
                "วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("ยอดรวมสุทธิ: ${widget.bill.netTotal.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
                "เงินที่รับ: ${widget.bill.moneyReceived.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("เงินทอน: ${widget.bill.change.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text("รายการสินค้า:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            ...widget.bill.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      "ราคา: ${item.price.toStringAsFixed(2)} บาท  x  ${item.quantity}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "ส่วนลด: ${item.discount.toStringAsFixed(2)} บาท",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "รวม: ${item.itemNetTotal.toStringAsFixed(2)} บาท",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            // Dropdown สำหรับเลือกขนาดหน้ากระดาษ
            Row(
              children: [
                const Text("เลือกขนาดหน้ากระดาษ: ",
                    style: TextStyle(fontSize: 16)),
                DropdownButton<PdfPageFormat>(
                  value: _selectedFormat,
                  items: _formats.map((formatData) {
                    return DropdownMenuItem<PdfPageFormat>(
                      value: formatData['format'],
                      child: Text(formatData['label']),
                    );
                  }).toList(),
                  onChanged: (newFormat) {
                    setState(() {
                      _selectedFormat = newFormat!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ปุ่มแสดง PDF Preview
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // เปิดหน้าแสดงตัวอย่าง PDF โดยใช้ขนาดหน้าที่เลือก
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewPage(
                        buildPdf: (format) => _generatePdf(_selectedFormat),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("แสดงตัวอย่าง/พิมพ์บิล"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// หน้าที่ใช้แสดงตัวอย่าง PDF Preview
class PdfPreviewPage extends StatelessWidget {
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  const PdfPreviewPage({Key? key, required this.buildPdf}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตัวอย่าง PDF"),
      ),
      body: PdfPreview(
        build: (format) => buildPdf(format),
        pdfFileName: "bill.pdf",
      ),
    );
  }
}
