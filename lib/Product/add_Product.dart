import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Database/product_model.dart';
import '../Database/category_model.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../Database/lot_model.dart';


class MyAddProduct extends StatefulWidget {
  const MyAddProduct({super.key});

  @override
  State<MyAddProduct> createState() => _MyAddProductState();
}

class _MyAddProductState extends State<MyAddProduct> {
  int _selectedIndex = 0;
  Box<ProductModel>? productBox;
  Box<CategoryModel>? categoryBox;
  List<String> _categories = [];
  String? _selectedCategory;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _Retail_priceController = TextEditingController();
  final TextEditingController _Wholesale_priceController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestCameraPermission(); // ✅ ขออนุญาตกล้องเมื่อเปิดหน้า
    productBox = Hive.box<ProductModel>('products');
    categoryBox = Hive.box<CategoryModel>('categories');
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = categoryBox!.values.map((c) => c.name).toList();
    });
  }

void _addProduct() async {
  final name = _productNameController.text.trim();
  final retailPrice = double.tryParse(_Retail_priceController.text) ?? 0;
  final wholesalePrice = double.tryParse(_Wholesale_priceController.text) ?? 0;
  final quantity = int.tryParse(_quantityController.text) ?? 0;
  final expiryDateStr = _expiryDateController.text.trim();
  final category = _selectedCategory ?? "ไม่ระบุ";
  final barcode = _barcodeController.text.trim();

  if (name.isEmpty || expiryDateStr.isEmpty || quantity <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน")),
    );
    return;
  }

  try {
    final parts = expiryDateStr.split('/');
    final expiryDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );

    // อ่าน counter id ปัจจุบันจาก Hive หรือใช้ 0 ถ้ายังไม่มี
    final settingsBox = await Hive.openBox('settings');
    int currentId = settingsBox.get('productIdCounter', defaultValue: 0);

    final newProductId = (currentId + 1).toString(); // เช่น "1", "2", "3" ...

    final newProduct = ProductModel(
      id: newProductId,
      name: name,
      retailPrice: retailPrice,
      wholesalePrice: wholesalePrice,
      category: category,
      barcode: barcode,
    );

    await productBox!.add(newProduct);

    final newLot = LotModel(
      lotId: "LOT-${DateTime.now().millisecondsSinceEpoch}",
      productId: newProductId,
      quantity: quantity,
      expiryDate: expiryDate,
      recordDate: DateTime.now(),
    );

    final lotBox = Hive.box<LotModel>('lots');
    await lotBox.add(newLot);

    // บันทึก counter ใหม่กลับไป
    await settingsBox.put('productIdCounter', currentId + 1);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("เพิ่มสินค้าสำเร็จ")),
    );

    _clearFields();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("บันทึก")),
    );
  }
}

  void _clearFields() {
    _productNameController.clear();
    _Retail_priceController.clear();
    _Wholesale_priceController.clear();
    _quantityController.clear();
    _expiryDateController.clear();
    _barcodeController.clear();
    setState(() {
      _selectedCategory = null;
    });
  }

  void _addCategory(String category) {
    if (category.isNotEmpty &&
        !categoryBox!.values.any((c) => c.name == category)) {
      categoryBox!.add(CategoryModel(name: category));
      _loadCategories();
    }
  }

  void _showAddCategoryDialog() {
    TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("สร้างหมวดหมู่ใหม่"),
        content: TextField(
          controller: categoryController,
          decoration: InputDecoration(
            labelText: "ชื่อหมวดหมู่",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () {
              String newCategory = categoryController.text.trim();
              if (newCategory.isNotEmpty) {
                _addCategory(newCategory);
                setState(() {
                  _selectedCategory = newCategory;
                });
              }
              Navigator.pop(context);
            },
            child: Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("จัดการหมวดหมู่"),
              content: SizedBox(
                width: double.maxFinite,
                child: _categories.isEmpty
                    ? Center(child: Text("ยังไม่มีหมวดหมู่"))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return ListTile(
                            title: Text(cat),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ปุ่มแก้ไข
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    TextEditingController editController =
                                        TextEditingController(text: cat);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("แก้ไขหมวดหมู่"),
                                        content: TextField(
                                          controller: editController,
                                          decoration: InputDecoration(
                                            labelText: "ชื่อหมวดหมู่ใหม่",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text("ยกเลิก"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              String newName =
                                                  editController.text.trim();
                                              if (newName.isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          "กรุณากรอกชื่อหมวดหมู่ใหม่")),
                                                );
                                                return;
                                              }
                                              // อัปเดตใน categoryBox
                                              await categoryBox!.putAt(index,
                                                  CategoryModel(name: newName));

                                              // อัปเดตชื่อหมวดหมู่ในสินค้า (ProductModel) ที่มีหมวดหมู่นี้
                                              for (var entry in productBox!
                                                  .toMap()
                                                  .entries) {
                                                ProductModel prod = entry.value;
                                                if (prod.category == cat) {
                                                  ProductModel updatedProd =
                                                      ProductModel(
                                                    id: prod.id,
                                                    name: prod.name,
                                                    retailPrice:
                                                        prod.retailPrice,
                                                    wholesalePrice:
                                                        prod.wholesalePrice,
                                                    category: newName,
                                                    barcode: prod.barcode,
                                                    imageUrl: prod.imageUrl,
                                                  );
                                                  await productBox!.put(
                                                      entry.key, updatedProd);
                                                }
                                              }

                                              // อัปเดต _categories และ _selectedCategory ใน UI
                                              setState(() {
                                                _categories[index] = newName;
                                                if (_selectedCategory == cat) {
                                                  _selectedCategory = newName;
                                                }
                                              });
                                              setStateDialog(() {});
                                              Navigator.pop(
                                                  context); // ปิด dialog แก้ไข
                                            },
                                            child: Text("บันทึก"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                // ปุ่มลบ
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("ยืนยันการลบ"),
                                        content: Text(
                                            "ต้องการลบหมวดหมู่ \"$cat\" หรือไม่? สินค้าในหมวดนี้จะถูกลบด้วย"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text("ยกเลิก"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text("ลบ",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      // ลบหมวดหมู่จาก Hive
                                      await categoryBox!.deleteAt(index);
                                      // ลบสินค้าที่อยู่ในหมวดนี้ออกจาก productBox
                                      List keysToDelete = [];
                                      for (var entry
                                          in productBox!.toMap().entries) {
                                        ProductModel prod = entry
                                            .value; // entry.value มีชนิด ProductModel
                                        if (prod.category == cat) {
                                          keysToDelete.add(entry.key);
                                        }
                                      }
                                      for (var key in keysToDelete) {
                                        await productBox!.delete(key);
                                      }
                                      setState(() {
                                        _categories.removeAt(index);
                                        if (_selectedCategory == cat) {
                                          _selectedCategory = null;
                                        }
                                      });
                                      setStateDialog(() {});
                                    }
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
                  child: Text("ปิด"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
    );

    if (result != null && result != '-1') {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      print("✅ อนุญาตใช้กล้องแล้ว");
    } else {
      print("❌ ปฏิเสธการใช้กล้อง");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TPrimaryHeaderContainer(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "เพิ่มรายการสินค้า",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _showAddCategoryDialog,
                              child: Text(
                                "สร้างหมวดหมู่ใหม่",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              tooltip: "จัดการหมวดหมู่",
                              onPressed: _showManageCategoriesDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration("เลือกหมวดหมู่"),
                          value: _selectedCategory,
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                            controller: _productNameController,
                            label: "ชื่อสินค้า"),
                        _buildTextField(
                            controller: _Retail_priceController,
                            label: "ราคาปลีก",
                            keyboardType: TextInputType.number),
                        _buildTextField(
                            controller: _Wholesale_priceController,
                            label: "ราคาส่ง",
                            keyboardType: TextInputType.number),
                        _buildTextField(
                            controller: _quantityController,
                            label: "จำนวน",
                            keyboardType: TextInputType.number),
                        _buildTextField(
                          controller: _expiryDateController,
                          label: "วันหมดอายุ วัน/เดือน/ปี (ค.ศ.)",
                          keyboardType: TextInputType.number,
                          inputFormatters: [DateInputFormatter()],
                        ),
                        TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: "บาร์โค้ดสินค้า",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              // ✅ ปุ่มสแกนอยู่ในช่องกรอก
                              icon: Icon(Icons.qr_code_scanner,
                                  color: Colors.blue),
                              onPressed:
                                  _scanBarcode, // ✅ เรียกฟังก์ชันสแกนบาร์โค้ด
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addProduct,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                            child: Text("บันทึกสินค้า",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white);
  }
}

// ✅ ตัวจัดรูปแบบวันที่แบบ dd/MM/yyyy
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

    // ล็อกค่าให้ถูกต้องถ้าครบ dd/MM/yyyy แล้ว
    if (digitsOnly.length == 8) {
      int day = int.parse(digitsOnly.substring(0, 2));
      int month = int.parse(digitsOnly.substring(2, 4));
      int year = int.parse(digitsOnly.substring(4, 8));

      // ปรับเดือนถ้าเกิน 12
      if (month > 12) {
        month = 12;
      } else if (month == 0) {
        month = 1;
      }

      // ตรวจสอบจำนวนวันในเดือน
      int maxDay = _daysInMonth(month, year);

      if (day > maxDay) {
        day = maxDay;
      } else if (day == 0) {
        day = 1;
      }

      // จัดข้อความใหม่หลังตรวจสอบ
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

  /// ตรวจสอบจำนวนวันในเดือน (รองรับปีอธิกสุรทิน)
  int _daysInMonth(int month, int year) {
    if (month == 2) {
      // กุมภาพันธ์
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
