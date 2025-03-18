import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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

  int _selectedIndex = 2; // ตั้งค่าให้แท็บเริ่มต้นอยู่ที่หน้า "เมนูหลัก"

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
      appBar: AppBar(
        title: Text("แก้ไขสินค้า"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Dropdown สำหรับเลือกหมวดหมู่
            Text("เลือกหมวดหมู่:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
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
            SizedBox(height: 20),

            /// แสดงรายการสินค้า
            Text("รายการสินค้า:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(child: Text("ไม่มีสินค้าในหมวดหมู่นี้"))
                  : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        var product = filteredProducts[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(product.name,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            subtitle: Text("หมวดหมู่: ${product.category}"),
                            trailing: Text("${product.price} บาท",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
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

      /// แถบเมนูด้านล่าง
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
