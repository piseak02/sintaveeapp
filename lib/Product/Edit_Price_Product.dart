import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import '../Database/product_model.dart';

class EditPriceProduct extends StatefulWidget {
  const EditPriceProduct({Key? key}) : super(key: key);

  @override
  _EditPriceProductState createState() => _EditPriceProductState();
}

class _EditPriceProductState extends State<EditPriceProduct> {
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

  /// ฟังก์ชันแก้ไขราคา: เปิด AlertDialog เพื่อแก้ไขราคาปลีกและราคาส่ง
  void _editPrice(ProductModel product) {
    TextEditingController retailPriceController =
        TextEditingController(text: product.Retail_price.toString());
    TextEditingController wholesalePriceController =
        TextEditingController(text: product.Wholesale_price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("แก้ไขราคา: ${product.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: retailPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ราคาปลีก",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: wholesalePriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ราคาส่ง",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              double? newRetail = double.tryParse(retailPriceController.text);
              double? newWholesale =
                  double.tryParse(wholesalePriceController.text);
              if (newRetail != null && newWholesale != null) {
                final updatedProduct = ProductModel(
                  name: product.name,
                  Retail_price: newRetail,
                  Wholesale_price: newWholesale,
                  quantity: product.quantity,
                  expiryDate: product.expiryDate,
                  category: product.category,
                  barcode: product.barcode,
                );
                int index = productBox!.values.toList().indexOf(product);
                if (index != -1) {
                  productBox!.putAt(index, updatedProduct);
                  _loadProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("แก้ไขราคาเรียบร้อย")),
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

  /// สร้างการ์ดสำหรับแต่ละรายการสินค้า (แสดงชื่อ, จำนวนพร้อมไอคอนแก้ไข และหมวดหมู่)
  Widget _buildProductCard(ProductModel product) {
    const double priceContainerWidth = 100;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวแรก: ชื่อสินค้าและราคาปลีก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ชื่อสินค้า
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // ราคาปลีก
                Container(
                  width: priceContainerWidth,
                  alignment: Alignment.centerRight,
                  child: RichText(
                    textAlign: TextAlign.end,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: "${product.Retail_price} "),
                        const TextSpan(text: "ราคาปลีก"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // แถวที่สอง: หมวดหมู่และราคาส่ง
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "หมวดหมู่: ${product.category}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  width: priceContainerWidth,
                  alignment: Alignment.centerRight,
                  child: RichText(
                    textAlign: TextAlign.end,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      children: [
                        TextSpan(text: "${product.Wholesale_price} "),
                        const TextSpan(text: "ราคาส่ง"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // แถวที่สาม: ไอคอนดินสอ (Edit) อยู่ชิดขวา
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: Color.fromARGB(255, 0, 0, 0)),
                  onPressed: () {
                    _editPrice(product);
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
    return Scaffold(
      body: Column(
        children: [
          // ส่วนหัวที่ใช้ PrimaryHeaderContainer
          TPrimaryHeaderContainer(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "แก้ไขราคาสินค้า",
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
