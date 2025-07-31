import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart'; // [แก้ไข] 1. เพิ่ม import สำหรับ SharedPreferences
import 'dart:io'; // [แก้ไข] 2. เพิ่ม import สำหรับการจัดการไฟล์

import '../Database/bill_model.dart'; // ไฟล์ Model บิล

class BillDetailPage extends StatefulWidget {
  final BillModel bill;

  const BillDetailPage({Key? key, required this.bill}) : super(key: key);

  @override
  _BillDetailPageState createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  late PdfPageFormat _selectedFormat;

  // ขนาดกระดาษที่เลือกได้
  final List<Map<String, dynamic>> _formats = [
    {
      'label': 'A4',
      'format': PdfPageFormat.a4,
    },
    {
      'label': 'Custom (80 x 210 มม.)',
      'format': PdfPageFormat(80 * PdfPageFormat.mm, 210 * PdfPageFormat.mm, marginAll: 10),
    },
    {
      'label': 'Custom (58 x 210 มม.)',
      'format': PdfPageFormat(58 * PdfPageFormat.mm, 210 * PdfPageFormat.mm, marginAll: 10),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedFormat = PdfPageFormat.a4; // ตั้งค่าเริ่มต้นเป็น A4
  }

  /// สร้าง PDF จาก BillModel
  ///
  /// สำหรับหน้ากระดาษ A4 เราใช้ MultiPage พร้อม header และ footer
  /// สำหรับหน้ากระดาษอื่น (สลิป) เราจะทำเป็นหน้าเดียวที่ต่อเนื่องกัน
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();

    // โหลดฟอนต์ไทย
    final fontData = await rootBundle.load("assets/fonts/THSarabun.ttf");
    final fontThai = pw.Font.ttf(fontData.buffer.asByteData());

    // [แก้ไข] 3. โหลดโลโก้และข้อความท้ายบิลแบบ Dynamic
    // ดึงค่าที่บันทึกไว้จาก SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('bill_logo_path');
    final footerLine1 = prefs.getString('bill_footer_line1') ?? "เวลาทำการ: เปิดทุกวัน 04.00 - 18.00";
    final footerLine2 = prefs.getString('bill_footer_line2') ?? "ขอบคุณที่ใช้บริการ";

    pw.MemoryImage? logoImage;
    // ตรวจสอบว่ามี path ของโลโก้ที่ผู้ใช้เลือกไว้หรือไม่
    if (logoPath != null && await File(logoPath).exists()) {
      // ถ้ามี ให้โหลดรูปจาก path นั้น
      final logoBytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(logoBytes);
    } else {
      // ถ้าไม่มี หรือหาไฟล์ไม่เจอ ให้ใช้โลโก้ตั้งต้นจาก assets
      final defaultLogoBytes = (await rootBundle.load('assets/logo1.png')).buffer.asUint8List();
      logoImage = pw.MemoryImage(defaultLogoBytes);
    }

    // คำนวณยอดรวมก่อนหักส่วนลด
    final double totalAmount = widget.bill.netTotal + widget.bill.totalDiscount;

    if (format == PdfPageFormat.a4) {
      // Layout สำหรับ A4 พร้อม header และ footer โดยแบ่งหน้าอัตโนมัติ (MultiPage)
      doc.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            // แสดงโลโก้เฉพาะหน้าแรก
            if (context.pageNumber == 1) {
              // [แก้ไข] 4. ใช้ logoImage ที่โหลดมาแบบ Dynamic
              return pw.Center(child: pw.Image(logoImage!, width: 150, height: 150));
            }
            return pw.Container();
          },
          footer: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: fontThai, fontSize: 10),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 20),
              pw.Text("บิลเลขที่: ${widget.bill.billId}", style: pw.TextStyle(font: fontThai, fontSize: 16)),
              pw.Text(
                "วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}",
                style: pw.TextStyle(font: fontThai, fontSize: 16),
              ),
              pw.Divider(),
              // ตารางรายการสินค้า (โค้ดส่วนนี้คงเดิม)
              pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("ลำดับ", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("ชื่อสินค้า", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("จำนวน", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("ราคาต่อหน่วย", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("จำนวนเงิน", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...List.generate(widget.bill.items.length, (index) {
                    final item = widget.bill.items[index];
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("${index + 1}", style: pw.TextStyle(font: fontThai, fontSize: 12)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(item.productName, style: pw.TextStyle(font: fontThai, fontSize: 12)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("${item.quantity}", style: pw.TextStyle(font: fontThai, fontSize: 12)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("${item.price.toStringAsFixed(2)}", style: pw.TextStyle(font: fontThai, fontSize: 12)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("${item.itemNetTotal.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              // สรุปยอด (โค้ดส่วนนี้คงเดิม)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ยอดรวมสุทธิ:", style: pw.TextStyle(font: fontThai, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${widget.bill.netTotal.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai, fontSize: 16)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("เงินที่รับ:", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${widget.bill.moneyReceived.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai, fontSize: 14)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("เงินทอน:", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${widget.bill.change.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Column(
                  children: [
                    // [แก้ไข] 5. ใช้ข้อความท้ายบิลที่โหลดมาแบบ Dynamic
                    pw.Text(footerLine1, style: pw.TextStyle(font: fontThai, fontSize: 14)),
                    pw.Text(footerLine2, style: pw.TextStyle(font: fontThai, fontSize: 14)),
                  ],
                ),
              ),
            ];
          },
        ),
      );
    } else {
      // สำหรับหน้ากระดาษที่ไม่ใช่ A4 (สลิป)
      final slipFormat = PdfPageFormat(format.width, 1000 * PdfPageFormat.mm, marginAll: 10);
      
      doc.addPage(
        pw.Page(
          pageFormat: slipFormat,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // [แก้ไข] 4. ใช้ logoImage ที่โหลดมาแบบ Dynamic
                pw.Center(child: pw.Image(logoImage!, width: 100, height: 100)),
                pw.SizedBox(height: 10),
                pw.Text("บิลเลขที่: ${widget.bill.billId}", style: pw.TextStyle(font: fontThai, fontSize: 12)),
                pw.Text("วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}", style: pw.TextStyle(font: fontThai, fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Text("รายการสินค้า:", style: pw.TextStyle(font: fontThai, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                // ...widget.bill.items.map (โค้ดส่วนนี้คงเดิม)
                 ...widget.bill.items.map((item) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.productName, style: pw.TextStyle(font: fontThai, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.SizedBox(height: 1),
                      pw.Text("ราคา: ${item.price.toStringAsFixed(2)} x ${item.quantity}", style: pw.TextStyle(font: fontThai, fontSize: 12)),
                      pw.Text("ส่วนลด: ${item.discount.toStringAsFixed(2)}", style: pw.TextStyle(font: fontThai, fontSize: 12)),
                      pw.Text("รวม: ${item.itemNetTotal.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Divider(),
                    ],
                  );
                }).toList(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("รวมทั้งสิ้น:", style: pw.TextStyle(font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${totalAmount.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ส่วนลดท้ายบิล:", style: pw.TextStyle(font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.totalDiscount.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ยอดรวมสุทธิ:", style: pw.TextStyle(font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.netTotal.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("เงินที่รับ:", style: pw.TextStyle(font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.moneyReceived.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("เงินทอน:", style: pw.TextStyle(font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.change.toStringAsFixed(2)} บาท", style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                 pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Column(
                    children: [
                      // [แก้ไข] 5. ใช้ข้อความท้ายบิลที่โหลดมาแบบ Dynamic
                      pw.Text(footerLine1, style: pw.TextStyle(font: fontThai, fontSize: 12)),
                      pw.Text(footerLine2, style: pw.TextStyle(font: fontThai, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = widget.bill.netTotal + widget.bill.totalDiscount;
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียดบิล: ${widget.bill.billId}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ใบเสร็จ: ${widget.bill.billId}"),
            const SizedBox(height: 8),
            Text(
              "วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text("รายการสินค้า:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            ...widget.bill.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            Text("รวมทั้งสิ้น: ${totalAmount.toStringAsFixed(2)} บาท", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text("ส่วนลดท้ายบิล: ${widget.bill.totalDiscount.toStringAsFixed(2)} บาท", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            const Divider(thickness: 1.0),
            const SizedBox(height: 4),
            Text("ยอดรวมสุทธิ: ${widget.bill.netTotal.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("เงินที่รับ: ${widget.bill.moneyReceived.toStringAsFixed(2)} บาท", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("เงินทอน: ${widget.bill.change.toStringAsFixed(2)} บาท", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("เลือกขนาดหน้ากระดาษ: ", style: TextStyle(fontSize: 16)),
                DropdownButton<PdfPageFormat>(
                  value: _selectedFormat,
                  items: _formats.map((formatData) {
                    return DropdownMenuItem<PdfPageFormat>(
                      value: formatData['format'],
                      child: Text(formatData['label']),
                    );
                  }).toList(),
                  onChanged: (newFormat) {
                    if (newFormat != null) {
                      setState(() {
                        _selectedFormat = newFormat;
                      });
                    }
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