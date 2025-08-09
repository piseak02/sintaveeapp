// BillDetailPage (full) — Dynamic height capture + safe slicing for very long receipts
// - ไม่พึ่ง drawImage/copyInto (ทำ padding ตั้งแต่ capture)
// - คำนวณความสูงตามจำนวนรายการจริงด้วย TextPainter (กัน overflow)
// - ถ้ารูปยาวมาก ตัดเป็นชิ้น ๆ ก่อนส่งพิมพ์ (ป้องกัน buffer ของเครื่องพิมพ์)

import 'dart:math' as math;
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
import 'receipt_widget.dart';

const int kDots80 = 576; // 80mm printable width @203dpi
const int kDots58 = 384; // 58mm printable width @203dpi

class BillDetailPage extends StatefulWidget {
  final BillModel bill;
  const BillDetailPage({Key? key, required this.bill}) : super(key: key);
  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
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

  // ---------------- PDF Preview (A4) ----------------
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final fontData = await rootBundle.load('assets/fonts/THSarabun.ttf');
    final ttf = pw.Font.ttf(fontData);

    final prefs = await SharedPreferences.getInstance();
    final shopName = prefs.getString('bill_shop_name') ?? 'ร้านค้าตัวอย่าง';
    final address =
        prefs.getString('bill_address') ?? '123 ถนนตัวอย่าง ต.ตัวอย่าง อ.เมือง';
    final phone = prefs.getString('bill_phone') ?? '081-234-5678';
    final logoPath = prefs.getString('bill_logo_path');
    final footerLine1 = prefs.getString('bill_footer_line1') ??
        'เวลาทำการ: เปิดทุกวัน 04.00 - 18.00';
    final footerLine2 =
        prefs.getString('bill_footer_line2') ?? 'ขอบคุณที่ใช้บริการ';

    pw.ImageProvider? logoImage;
    if (logoPath != null && await File(logoPath).exists()) {
      final bytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(bytes);
    } else {
      final bytes =
          (await rootBundle.load('assets/logo1.png')).buffer.asUint8List();
      logoImage = pw.MemoryImage(bytes);
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
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
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
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
            ],
          ),
          pw.SizedBox(height: 1 * PdfPageFormat.cm),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('เลขที่: ${widget.bill.billId}', style: subHeaderStyle),
              pw.Text(
                  'วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}',
                  style: subHeaderStyle),
            ],
          ),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 0.5 * PdfPageFormat.cm),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.white),
            headerStyle: tableHeaderStyle,
            cellStyle: bodyStyle,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {
              1: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight
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
          pw.Spacer(),
          pw.Divider(thickness: 1.5),
          pw.Center(child: pw.Text(footerLine1, style: bodyStyle)),
          pw.Center(child: pw.Text(footerLine2, style: bodyStyle)),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _buildTotalRowPdf(String label, String value,
      pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: labelStyle),
            pw.Text(value, style: valueStyle)
          ]),
    );
  }

  // ---------------- Thermal Print (80/58mm) ----------------
  Future<void> _showPreviewAndPrint() async {
    setState(() => _isWorking = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final printerIp = prefs.getString('printer_ip');
      final autoCut = prefs.getBool('auto_cut_paper') ?? true;
      if (printerIp == null || printerIp.isEmpty) {
        throw Exception(
            'กรุณาไปที่หน้า "ตั้งค่าเครื่องพิมพ์" เพื่อระบุ IP Address ก่อน');
      }

      setState(() => _isWorking = false);

      final bool? confirmPrint = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                Text('ตัวอย่างก่อนพิมพ์',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ReceiptWidget(
                        bill: widget.bill,
                        paperWidth:
                            _selectedFormat.width == (80 * PdfPageFormat.mm)
                                ? 345
                                : 253,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('จะพิมพ์ไปยัง IP: $printerIp',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('ยกเลิก'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('ยืนยันการพิมพ์'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (confirmPrint != true) return;

      setState(() => _isWorking = true);

      // ====== ค่าที่ต้องจูน ======
      final bool is80 = _selectedFormat.width == (80 * PdfPageFormat.mm);
      final int maxDots = is80 ? kDots80 : kDots58;
      int sideMargin = is80 ? 16 : 12; // 🔧 ปรับทีละ 4–8 dots จนพอดี
      int bottomMargin = 40; // 🔧 เผื่อท้ายบิลเพิ่มกันคัตเตอร์

      // ====== สร้างภาพให้กว้าง = maxDots ตั้งแต่ตอน capture ======
      final double contentWidthPx = is80 ? 345 : 253; // ความกว้างเนื้อหา (px)
      final double pixelRatio = (maxDots - sideMargin * 2) /
          contentWidthPx; // สเกลให้เนื้อหา = (maxDots-ขอบ)
      final double padSidePx = sideMargin / pixelRatio; // ขอบซ้าย/ขวา (px)
      final double padBottomPx = bottomMargin / pixelRatio; // ขอบล่าง (px)

      // === คำนวณความสูงตามเนื้อหาจริง (ป้องกัน Bottom Overflow) ===
      // กำหนดสไตล์ให้เหมือนใน ReceiptWidget
      const TextStyle regularStyle =
          TextStyle(fontSize: 18, fontFamily: 'Sarabun');
      const TextStyle boldStyle = TextStyle(
          fontSize: 19, fontWeight: FontWeight.bold, fontFamily: 'Sarabun');

      double _measureTextHeight(String text, TextStyle style, double maxWidth) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          maxLines: null,
        )..layout(maxWidth: maxWidth);
        return tp.size.height;
      }

      // พื้นที่คอลัมน์ซ้ายของรายการ (ประมาณ): หักค่าตัวเลขราคารวม + interval
      final double leftColWidthPx =
          contentWidthPx - 110; // 🔧 ปรับได้ถ้าตัวเลขยาวมาก

      double itemsHeightPx = 0;
      for (final it in widget.bill.items) {
        final line = '${it.productName} x${it.quantity}';
        itemsHeightPx +=
            _measureTextHeight(line, regularStyle, leftColWidthPx) +
                6; // + gap ต่อรายการ
      }

      // ความสูงส่วนอื่น ๆ ที่คงที่โดยประมาณ (หัว+หัวตาราง+สรุปราคา+ฟุตเตอร์)
      final double staticHeightPx = 360 + 260; // 🔧 ปรับได้ตามธีมจริง

      final double logicalHeight =
          (itemsHeightPx + staticHeightPx + padBottomPx);
      final double logicalWidth = contentWidthPx + padSidePx * 2;

      final Uint8List imageBytes =
          await _screenshotController.captureFromWidget(
        Material(
          color: Colors.white,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.only(
                left: padSidePx, right: padSidePx, bottom: padBottomPx),
            child: ReceiptWidget(bill: widget.bill, paperWidth: contentWidthPx),
          ),
        ),
        delay: const Duration(milliseconds: 200),
        pixelRatio: pixelRatio, // ความกว้าง = maxDots เป๊ะ
        targetSize: Size(logicalWidth, logicalHeight), // ความสูงตามคำนวณจริง
      );

      final img.Image raster = img.decodeImage(imageBytes)!;

      final paperSize = is80 ? PaperSize.mm80 : PaperSize.mm58;
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(paperSize, profile);
      final PosPrintResult res = await printer.connect(printerIp,
          port: 9100, timeout: const Duration(seconds: 10));

      if (res == PosPrintResult.success) {
        // ถ้ารูปยาวมาก ให้ตัดเป็นชิ้น ๆ (slice) ป้องกันเครื่องบางรุ่นค้าง
        const int sliceHeight =
            1024; // 🔧 เปลี่ยนได้ตามความเสถียรของรุ่นเครื่อง
        if (raster.height > sliceHeight * 2) {
          for (int y = 0; y < raster.height; y += sliceHeight) {
            final int h = math.min(sliceHeight, raster.height - y);
            final img.Image slice = img.copyCrop(raster,
                x: 0, y: y, width: raster.width, height: h);
            printer.image(slice, align: PosAlign.center);
          }
        } else {
          printer.image(raster, align: PosAlign.center);
        }

        printer.feed(4); // กันคัตเตอร์ตัดโดนบรรทัดท้าย
        printer.cut(mode: PosCutMode.partial);
        printer.disconnect();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('พิมพ์สำเร็จ'), backgroundColor: Colors.green));
        }
      } else {
        throw Exception('เชื่อมต่อไม่สำเร็จ: ${res.msg}');
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
      appBar: AppBar(title: Text('รายละเอียดบิล: ${widget.bill.billId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ใบเสร็จ: ${widget.bill.billId}'),
          const SizedBox(height: 8),
          Text(
              'วันที่: ${widget.bill.billDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text('รายการสินค้า:',
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
                        'ราคา: ${item.price.toStringAsFixed(2)} บาท  x  ${item.quantity}',
                        style: const TextStyle(fontSize: 14)),
                    Text('ส่วนลด: ${item.discount.toStringAsFixed(2)} บาท',
                        style: const TextStyle(fontSize: 14)),
                    Text('รวม: ${item.itemNetTotal.toStringAsFixed(2)} บาท',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const Divider(),
                  ]),
            );
          }).toList(),
          Text('รวมทั้งสิ้น: ${totalAmount.toStringAsFixed(2)} บาท',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
              'ส่วนลดท้ายบิล: ${widget.bill.totalDiscount.toStringAsFixed(2)} บาท',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          const Divider(thickness: 1.0),
          const SizedBox(height: 4),
          Text('ยอดรวมสุทธิ: ${widget.bill.netTotal.toStringAsFixed(2)} บาท',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              'เงินที่รับ: ${widget.bill.moneyReceived.toStringAsFixed(2)} บาท',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('เงินทอน: ${widget.bill.change.toStringAsFixed(2)} บาท',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Row(children: [
            const Text('เลือกขนาดหน้ากระดาษ: ', style: TextStyle(fontSize: 16)),
            DropdownButton<PdfPageFormat>(
              value: _selectedFormat,
              items: _formats
                  .map((f) => DropdownMenuItem<PdfPageFormat>(
                      value: f['format'], child: Text(f['label'])))
                  .toList(),
              onChanged: (newFormat) {
                if (newFormat != null)
                  setState(() => _selectedFormat = newFormat);
              },
            ),
          ]),
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
                                    _generatePdf(_selectedFormat)),
                          ),
                        );
                      } else {
                        _showPreviewAndPrint();
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('แสดงตัวอย่าง/พิมพ์บิล'),
                  ),
          ),
        ]),
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
        appBar: AppBar(title: const Text('ตัวอย่าง PDF')),
        body: PdfPreview(
            build: (format) => buildPdf(format), pdfFileName: 'bill.pdf'));
  }
}

// 🛠 ปรับจูนได้
// - sideMargin: เพิ่ม/ลดทีละ 4–8 dots ให้ขอบซ้ายขวาพอดี
// - bottomMargin: เพิ่มถ้าคัตเตอร์ยังตัดโดนบรรทัดท้าย
// - leftColWidthPx/staticHeightPx: ปรับเล็กน้อยให้ตรงกับธีมจริง ถ้าชื่อสินค้ายาวมาก/ฟอนต์ต่าง
// - sliceHeight: ถ้ารูปยาวมากแล้วเครื่องบางรุ่นพิมพ์ค้าง ให้ลดลง เช่น 768
