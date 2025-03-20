import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import '../Database/product_model.dart';
import '../Database/category_model.dart';
import '../Bottoom_Navbar/bottom_navbar.dart';

class EditProduct extends StatefulWidget {
  const EditProduct({super.key});

  @override
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  Box<ProductModel>? productBox;
  Box<CategoryModel>? categoryBox;

  List<String> categories = ["ทั้งหมด"];
  String selectedCategory = "ทั้งหมด";
  List<ProductModel> allProducts = [];

  int _selectedIndex = 0; // ตั้งค่าให้แท็บเริ่มต้นอยู่ที่หน้า "เมนูหลัก"

  @override
  void initState() {
    super.initState();
    productBox = Hive.box<ProductModel>('products');
    categoryBox = Hive.box<CategoryModel>('categories');
    _loadData();
  }

  /// โหลดข้อมูลสินค้าและหมวดหมู่จาก Hive
  void _loadData() {
    setState(() {
      categories = [
        "ทั้งหมด",
        ...categoryBox!.values.map((c) => c.name).toList()
      ];
      allProducts = productBox!.values.toList();
    });
  }

  /// ฟังก์ชันเปลี่ยนหน้าใน BottomNavBar
  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // นำทางไปยังหน้าต่าง ๆ ตามปุ่มที่กด
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/account');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ProductModel> filteredProducts = selectedCategory == "ทั้งหมด"
        ? allProducts
        : allProducts
            .where((product) => product.category == selectedCategory)
            .toList();

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // ส่วนหัวแสดงชื่อ "เพิ่มรายการสินค้า"
                TPrimaryHeaderContainer(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "แก้ไขรายการสินค้า",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // ส่วนเนื้อหาหลัก
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dropdown สำหรับเลือกหมวดหมู่
                        const Text(
                          "เลือกหมวดหมู่:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          onChanged: (newValue) {
                            setState(() {
                              selectedCategory = newValue!;
                            });
                          },
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        // แสดงรายการสินค้า
                        const Text(
                          "รายการสินค้า:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        // ใช้ Expanded ครอบ ListView เพื่อให้แสดงผลเต็มพื้นที่ที่เหลือ
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(
                                  child: Text("ไม่มีสินค้าในหมวดหมู่นี้"))
                              : ListView.builder(
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    var product = filteredProducts[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: ListTile(
                                        title: Text(
                                          product.name,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                            "หมวดหมู่: ${product.category}"),
                                        trailing: Text(
                                          "${product.price} บาท",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onTap: () {
                                          print("แก้ไข: ${product.name}");
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // แถบเมนูด้านล่าง
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
