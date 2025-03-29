import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui; // ใช้สำหรับ ImageByteFormat และ ui.Image
import 'package:flutter/foundation.dart' as ui show ByteData;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img; // สำหรับแปลง Uint8List เป็น Image ของ package image

import '../Database/bill_model.dart'; // ไฟล์ Model บิล
import '../Database/printer_connection_model.dart'; // Model เครื่องปริ้นที่ใช้ Hive

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
      'format': PdfPageFormat(80 * PdfPageFormat.mm, 210 * PdfPageFormat.mm,
          marginAll: 10),
    },
    {
      'label': 'Custom (58 x 210 มม.)',
      'format': PdfPageFormat(58 * PdfPageFormat.mm, 210 * PdfPageFormat.mm,
          marginAll: 10),
    },
  ];

  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _selectedFormat = PdfPageFormat.a4; // ตั้งค่าเริ่มต้นเป็น A4
  }

  /// สร้าง PDF จาก BillModel
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();

    // โหลดฟอนต์ไทย
    final fontData = await rootBundle.load("assets/fonts/THSarabun.ttf");
    final fontThai = pw.Font.ttf(fontData.buffer.asByteData());

    // โหลดโลโก้
    final logoBytes =
        (await rootBundle.load('assets/logo1.png')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    // คำนวณยอดรวมก่อนหักส่วนลด
    final double totalAmount = widget.bill.netTotal + widget.bill.totalDiscount;

    if (format == PdfPageFormat.a4) {
      // Layout สำหรับ A4
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Image(logoImage, width: 150, height: 150),
                ),
                pw.SizedBox(height: 20),
                pw.Text("บิลเลขที่: ${widget.bill.billId}",
                    style: pw.TextStyle(font: fontThai, fontSize: 16)),
                pw.Text(
                  "วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}",
                  style: pw.TextStyle(font: fontThai, fontSize: 16),
                ),
                pw.Divider(),
                // ตารางรายการ
                pw.Table(
                  border: pw.TableBorder.symmetric(
                    inside: pw.BorderSide.none,
                    outside: pw.BorderSide.none,
                  ),
                  children: [
                    // หัวตาราง
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("ลำดับ",
                              style: pw.TextStyle(
                                  font: fontThai,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("ชื่อสินค้า",
                              style: pw.TextStyle(
                                  font: fontThai,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("จำนวน",
                              style: pw.TextStyle(
                                  font: fontThai,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("ราคาต่อหน่วย",
                              style: pw.TextStyle(
                                  font: fontThai,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text("จำนวนเงิน",
                              style: pw.TextStyle(
                                  font: fontThai,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // รายการสินค้า
                    ...List.generate(widget.bill.items.length, (index) {
                      final item = widget.bill.items[index];
                      return pw.TableRow(
                        decoration: const pw.BoxDecoration(),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text("${index + 1}",
                                style:
                                    pw.TextStyle(font: fontThai, fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(item.productName,
                                style:
                                    pw.TextStyle(font: fontThai, fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text("${item.quantity}",
                                style:
                                    pw.TextStyle(font: fontThai, fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text("${item.price}",
                                style:
                                    pw.TextStyle(font: fontThai, fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text("${item.itemNetTotal} บาท",
                                style: pw.TextStyle(
                                    font: fontThai,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                // สรุปยอด
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ยอดรวมสุทธิ:",
                        style: pw.TextStyle(
                            font: fontThai,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.netTotal} บาท",
                        style: pw.TextStyle(font: fontThai, fontSize: 16)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("เงินที่รับ:",
                        style: pw.TextStyle(
                            font: fontThai,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.moneyReceived} บาท",
                        style: pw.TextStyle(font: fontThai, fontSize: 14)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("เงินทอน:",
                        style: pw.TextStyle(
                            font: fontThai,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.change} บาท",
                        style: pw.TextStyle(font: fontThai, fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("เวลาทำการ: เปิดทุกวัน 04.00 - 18.00",
                          style: pw.TextStyle(font: fontThai, fontSize: 14)),
                      pw.Text("ขอบคุณที่ใช้บริการ",
                          style: pw.TextStyle(font: fontThai, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // Layout สำหรับกระดาษอื่น ๆ (Custom 58mm, 80mm)
      doc.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Image(logoImage, width: 100, height: 100),
                ),
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
                      pw.SizedBox(height: 1),
                      pw.Text("ราคา: ${item.price} x ${item.quantity}",
                          style: pw.TextStyle(font: fontThai, fontSize: 12)),
                      pw.Text("ส่วนลด: ${item.discount}",
                          style: pw.TextStyle(font: fontThai, fontSize: 12)),
                      pw.Text("รวม: ${item.itemNetTotal} บาท",
                          style: pw.TextStyle(
                              font: fontThai,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Divider(),
                    ],
                  );
                }).toList(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("รวมทั้งสิ้น:",
                        style: pw.TextStyle(
                            font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("$totalAmount บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ส่วนลดท้ายบิล:",
                        style: pw.TextStyle(
                            font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.totalDiscount} บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ยอดรวมสุทธิ:",
                        style: pw.TextStyle(
                            font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.netTotal} บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("เงินที่รับ:",
                        style: pw.TextStyle(
                            font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.moneyReceived} บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("เงินทอน:",
                        style: pw.TextStyle(
                            font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${widget.bill.change} บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
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
    }

    return doc.save();
  }

Future<void> _printBillViaSocket(PrinterConnectionModel printer) async {
  try {
    Uint8List pdfBytes = await _generatePdf(_selectedFormat);

    final rasterStream = Printing.raster(pdfBytes);
    final PdfRaster raster = await rasterStream.first;
    final ui.Image uiImage = await raster.toImage();
    final ui.ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageBytes = byteData!.buffer.asUint8List();

    // ส่งรูปตรง ๆ แบบ Raw
    Socket socket = await Socket.connect(printer.ipAddress, printer.port,
        timeout: const Duration(seconds: 5));

    socket.add(imageBytes); // <-- ส่งภาพ PNG ตรง ๆ
    await socket.flush();
    socket.destroy();

    setState(() {
      _statusMessage =
          "ส่งคำสั่งปริ้นของเครื่องปริ้น ${printer.printerName} สำเร็จ!";
    });
  } catch (e) {
    setState(() {
      _statusMessage =
          "การส่งคำสั่งปริ้นของเครื่องปริ้น ${printer.printerName} ล้มเหลว: $e";
    });
  }
}

  /// แสดง Dialog ให้เลือกวิธีพิมพ์ (PDF หรือ Socket)
  Future<void> _showPrintMethodDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("เลือกวิธีพิมพ์"),
          content: const Text("คุณต้องการพิมพ์แบบ PDF หรือแบบ Socket?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // เลือก PDF => ไปแสดง PdfPreviewPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfPreviewPage(
                      buildPdf: (format) => _generatePdf(_selectedFormat),
                    ),
                  ),
                );
              },
              child: const Text("PDF"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // เลือก Socket => แสดง Dialog เลือกเครื่องปริ้น
                await _showSelectPrinterDialog();
              },
              child: const Text("Socket"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("ยกเลิก"),
            ),
          ],
        );
      },
    );
  }

  /// แสดง Dialog เลือกเครื่องปริ้นจาก Hive
  Future<void> _showSelectPrinterDialog() async {
    Box<PrinterConnectionModel> box =
        Hive.box<PrinterConnectionModel>('printerBox');
    List<PrinterConnectionModel> printers = box.values.toList();

    if (printers.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("ไม่พบเครื่องปริ้น"),
          content:
              const Text("กรุณาเพิ่มเครื่องปริ้นก่อนทำการพิมพ์แบบ Socket"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("ตกลง"),
            ),
          ],
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("เลือกเครื่องปริ้น"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: printers.length,
              itemBuilder: (context, index) {
                final printer = printers[index];
                return ListTile(
                  title: Text(printer.printerName),
                  subtitle: Text("${printer.ipAddress}:${printer.port}"),
                  onTap: () async {
                    Navigator.pop(context); // ปิด Dialog
                    await _printBillViaSocket(printer);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("ยกเลิก"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount =
        widget.bill.netTotal + widget.bill.totalDiscount;
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
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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
                    setState(() {
                      _selectedFormat = newFormat!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showPrintMethodDialog,
                icon: const Icon(Icons.print),
                label: const Text("แสดงตัวอย่าง/พิมพ์บิล"),
              ),
            ),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
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
