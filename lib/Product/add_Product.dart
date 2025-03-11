import 'package:flutter/material.dart';

import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';

class MyAddProduct extends StatefulWidget {
  const MyAddProduct({super.key});

  @override
  State<MyAddProduct> createState() => _MyAddProductState();
}

class _MyAddProductState extends State<MyAddProduct> {
  int _selectedIndex = 0;

  /// รายการหมวดหมู่สินค้า
  final List<String> _categories = [];

  /// เก็บค่าหมวดหมู่ที่เลือก
  String? _selectedCategory;

  /// ตัวควบคุม TextField
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  /// ฟังก์ชันเปลี่ยนหน้าใน BottomNavBar
  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// ฟังก์ชันเปิด Dialog สำหรับสร้างหมวดหมู่ใหม่
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
            onPressed: () => Navigator.pop(context), // ปิด Popup
            child: Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () {
              String newCategory = categoryController.text.trim();
              if (newCategory.isNotEmpty) {
                setState(() {
                  _categories.add(newCategory); // เพิ่มหมวดหมู่ใหม่ใน List
                  _selectedCategory = newCategory; // เลือกหมวดหมู่ใหม่ทันที
                });
              }
              Navigator.pop(context); // ปิด Popup
            },
            child: Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชันเปิด Dialog สำหรับจัดการ (แก้ไข/ลบ) หมวดหมู่ที่มีอยู่
  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("จัดการหมวดหมู่"),
          content: SizedBox(
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
      /// ใช้ Container คลุมทั้งหมด และตั้งค่าพื้นหลังเป็นสีขาว
      body: Container(
        color: Colors.white, // พื้นหลังสีขาวทั้งหมด
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500), // จำกัดความกว้าง
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// ส่วนหัว
                  TPrimaryHeaderContainer(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "เพิ่มรายการสินค้า",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 252, 250, 250)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Container สีขาว
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// แถวที่มี "สร้างหมวดหมู่ใหม่" และไอคอนดินสอ
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

                        /// เลือกหมวดหมู่
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

                        /// ชื่อสินค้า
                        _buildTextField(
                          controller: _productNameController,
                          label: "ชื่อสินค้า",
                        ),

                        /// ราคา
                        _buildTextField(
                          controller: _priceController,
                          label: "ราคา",
                          keyboardType: TextInputType.number,
                        ),

                        /// จำนวน
                        _buildTextField(
                          controller: _quantityController,
                          label: "จำนวน",
                          keyboardType: TextInputType.number,
                        ),

                        /// วันหมดอายุ
                        _buildTextField(
                          controller: _expiryDateController,
                          label: "วันหมดอายุ (ตัวอย่าง: 2025-12-31)",
                          keyboardType: TextInputType.datetime,
                        ),

                        const SizedBox(height: 20),

                        /// ปุ่มบันทึก
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final category = _selectedCategory;
                              final productName = _productNameController.text;
                              final price = _priceController.text;
                              final quantity = _quantityController.text;
                              final expiryDate = _expiryDateController.text;

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("ผลลัพธ์การบันทึก"),
                                  content: Text(
                                    "หมวดหมู่: $category\n"
                                    "ชื่อสินค้า: $productName\n"
                                    "ราคา: $price\n"
                                    "จำนวน: $quantity\n"
                                    "วันหมดอายุ: $expiryDate",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("ปิด"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                            child: Text(
                              "บันทึกสินค้า",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
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

      /// แถบเมนูด้านล่าง
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }

  /// Widget สำหรับสร้าง TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
      ),
    );
  }

  /// ฟังก์ชันสร้าง InputDecoration ที่มีขอบโค้งมน
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
