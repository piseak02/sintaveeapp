import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Database/product_model.dart';
import '../Database/category_model.dart';

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
      // โหลดหมวดหมู่จาก Hive และเพิ่ม "ทั้งหมด" ไว้เป็นตัวเลือกแรก
      categories = [
        "ทั้งหมด",
        ...categoryBox!.values.map((c) => c.name).toList()
      ];

      // โหลดสินค้า
      allProducts = productBox!.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // กรองสินค้าโดยดูจากหมวดหมู่ที่เลือก
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
                              // สามารถเพิ่มโค้ดแก้ไขสินค้าเมื่อกดได้
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
    );
  }
}
