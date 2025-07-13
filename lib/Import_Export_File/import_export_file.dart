import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

// Import model ต่างๆ
import '../Database/product_model.dart';
import '../Database/bill_model.dart';
import '../Database/supplier_model.dart';
import '../Database/lot_model.dart';

// Enum สำหรับเก็บการตัดสินใจ global เมื่อเจอ duplicate
enum DuplicateDecision { none, skipAll, replaceAll }

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({Key? key}) : super(key: key);

  @override
  _ImportExportPageState createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  // ค่าที่เลือกใน dialog export
  bool exportProducts = false;
  bool exportBills = false;
  bool exportSuppliers = false;
  bool exportLots = false; // เพิ่ม export สำหรับ LotModel

  // ตัวแปร global สำหรับเก็บการตัดสินใจใน duplicate
  DuplicateDecision _globalDecision = DuplicateDecision.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รับข้อมูล / ส่งข้อมูล")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showExportOptionsDialog(),
              child: const Text("ส่งข้อมูล"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Reset global decision ก่อนเริ่ม import ใหม่
                _globalDecision = DuplicateDecision.none;
                _importData();
              },
              child: const Text("รับข้อมูล"),
            ),
          ],
        ),
      ),
    );
  }

  // ********************************************
  // Export Section
  // ********************************************

  /// แสดง dialog ให้เลือกข้อมูลที่ต้องการ export
  Future<void> _showExportOptionsDialog() async {
    // รีเซ็ตค่าก่อนแสดง dialog
    exportProducts = false;
    exportBills = false;
    exportSuppliers = false;
    exportLots = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("เลือกข้อมูลที่จะ ส่งออก"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text("ข้อมูลสินค้า"),
                    value: exportProducts,
                    onChanged: (value) {
                      setStateDialog(() {
                        exportProducts = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("ข้อมูลบิล"),
                    value: exportBills,
                    onChanged: (value) {
                      setStateDialog(() {
                        exportBills = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("ข้อมูลซัพพายเออร์ (รวมรูปบิล)"),
                    value: exportSuppliers,
                    onChanged: (value) {
                      setStateDialog(() {
                        exportSuppliers = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("ข้อมูลล็อต"),
                    value: exportLots,
                    onChanged: (value) {
                      setStateDialog(() {
                        exportLots = value ?? false;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportData();
              },
              child: const Text("Export"),
            ),
          ],
        );
      },
    );
  }

  /// ฟังก์ชัน export ข้อมูลตามที่เลือก
 Future<void> _exportData() async {
  Map<String, dynamic> exportMap = {};

  // ตรวจสอบเลือก export ข้อมูลสินค้า
  if (exportProducts) {
    final productBox = Hive.box<ProductModel>('products');
    exportMap["products"] =
        productBox.values.map((p) => _productToMap(p)).toList();
  }
  // ตรวจสอบเลือก export ข้อมูลบิล
  if (exportBills) {
    final billBox = Hive.box<BillModel>('bills');
    exportMap["bills"] = billBox.values.map((b) => _billToMap(b)).toList();
  }
  // ตรวจสอบเลือก export ข้อมูลซัพพายเออร์
  if (exportSuppliers) {
    final supplierBox = Hive.box<SupplierModel>('suppliers');
    exportMap["suppliers"] =
        supplierBox.values.map((s) => _supplierToMap(s)).toList();
  }
  // ตรวจสอบเลือก export ข้อมูลล็อต
  if (exportLots) {
    final lotBox = Hive.box<LotModel>('lots');
    exportMap["lots"] = lotBox.values.map((l) => _lotToMap(l)).toList();
  }

  String jsonString = jsonEncode(exportMap);

  // ให้ผู้ใช้เลือกโฟลเดอร์ปลายทางสำหรับเก็บไฟล์
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

  if (selectedDirectory == null) {
    // ถ้าผู้ใช้ยกเลิกการเลือกโฟลเดอร์
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ยกเลิกการเลือกโฟลเดอร์")),
    );
    return;
  }

  // สร้างชื่อไฟล์ โดยใช้ datetime
  String fileName = "export_${DateTime.now().millisecondsSinceEpoch}.json";
  String fullPath = "$selectedDirectory/$fileName";

  File file = File(fullPath);
  await file.writeAsString(jsonString);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Export สำเร็จที่ $fullPath")),
  );
}


  // ********************************************
  // Import Section
  // ********************************************

  Future<void> _importData() async {
    // ให้ผู้ใช้เลือกไฟล์ JSON ที่ต้องการ import
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;
    String? filePath = result.files.single.path;
    if (filePath == null) return;

    File file = File(filePath);
    String jsonString = await file.readAsString();
    Map<String, dynamic> importMap = jsonDecode(jsonString);

    // Import Products
    if (importMap.containsKey("products")) {
      final productBox = Hive.box<ProductModel>('products');
      for (var prod in importMap["products"]) {
        ProductModel newProduct = ProductModel(
          id: prod["id"],
          name: prod["name"],
          retailPrice: (prod["retailPrice"] as num).toDouble(),
          wholesalePrice: (prod["wholesalePrice"] as num).toDouble(),
          category: prod["category"],
          barcode: prod["barcode"],
          imageUrl: prod["imageUrl"],
        );
        var existingIndex =
            productBox.values.toList().indexWhere((p) => p.id == newProduct.id);
        if (existingIndex == -1) {
          await productBox.add(newProduct);
        } else {
          bool replace = await _showDuplicateDialog("สินค้า", newProduct.id);
          if (replace) {
            var key = productBox
                .toMap()
                .keys
                .firstWhere((k) => productBox.get(k)?.id == newProduct.id);
            await productBox.put(key, newProduct);
          }
        }
      }
    }

    // Import Bills
    if (importMap.containsKey("bills")) {
      final billBox = Hive.box<BillModel>('bills');
      for (var bill in importMap["bills"]) {
        BillModel newBill = BillModel(
          billId: bill["billId"],
          billDate: DateTime.parse(bill["billDate"]),
          items: (bill["items"] as List).map((item) {
            return BillItem(
              productName: item["productName"],
              price: (item["price"] as num).toDouble(),
              quantity: item["quantity"],
              discount: (item["discount"] as num).toDouble(),
            );
          }).toList(),
          totalDiscount: (bill["totalDiscount"] as num).toDouble(),
          netTotal: (bill["netTotal"] as num).toDouble(),
          moneyReceived: (bill["moneyReceived"] as num).toDouble(),
          change: (bill["change"] as num).toDouble(),
        );
        var existingIndex = billBox.values
            .toList()
            .indexWhere((b) => b.billId == newBill.billId);
        if (existingIndex == -1) {
          await billBox.add(newBill);
        } else {
          bool replace = await _showDuplicateDialog("บิล", newBill.billId);
          if (replace) {
            var key = billBox
                .toMap()
                .keys
                .firstWhere((k) => billBox.get(k)?.billId == newBill.billId);
            await billBox.put(key, newBill);
          }
        }
      }
    }

    // Import Suppliers
    if (importMap.containsKey("suppliers")) {
      final supplierBox = Hive.box<SupplierModel>('suppliers');
      for (var sup in importMap["suppliers"]) {
        SupplierModel newSupplier = SupplierModel(
          name: sup["name"],
          billImagePath: sup["billImagePath"],
          paymentAmount: (sup["paymentAmount"] as num).toDouble(),
          recordDate: DateTime.parse(sup["recordDate"]),
        );
        bool exists = supplierBox.values.any((s) => s.name == newSupplier.name);
        if (!exists) {
          await supplierBox.add(newSupplier);
        } else {
          bool replace =
              await _showDuplicateDialog("ซัพพายเออร์", newSupplier.name);
          if (replace) {
            var key = supplierBox.toMap().keys.firstWhere(
                (k) => supplierBox.get(k)?.name == newSupplier.name);
            await supplierBox.put(key, newSupplier);
          }
        }
      }
    }

    // Import Lots
    if (importMap.containsKey("lots")) {
      final lotBox = Hive.box<LotModel>('lots');
      for (var lot in importMap["lots"]) {
        LotModel newLot = LotModel(
          lotId: lot["lotId"],
          productId: lot["productId"],
          quantity: lot["quantity"],
          expiryDate: DateTime.parse(lot["expiryDate"]),
          recordDate: DateTime.parse(lot["recordDate"]),
          note: lot["note"],
        );
        bool exists = lotBox.values.any((l) => l.lotId == newLot.lotId);
        if (!exists) {
          await lotBox.add(newLot);
        } else {
          bool replace = await _showDuplicateDialog("ล็อต", newLot.lotId);
          if (replace) {
            var key = lotBox
                .toMap()
                .keys
                .firstWhere((k) => lotBox.get(k)?.lotId == newLot.lotId);
            await lotBox.put(key, newLot);
          }
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Import ข้อมูลเสร็จสิ้น")),
    );
  }

  /// ฟังก์ชันแปลง ProductModel เป็น Map สำหรับ JSON
  Map<String, dynamic> _productToMap(ProductModel product) => {
        "id": product.id,
        "name": product.name,
        "retailPrice": product.retailPrice,
        "wholesalePrice": product.wholesalePrice,
        "category": product.category,
        "barcode": product.barcode,
        "imageUrl": product.imageUrl,
      };

  /// ฟังก์ชันแปลง BillModel เป็น Map
  Map<String, dynamic> _billToMap(BillModel bill) => {
        "billId": bill.billId,
        "billDate": bill.billDate.toIso8601String(),
        "items": bill.items.map((item) => _billItemToMap(item)).toList(),
        "totalDiscount": bill.totalDiscount,
        "netTotal": bill.netTotal,
        "moneyReceived": bill.moneyReceived,
        "change": bill.change,
      };

  Map<String, dynamic> _billItemToMap(BillItem item) => {
        "productName": item.productName,
        "price": item.price,
        "quantity": item.quantity,
        "discount": item.discount,
      };

  /// ฟังก์ชันแปลง SupplierModel เป็น Map
  Map<String, dynamic> _supplierToMap(SupplierModel supplier) => {
        "name": supplier.name,
        "billImagePath": supplier.billImagePath,
        "paymentAmount": supplier.paymentAmount,
        "recordDate": supplier.recordDate.toIso8601String(),
      };

  /// ฟังก์ชันแปลง LotModel เป็น Map
  Map<String, dynamic> _lotToMap(LotModel lot) => {
        "lotId": lot.lotId,
        "productId": lot.productId,
        "quantity": lot.quantity,
        "expiryDate": lot.expiryDate.toIso8601String(),
        "recordDate": lot.recordDate.toIso8601String(),
        "note": lot.note,
      };

  /// Dialog แจ้งเตือนเมื่อพบข้อมูลซ้ำ
  /// เพิ่มตัวเลือก "ใช้กับรายการที่เหลือทั้งหมด" เพื่อให้ผู้ใช้เลือก global decision
  Future<bool> _showDuplicateDialog(String type, String identifier) async {
    // ถ้ามีการตัดสินใจ global แล้วให้ใช้ค่าเดิมทันที
    if (_globalDecision == DuplicateDecision.replaceAll) return true;
    if (_globalDecision == DuplicateDecision.skipAll) return false;

    bool applyToAll = false;
    bool? decision = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("พบข้อมูล$type ซ้ำ"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "มีรายการที่มีค่า \"$identifier\" อยู่แล้ว\nคุณต้องการแทนที่หรือข้าม?"),
                CheckboxListTile(
                  title: const Text("ใช้กับรายการที่เหลือทั้งหมด"),
                  value: applyToAll,
                  onChanged: (value) {
                    setStateDialog(() {
                      applyToAll = value ?? false;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("ข้าม"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("แทนที่"),
              ),
            ],
          );
        },
      ),
    );

    // หากผู้ใช้ติ๊ก "ใช้กับรายการที่เหลือทั้งหมด" ให้เก็บการตัดสินใจแบบ global
    if (applyToAll && decision != null) {
      _globalDecision = decision
          ? DuplicateDecision.replaceAll
          : DuplicateDecision.skipAll;
    }
    return decision ?? false;
  }
}
