import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import '../Database/product_model.dart';

class EditStockProduct extends StatefulWidget {
  const EditStockProduct({Key? key}) : super(key: key);

  @override
  _EditStockProductState createState() => _EditStockProductState();
}

class _EditStockProductState extends State<EditStockProduct> {
  Box<ProductModel>? productBox;
  List<ProductModel> allProducts = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    productBox = Hive.box<ProductModel>('products');
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      allProducts = productBox!.values.toList();
    });
  }

  /// ฟังก์ชันแก้ไขจำนวนสินค้า: เปิด AlertDialog เพื่อแก้ไขจำนวนในสต็อก
  void _editStock(ProductModel product) {
    TextEditingController stockController =
        TextEditingController(text: product.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("แก้ไขจำนวนสินค้า: ${product.name}"),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "จำนวนสินค้า",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              int? newStock = int.tryParse(stockController.text);
              if (newStock != null) {
                final updatedProduct = ProductModel(
                  name: product.name,
                  Retail_price: product.Retail_price,
                  Wholesale_price: product.Wholesale_price,
                  quantity: newStock,
                  expiryDate: product.expiryDate,
                  category: product.category,
                  barcode: product.barcode,
                );
                int index = productBox!.values.toList().indexOf(product);
                if (index != -1) {
                  productBox!.putAt(index, updatedProduct);
                  _loadProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("แก้ไขจำนวนสินค้าเรียบร้อย")),
                  );
                }
                Navigator.pop(context);
              }
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  /// สร้างการ์ดสำหรับแต่ละรายการสินค้า (แสดงชื่อ, จำนวน พร้อมไอคอนแก้ไข และหมวดหมู่)
  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวแรก: ชื่อสินค้า, จำนวน และไอคอนแก้ไข
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
                      "จำนวน: ${product.quantity}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Color.fromARGB(255, 5, 5, 5)),
                      onPressed: () {
                        _editStock(product);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // แถวที่สอง: แสดงหมวดหมู่ (ใต้ชื่อสินค้า)
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
