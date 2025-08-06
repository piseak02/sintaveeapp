import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:screenshot/screenshot.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

import '../Database/bill_model.dart';
import 'receipt_widget.dart'; // import แม่แบบใบเสร็จ

class BillDetailPage extends StatefulWidget {
  final BillModel bill;

  const BillDetailPage({Key? key, required this.bill}) : super(key: key);

  @override
  _BillDetailPageState createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  final List<Map<String, dynamic>> _formats = [
    {'label': 'A4', 'format': PdfPageFormat.a4},
    {
      'label': 'Custom (80 x 210 มม.)',
      'format': PdfPageFormat(80 * PdfPageFormat.mm, 210 * PdfPageFormat.mm,
          marginAll: 10)
    },
    {
      'label': 'Custom (58 x 210 มม.)',
      'format': PdfPageFormat(58 * PdfPageFormat.mm, 210 * PdfPageFormat.mm,
          marginAll: 10)
    },
  ];
  late PdfPageFormat _selectedFormat = _formats.first['format'];

  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isWorking = false;

  /// [ปรับปรุง] ฟังก์ชันสร้าง PDF สำหรับ A4 ให้ดึงข้อมูลจาก SharedPreferences
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final fontData = await rootBundle.load("assets/fonts/THSarabun.ttf");
    final ttf = pw.Font.ttf(fontData);

    // --- [แก้ไข] ดึงข้อมูลร้านค้าและข้อความท้ายบิลจาก SharedPreferences ---
    final prefs = await SharedPreferences.getInstance();
    final shopName = prefs.getString('bill_shop_name') ?? 'ร้านค้าตัวอย่าง';
    final address =
        prefs.getString('bill_address') ?? '123 ถนนตัวอย่าง ต.ตัวอย่าง อ.เมือง';
    final phone = prefs.getString('bill_phone') ?? '081-234-5678';
    final logoPath = prefs.getString('bill_logo_path');
    final footerLine1 = prefs.getString('bill_footer_line1') ??
        "เวลาทำการ: เปิดทุกวัน 04.00 - 18.00";
    final footerLine2 =
        prefs.getString('bill_footer_line2') ?? "ขอบคุณที่ใช้บริการ";

    pw.ImageProvider? logoImage;
    if (logoPath != null && await File(logoPath).exists()) {
      final fileBytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(fileBytes);
    } else {
      final defaultLogoBytes =
          (await rootBundle.load('assets/logo1.png')).buffer.asUint8List();
      logoImage = pw.MemoryImage(defaultLogoBytes);
    }

    final double totalAmount = widget.bill.netTotal + widget.bill.totalDiscount;

    final headerStyle =
        pw.TextStyle(font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold);
    final subHeaderStyle = pw.TextStyle(font: ttf, fontSize: 16);
    final bodyStyle = pw.TextStyle(font: ttf, fontSize: 14);
    final tableHeaderStyle =
        pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold);
    final totalLabelStyle =
        pw.TextStyle(font: ttf, fontSize: 15, fontWeight: pw.FontWeight.bold);
    final totalValueStyle = pw.TextStyle(font: ttf, fontSize: 15);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- [แก้ไข] ส่วนหัวใช้ข้อมูลที่ดึงมา ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ใบเสร็จรับเงิน', style: headerStyle),
                        pw.Text(shopName, style: subHeaderStyle),
                        pw.Text(address, style: bodyStyle),
                        pw.Text('โทร: $phone', style: bodyStyle),
                      ],
                    ),
                  ),
                  if (logoImage != null)
                    pw.SizedBox(
                      width: 80,
                      height: 80,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),
              pw.SizedBox(height: 1 * PdfPageFormat.cm),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('เลขที่: ${widget.bill.billId}',
                      style: subHeaderStyle),
                  pw.Text(
                      'วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}',
                      style: subHeaderStyle),
                ],
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 0.5 * PdfPageFormat.cm),

              // --- ตารางรายการสินค้า ---
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(
                    color: PdfColors.white), // <--- แก้ไขตรงนี้
                headerStyle: tableHeaderStyle,
                cellStyle: bodyStyle,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.white),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {
                  1: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(6),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2.5),
                },
                headers: ['ลำดับ', 'รายการ', 'จำนวน', 'ราคา/หน่วย', 'ราคารวม'],
                data: widget.bill.items.map((item) {
                  final index = widget.bill.items.indexOf(item) + 1;
                  return [
                    index.toString(),
                    item.productName,
                    item.quantity.toString(),
                    item.price.toStringAsFixed(2),
                    item.itemNetTotal.toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.Divider(),
              pw.SizedBox(height: 0.5 * PdfPageFormat.cm),

              // --- ส่วนสรุปยอด ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 280,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildTotalRowPdf(
                            'รวมเป็นเงิน',
                            totalAmount.toStringAsFixed(2),
                            totalLabelStyle,
                            totalValueStyle),
                        _buildTotalRowPdf(
                            'ส่วนลดท้ายบิล',
                            widget.bill.totalDiscount.toStringAsFixed(2),
                            totalLabelStyle,
                            totalValueStyle),
                        pw.Divider(color: PdfColors.grey600),
                        _buildTotalRowPdf(
                            'ยอดรวมสุทธิ',
                            widget.bill.netTotal.toStringAsFixed(2),
                            totalLabelStyle,
                            totalValueStyle.copyWith(
                                fontWeight: pw.FontWeight.bold)),
                        pw.Divider(color: PdfColors.grey600),
                        _buildTotalRowPdf(
                            'รับเงิน',
                            widget.bill.moneyReceived.toStringAsFixed(2),
                            totalLabelStyle,
                            totalValueStyle),
                        _buildTotalRowPdf(
                            'เงินทอน',
                            widget.bill.change.toStringAsFixed(2),
                            totalLabelStyle,
                            totalValueStyle.copyWith(
                                fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),

              // --- ส่วนท้าย ---
              pw.Spacer(),
              pw.Divider(thickness: 1.5),
              pw.Center(child: pw.Text(footerLine1, style: bodyStyle)),
              pw.Center(child: pw.Text(footerLine2, style: bodyStyle)),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  // Helper สำหรับสร้างแถวสรุปยอดใน PDF
  pw.Widget _buildTotalRowPdf(String label, String value,
      pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: labelStyle),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }

  /// [ใหม่] ฟังก์ชันสำหรับพิมพ์ใบเสร็จ (80mm & 58mm) เป็นรูปภาพผ่าน IP
  Future<void> _printReceiptAsImage() async {
    setState(() => _isWorking = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final printerIp = prefs.getString('printer_ip');
      final autoCut = prefs.getBool('auto_cut_paper') ?? true;

      if (printerIp == null || printerIp.isEmpty) {
        throw Exception(
            'กรุณาไปที่หน้า "ตั้งค่าเครื่องพิมพ์" เพื่อระบุ IP Address ก่อน');
      }

      double paperWidth =
          _selectedFormat.width == (80 * PdfPageFormat.mm) ? 345 : 253;

      final imageBytes = await _screenshotController.captureFromWidget(
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: ReceiptWidget(
            bill: widget.bill,
            paperWidth: paperWidth,
          ),
        ),
        delay: const Duration(milliseconds: 50),
        pixelRatio: 1.5,
      );

      setState(() => _isWorking = false);

      bool? confirmPrint = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ตัวอย่างก่อนพิมพ์'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(imageBytes, fit: BoxFit.contain),
                const SizedBox(height: 10),
                Text('จะพิมพ์ไปยัง IP: $printerIp',
                    style: const TextStyle(color: Colors.grey))
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ยกเลิก')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('ยืนยันการพิมพ์')),
          ],
        ),
      );

      if (confirmPrint == true) {
        setState(() => _isWorking = true);
        final paperSize = _selectedFormat.width == (80 * PdfPageFormat.mm)
            ? PaperSize.mm80
            : PaperSize.mm58;
        final profile = await CapabilityProfile.load();
        final printer = NetworkPrinter(paperSize, profile);
        final PosPrintResult res = await printer.connect(printerIp,
            port: 9100, timeout: const Duration(seconds: 10));

        if (res == PosPrintResult.success) {
          final image = img.decodeImage(imageBytes)!;
          printer.image(image, align: PosAlign.center);
          printer.feed(1);
          if (autoCut) printer.cut();
          printer.disconnect();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('พิมพ์สำเร็จ'), backgroundColor: Colors.green));
          }
        } else {
          throw Exception('เชื่อมต่อไม่สำเร็จ: ${res.msg}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
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
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
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
                        "ราคา: ${item.price.toStringAsFixed(2)} บาท  x  ${item.quantity}",
                        style: const TextStyle(fontSize: 14)),
                    Text("ส่วนลด: ${item.discount.toStringAsFixed(2)} บาท",
                        style: const TextStyle(fontSize: 14)),
                    Text("รวม: ${item.itemNetTotal.toStringAsFixed(2)} บาท",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
            Text("รวมทั้งสิ้น: ${totalAmount.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
                "ส่วนลดท้ายบิล: ${widget.bill.totalDiscount.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            const Divider(thickness: 1.0),
            const SizedBox(height: 4),
            Text("ยอดรวมสุทธิ: ${widget.bill.netTotal.toStringAsFixed(2)} บาท",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                "เงินที่รับ: ${widget.bill.moneyReceived.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("เงินทอน: ${widget.bill.change.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
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
            Center(
              child: _isWorking
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedFormat == PdfPageFormat.a4) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfPreviewPage(
                                  buildPdf: (format) =>
                                      _generatePdf(_selectedFormat),
                                ),
                              ));
                        } else {
                          _printReceiptAsImage();
                        }
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

  const PdfPreviewPage({super.key, required this.buildPdf});

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
