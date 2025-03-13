import 'package:flutter/material.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/database_project/database_helper.dart';

class MyAddProduct extends StatefulWidget {
  const MyAddProduct({super.key});

  @override
  State<MyAddProduct> createState() => _MyAddProductState();
}

class _MyAddProductState extends State<MyAddProduct> {
  int _selectedIndex = 0;
  final List<String> _categories = [];
  String? _selectedCategory;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  void onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  /// ฟังก์ชันเพิ่มหมวดหมู่ใหม่
  void _showAddCategoryDialog() {
    TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("สร้างหมวดหมู่ใหม่"),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: "ชื่อหมวดหมู่",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () {
              String newCategory = categoryController.text.trim();
              if (newCategory.isNotEmpty) {
                setState(() {
                  _categories.add(newCategory);
                  _selectedCategory = newCategory;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชันจัดการหมวดหมู่
  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("จัดการหมวดหมู่"),
          content: Container(
            width: double.maxFinite, // ให้ Dialog ขยายตามเนื้อหา
            child: _categories.isEmpty
                ? Center(
                    child: Text("ยังไม่มีหมวดหมู่"),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return ListTile(
                        title: Text(cat),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              // ถ้าหมวดหมู่ที่ลบเป็นอันเดียวกับที่เลือกอยู่ ให้ลบการเลือกด้วย
                              if (_selectedCategory == cat) {
                                _selectedCategory = null;
                              }
                              _categories.removeAt(index);
                            });
                          },
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TPrimaryHeaderContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "เพิ่มรายการสินค้า",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildForm(),
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

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _showAddCategoryDialog,
                child: const Text(
                  "สร้างหมวดหมู่ใหม่",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
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
              setState(() => _selectedCategory = newValue);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
              controller: _productNameController, label: "ชื่อสินค้า"),
          _buildTextField(
              controller: _priceController,
              label: "ราคา",
              keyboardType: TextInputType.number),
          _buildTextField(
              controller: _quantityController,
              label: "จำนวน",
              keyboardType: TextInputType.number),
          _buildTextField(
              controller: _expiryDateController,
              label: "วันหมดอายุ (ตัวอย่าง: 2025-12-31)",
              keyboardType: TextInputType.datetime),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orange,
              ),
              child: const Text("บันทึกสินค้า",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _saveProduct() async {
    if (_selectedCategory == null ||
        _productNameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _expiryDateController.text.isEmpty) {
      // แจ้งเตือนถ้ายังกรอกไม่ครบ
      _showAlertDialog("แจ้งเตือน", "กรุณากรอกข้อมูลให้ครบถ้วน");
      return;
    }

    // เตรียมข้อมูลสินค้า
    Map<String, dynamic> product = {
      'category': _selectedCategory,
      'name': _productNameController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'expiryDate': _expiryDateController.text,
    };

    // เรียกใช้งาน DatabaseHelper
    final dbHelper = DatabaseHelper();
    int newId = await dbHelper.insertProduct(product); // บันทึกลง DB

    // แจ้งเตือนว่าเพิ่มสำเร็จ
    _showAlertDialog("บันทึกสำเร็จ", "เพิ่มสินค้าเรียบร้อย! ID = $newId",
        clearFields: true);
  }

  void _showAlertDialog(String title, String message,
      {bool clearFields = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (clearFields) {
                setState(() {
                  _selectedCategory = null;
                  _productNameController.clear();
                  _priceController.clear();
                  _quantityController.clear();
                  _expiryDateController.clear();
                });
              }
            },
            child: Text("ตกลง"),
          ),
        ],
      ),
    );
  }
}
