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
              final lotId = "LOT-${now.year}${now.month.toString().padLeft(2, '0')}"
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

  /// สร้างการ์ดสำหรับแต่ละรายการสินค้า (แสดงชื่อ, จำนวนคงเหลือ จาก LotModel, และหมวดหมู่)
  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวแรก: ชื่อสินค้า, จำนวนคงเหลือ, และไอคอนแก้ไข (เพิ่มล็อต)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      "จำนวน: ${_getTotalQuantity(product.id)}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _editStock(product);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // แถวที่สอง: แสดงหมวดหมู่
            Text(
              "หมวดหมู่: ${product.category}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ส่วนหัวด้วย PrimaryHeaderContainer
          TPrimaryHeaderContainer(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "แก้ไขจำนวนสินค้า",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          // รายการสินค้าใน ListView
          Expanded(
            child: allProducts.isEmpty
                ? const Center(child: Text("ไม่มีสินค้า"))
                : ListView.builder(
                    itemCount: allProducts.length,
                    itemBuilder: (context, index) {
                      final product = allProducts[index];
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
