import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Database/product_model.dart';
import '../Database/lot_model.dart';
import '../Bottoom_Navbar/bottom_navbar.dart';
import '../widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:flutter/services.dart';

class EditStockProduct extends StatefulWidget {
  const EditStockProduct({Key? key}) : super(key: key);

  @override
  _EditStockProductState createState() => _EditStockProductState();
}

class _EditStockProductState extends State<EditStockProduct> {
  Box<ProductModel>? productBox;
  List<ProductModel> allProducts = [];
  Box<LotModel>? lotBox;
  int _selectedIndex = 0;

  // Controller สำหรับค้นหาและแจ้งเตือน
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _alertController = TextEditingController();
  bool _showAlertConditionField = false;

  @override
  void initState() {
    super.initState();
    productBox = Hive.box<ProductModel>('products');
    lotBox = Hive.box<LotModel>('lots');
    _loadProducts();
  }

  // รวมจำนวนจาก LotModel ทั้งหมดที่มี productId ตรงกับสินค้านั้น
  int _getTotalQuantity(String productId) {
    return lotBox!.values
        .where((lot) => lot.productId == productId)
        .fold(0, (sum, lot) => sum + lot.quantity);
  }

  void _loadProducts() {
    setState(() {
      allProducts = productBox!.values.toList();
    });
  }

  /// ฟังก์ชันเพิ่มล็อตสินค้าใหม่สำหรับสินค้า
  void _editStock(ProductModel product) {
    // สร้าง controller สำหรับ 3 ช่อง: จำนวน, วันหมดอายุ, และหมายเหตุ
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("เพิ่มล็อตสินค้า: ${product.name}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ช่องกรอกจำนวนสินค้า
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "จำนวนสินค้า",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              // ช่องกรอกวันหมดอายุ (ในรูปแบบ วว/ดด/ปปปป)
              TextField(
                controller: expiryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "วันหมดอายุ (วว/ดด/ปปปป)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                inputFormatters: [DateInputFormatter()],
              ),
              const SizedBox(height: 10),
              // ช่องกรอกหมายเหตุ (ถ้ามี)
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: "หมายเหตุ (ถ้ามี)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantityText = quantityController.text;
              final expiryText = expiryController.text;
              if (quantityText.isEmpty || expiryText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน")),
                );
                return;
              }
              final int? quantity = int.tryParse(quantityText);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("จำนวนต้องมากกว่า 0")),
                );
                return;
              }
              // แปลงวันที่จาก TextBox (รูปแบบ วว/ดด/ปปปป)
              final expiryParts = expiryText.split('/');
              if (expiryParts.length != 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("รูปแบบวันหมดอายุไม่ถูกต้อง")),
                );
                return;
              }
              final day = int.tryParse(expiryParts[0]);
              final month = int.tryParse(expiryParts[1]);
              final year = int.tryParse(expiryParts[2]);
              if (day == null || month == null || year == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ไม่สามารถแปลงวันหมดอายุ")),
                );
                return;
              }
              DateTime expiryDate;
              try {
                expiryDate = DateTime(year, month, day);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("วันที่ไม่ถูกต้อง")),
                );
                return;
              }
              final now = DateTime.now();
              // สร้าง lotId จากวันที่จริง (ปี เดือน วัน ชั่วโมง นาที วินาที)
              final lotId =
                  "LOT-${now.year}${now.month.toString().padLeft(2, '0')}"
                  "${now.day.toString().padLeft(2, '0')}"
                  "${now.hour.toString().padLeft(2, '0')}"
                  "${now.minute.toString().padLeft(2, '0')}"
                  "${now.second.toString().padLeft(2, '0')}";
              final newLot = LotModel(
                lotId: lotId,
                productId: product.id,
                quantity: quantity,
                expiryDate: expiryDate,
                recordDate: now,
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
              );
              await lotBox!.add(newLot);
              setState(() {}); // รีโหลดข้อมูล (ถ้ามี UI ที่แสดงสต็อก)
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("เพิ่มล็อตสินค้าเรียบร้อย")),
              );
            },
            child: const Text("เพิ่ม"),
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชันแสดงรายละเอียดล็อตของสินค้าในป๊อปอัป
  /// ฟังก์ชันแสดงรายละเอียดล็อตของสินค้าในป๊อปอัป พร้อมปุ่มแก้ไขและลบ
  void _showLotDetails(ProductModel product) {
    // ดึงรายการ Lot ที่มี productId ตรงกับสินค้านั้น
    List<LotModel> lotsForProduct =
        lotBox!.values.where((lot) => lot.productId == product.id).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("รายละเอียดล็อตสำหรับ ${product.name}"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: lotsForProduct.isEmpty
              ? const Center(child: Text("ไม่มีข้อมูลล็อตสำหรับสินค้านี้"))
              : ListView.builder(
                  itemCount: lotsForProduct.length,
                  itemBuilder: (context, index) {
                    final lot = lotsForProduct[index];
                    String expiry =
                        "${lot.expiryDate.day.toString().padLeft(2, '0')}/"
                        "${lot.expiryDate.month.toString().padLeft(2, '0')}/"
                        "${lot.expiryDate.year}";
                    return ListTile(
                      title: Text("ล็อต: ${lot.lotId}"),
                      subtitle:
                          Text("จำนวน: ${lot.quantity} - หมดอายุ: $expiry"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ปุ่มแก้ไขล็อต
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.pop(context); // ปิด Dialog แรกก่อน
                              _editLot(lot);
                            },
                          ),
                          // ปุ่มลบล็อต
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteLot(lot);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ปิด"),
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชันแก้ไข Lot (เปิดป๊อปอัปสำหรับแก้ไข)
  void _editLot(LotModel lot) {
    // ดึง key ของ Lot นั้นจาก lotBox
    final lotMap = lotBox!.toMap();
    final key = lotMap.keys.firstWhere(
        (k) => lotBox!.get(k)?.lotId == lot.lotId,
        orElse: () => null);
    if (key == null) return;

    final TextEditingController quantityController =
        TextEditingController(text: lot.quantity.toString());
    final TextEditingController expiryController = TextEditingController(
        text:
            "${lot.expiryDate.day.toString().padLeft(2, '0')}/${lot.expiryDate.month.toString().padLeft(2, '0')}/${lot.expiryDate.year}");
    final TextEditingController noteController =
        TextEditingController(text: lot.note ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("แก้ไขล็อต: ${lot.lotId}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ช่องแก้ไขจำนวน
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "จำนวนสินค้า",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              // ช่องแก้ไขวันหมดอายุ
              TextField(
                controller: expiryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "วันหมดอายุ (วว/ดด/ปปปป)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                inputFormatters: [DateInputFormatter()],
              ),
              const SizedBox(height: 10),
              // ช่องแก้ไขหมายเหตุ
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: "หมายเหตุ (ถ้ามี)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantityText = quantityController.text;
              final expiryText = expiryController.text;
              if (quantityText.isEmpty || expiryText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน")),
                );
                return;
              }
              final int? newQuantity = int.tryParse(quantityText);
              if (newQuantity == null || newQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("จำนวนต้องมากกว่า 0")),
                );
                return;
              }
              final expiryParts = expiryText.split('/');
              if (expiryParts.length != 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("รูปแบบวันหมดอายุไม่ถูกต้อง")),
                );
                return;
              }
              final day = int.tryParse(expiryParts[0]);
              final month = int.tryParse(expiryParts[1]);
              final year = int.tryParse(expiryParts[2]);
              if (day == null || month == null || year == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ไม่สามารถแปลงวันหมดอายุ")),
                );
                return;
              }
              DateTime newExpiryDate;
              try {
                newExpiryDate = DateTime(year, month, day);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("วันที่ไม่ถูกต้อง")),
                );
                return;
              }
              final newNote = noteController.text.trim();
              final updatedLot = LotModel(
                lotId: lot.lotId,
                productId: lot.productId,
                quantity: newQuantity,
                expiryDate: newExpiryDate,
                recordDate: lot.recordDate, // เก็บวันที่บันทึกเดิม
                note: newNote.isEmpty ? null : newNote,
              );
              await lotBox!.put(key, updatedLot);
              setState(() {}); // รีเฟรช UI
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("แก้ไขล็อตเรียบร้อย")),
              );
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชันลบ Lot
  void _deleteLot(LotModel lot) async {
    final lotMap = lotBox!.toMap();
    final key = lotMap.keys.firstWhere(
        (k) => lotBox!.get(k)?.lotId == lot.lotId,
        orElse: () => null);
    if (key == null) return;

    bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณต้องการลบล็อต ${lot.lotId} หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ลบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await lotBox!.delete(key);
      setState(() {}); // รีเฟรช UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ลบล็อตเรียบร้อย")),
      );
    }
  }

  /// สร้างการ์ดสำหรับแต่ละรายการสินค้า (แสดงชื่อ, จำนวนคงเหลือ จาก LotModel, และหมวดหมู่)
  Widget _buildProductCard(ProductModel product) {
    int totalQuantity = _getTotalQuantity(product.id);
    int? alertThreshold = int.tryParse(_alertController.text);
    bool highlight = alertThreshold != null &&
        alertThreshold > 0 &&
        totalQuantity < alertThreshold;

    return Card(
      color: highlight ? Colors.red[100] : null,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวแรก: ชื่อสินค้า, จำนวนคงเหลือ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "จำนวน: $totalQuantity",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // แถวที่สอง: แสดงหมวดหมู่
            Text(
              "หมวดหมู่: ${product.category}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // แถวปุ่ม สำหรับเพิ่มสต๊อก และ แก้ไขสต๊อก
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ปุ่มเพิ่มสต็อก (เปลี่ยนไอคอนเป็น Icons.add)
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: () {
                    _editStock(product);
                  },
                ),
                // ปุ่มแก้ไขสต๊อก (แสดงรายการ Lot)
                IconButton(
                  icon: const Icon(Icons.list, color: Colors.blue),
                  onPressed: () {
                    _showLotDetails(product);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // เริ่มต้นกรองสินค้าจากช่องค้นหา
    List<ProductModel> filteredProducts = allProducts.where((product) {
      return product.name
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
    }).toList();

    // ถ้ามีการกรอกเงื่อนไขแจ้งเตือน ให้กรองสินค้าเพิ่มเติม
    if (_alertController.text.isNotEmpty) {
      final int? threshold = int.tryParse(_alertController.text);
      if (threshold != null) {
        filteredProducts = filteredProducts
            .where((product) => _getTotalQuantity(product.id) < threshold)
            .toList();
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // ส่วนหัวด้วย PrimaryHeaderContainer
          TPrimaryHeaderContainer(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "จัดการสต็อกสินค้า",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          // ช่องค้นหาและเงื่อนไขแจ้งเตือน
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // ช่องค้นหาสินค้า
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "ค้นหาสินค้า",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {}); // รีเฟรช UI เมื่อค้นหา
                  },
                ),
                const SizedBox(height: 10),
                // Label สำหรับ "กำหนดเงื่อนไขแจ้งเตือน"
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showAlertConditionField = !_showAlertConditionField;
                      });
                    },
                    child: const Text(
                      "กำหนดเงื่อนไขแจ้งเตือน",
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                ),
                // ช่องกรอกเงื่อนไขแจ้งเตือน (เฉพาะเมื่อ _showAlertConditionField เป็น true)
                if (_showAlertConditionField)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _alertController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "แจ้งเตือนเมื่อจำนวนสินค้าน้อยกว่า",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(
                            () {}); // รีเฟรช UI เพื่อแสดงสินค้าที่ต่ำกว่าเงื่อนไข
                      },
                    ),
                  ),
              ],
            ),
          ),
          // รายการสินค้าใน ListView
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text("ไม่มีสินค้า"))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

/// TextInputFormatter สำหรับจัดรูปแบบวันหมดอายุเป็น dd/MM/yyyy
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';

    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8); // ddMMyyyy
    }

    for (int i = 0; i < digitsOnly.length; i++) {
      formatted += digitsOnly[i];
      if (i == 1 || i == 3) {
        formatted += '/';
      }
    }

    // หากครบ 8 หลัก ให้ตรวจสอบความถูกต้องของวัน
    if (digitsOnly.length == 8) {
      int day = int.parse(digitsOnly.substring(0, 2));
      int month = int.parse(digitsOnly.substring(2, 4));
      int year = int.parse(digitsOnly.substring(4, 8));

      if (month > 12) {
        month = 12;
      } else if (month == 0) {
        month = 1;
      }

      int maxDay = _daysInMonth(month, year);
      if (day > maxDay) {
        day = maxDay;
      } else if (day == 0) {
        day = 1;
      }

      final dd = day.toString().padLeft(2, '0');
      final mm = month.toString().padLeft(2, '0');
      final yyyy = year.toString();

      formatted = '$dd/$mm/$yyyy';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  int _daysInMonth(int month, int year) {
    if (month == 2) {
      if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
        return 29;
      }
      return 28;
    }
    if ([4, 6, 9, 11].contains(month)) {
      return 30;
    }
    return 31;
  }
}
