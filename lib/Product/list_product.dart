import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import '../Database/product_model.dart';
import '../Database/category_model.dart';
import '../Bottoom_Navbar/bottom_navbar.dart';
import '../Product/list_detailPage.dart';
import '../Database/lot_model.dart';

class List_Product extends StatefulWidget {
  const List_Product({super.key});

  @override
  _List_ProductState createState() => _List_ProductState();
}

class _List_ProductState extends State<List_Product> {
  Box<LotModel>? lotBox;
  Box<ProductModel>? productBox;
  Box<CategoryModel>? categoryBox;

  // ✅ ลบตัวแปร _expandedIndex
  // int? _expandedIndex;

  List<String> categories = ["ทั้งหมด"];
  String selectedCategory = "ทั้งหมด";
  List<ProductModel> allProducts = [];

  String searchQuery = ""; // ข้อความค้นหา
  bool showDropdown = false;

  int _selectedIndex = 0; // ตั้งค่าให้แท็บเริ่มต้นอยู่ที่หน้า "เมนูหลัก"

  @override
  void initState() {
    super.initState();
    productBox = Hive.box<ProductModel>('products');
    categoryBox = Hive.box<CategoryModel>('categories');
    lotBox = Hive.box<LotModel>('lots');
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

  @override
  Widget build(BuildContext context) {
    // กรองสินค้าตาม searchQuery + หมวดหมู่
    List<ProductModel> filteredProducts = allProducts.where((product) {
      final matchCategory = (selectedCategory == "ทั้งหมด")
          ? true
          : product.category == selectedCategory;
      final matchSearch =
          product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // ส่วนหัว
                TPrimaryHeaderContainer(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "แสดงรายการสินค้า",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // ส่วนเนื้อหา
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TextField สำหรับค้นหา
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: "ค้นหา...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ปุ่มตัวกรอง (Filter) -> เลือกหมวดหมู่
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                builder: (BuildContext context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          "เลือกหมวดหมู่",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: categories.length,
                                          itemBuilder: (context, index) {
                                            final category = categories[index];
                                            return ListTile(
                                              title: Text(category),
                                              onTap: () {
                                                setState(() {
                                                  selectedCategory = category;
                                                });
                                                Navigator.pop(context);
                                              },
                                            );
                                          },
                                        ),
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.filter_list,
                              color: Colors.black,
                            ),
                            label: Text(
                              "หมวดหมู่: $selectedCategory",
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // แสดงรายการสินค้า
                        const Text(
                          "รายการสินค้า:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(
                                  child: Text("ไม่มีสินค้าในหมวดหมู่นี้"),
                                )
                              : ListView.builder(
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    var product = filteredProducts[index];

                                    return Card(
                                      elevation: 2,
                                      color: Colors.white,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: InkWell(
                                        // ✅ เมื่อกด -> ไปหน้าใหม่ ProductDetailPage
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailPage(
                                                product: product,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // ชื่อสินค้า + ราคาปลีก
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${product.retailPrice} บาท",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),

                                              // หมวดหมู่ + ราคาส่ง
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "หมวดหมู่: ${product.category}",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    "ราคาส่ง: ${product.wholesalePrice} บาท",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
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

      // Bottom Navigation Bar
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
