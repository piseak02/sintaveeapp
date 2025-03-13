import 'package:flutter/material.dart';

class EditProduct extends StatefulWidget {
  const EditProduct({super.key});

  @override
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  // หมวดหมู่สินค้า (ตัวอย่างข้อมูล)
  final List<String> categories = ["ทั้งหมด", "เครื่องดื่ม", "ขนม", "อาหารสด"];

  // หมวดหมู่ที่เลือก
  String selectedCategory = "ทั้งหมด";

  // รายการสินค้า (ข้อมูลปลอม)
  final List<Map<String, dynamic>> allProducts = [
    {"name": "โค้ก", "category": "เครื่องดื่ม", "price": 20},
    {"name": "เป๊ปซี่", "category": "เครื่องดื่ม", "price": 18},
    {"name": "มันฝรั่งทอด", "category": "ขนม", "price": 30},
    {"name": "ข้าวกล่อง", "category": "อาหารสด", "price": 50},
    {"name": "น้ำแร่", "category": "เครื่องดื่ม", "price": 15},
    {"name": "เค้กช็อคโกแลต", "category": "ขนม", "price": 55},
  ];

  @override
  Widget build(BuildContext context) {
    // กรองสินค้าโดยดูจากหมวดหมู่ที่เลือก
    List<Map<String, dynamic>> filteredProducts = selectedCategory == "ทั้งหมด"
        ? allProducts
        : allProducts.where((product) => product["category"] == selectedCategory).toList();

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
            // Dropdown สำหรับเลือกหมวดหมู่
            Text("เลือกหมวดหมู่:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

            // แสดงรายการสินค้า
            Text("รายการสินค้า:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  var product = filteredProducts[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(product["name"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: Text("หมวดหมู่: ${product["category"]}"),
                      trailing: Text("${product["price"]} บาท", style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                      onTap: () {
                        // สามารถเพิ่มโค้ดแก้ไขสินค้าเมื่อกดได้
                        print("แก้ไข: ${product["name"]}");
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
