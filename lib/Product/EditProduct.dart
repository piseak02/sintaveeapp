import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import '../Database/product_model.dart';
import '../Database/category_model.dart';
import '../Bottoom_Navbar/bottom_navbar.dart';
import '../Product/EditProductPage.dart';

class EditProduct extends StatefulWidget {
  const EditProduct({super.key});

  @override
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  Box<ProductModel>? productBox;
  Box<CategoryModel>? categoryBox;

  int? _expandedIndex; // เก็บ index ของการ์ดที่ถูกกด
  List<String> categories = ["ทั้งหมด"];
  String selectedCategory = "ทั้งหมด";
  List<ProductModel> allProducts = [];

  /// สำหรับเก็บข้อความค้นหา
  String searchQuery = "";

  /// สำหรับควบคุมการแสดง/ซ่อน Dropdown
  bool showDropdown = false;

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
                      "แก้ไขรายการสินค้า",
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

                        // ปุ่มตัวกรอง (Filter)
                        // ปุ่มตัวกรอง (Filter)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // กดแล้วให้แสดง Modal Bottom Sheet ขึ้นมา
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
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

                                      // แสดงรายการหมวดหมู่
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
                                                // ปิด Bottom Sheet
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
                            icon: const Icon(Icons.filter_list),
                            label: Text("หมวดหมู่: $selectedCategory"),
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
                                    bool isExpanded = _expandedIndex == index;

                                    return Column(
                                      children: [
                                        // การ์ดหลัก
                                        Card(
                                          elevation: 2,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                // หากกดซ้ำ ให้ปิดการขยาย
                                                _expandedIndex =
                                                    isExpanded ? null : index;
                                              });
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
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
                                                        "${product.Retail_price} บาท",
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.orange,
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
                                                        "ราคาส่ง: ${product.Wholesale_price} บาท",
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
                                        ),

                                        // แสดงรายละเอียดเพิ่มเติมเมื่อการ์ดถูกกด
                                        if (isExpanded)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                              right: 12,
                                              bottom: 5,
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // จำนวน
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.inventory,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "จำนวน: ${product.quantity}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // วันหมดอายุ
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.calendar_today,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "วันหมดอายุ: ${product.expiryDate ?? 'ไม่มีข้อมูล'}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // บาร์โค้ด
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.qr_code,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "บาร์โค้ด: ${product.barcode ?? '-'}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Divider(
                                                    thickness: 1,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  // ปุ่มแก้ไข + ลบ ย้ายมาไว้ในนี้
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.blue,
                                                        ),
                                                        onPressed: () {
                                                          // ไปหน้าแก้ไขสินค้า
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  EditProductPage(
                                                                product:
                                                                    product,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          int hiveIndex =
                                                              productBox!.values
                                                                  .toList()
                                                                  .indexOf(
                                                                      product);
                                                          if (hiveIndex != -1) {
                                                            productBox!
                                                                .deleteAt(
                                                                    hiveIndex);
                                                            setState(() {
                                                              allProducts =
                                                                  productBox!
                                                                      .values
                                                                      .toList();
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
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
