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

  /// ฟังก์ชันลบสินค้า พร้อมยืนยันก่อนลบ
  void _deleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ยืนยันการลบ"),
          content: Text("คุณต้องการลบสินค้า \"${product.name}\" หรือไม่?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // ปิด Dialog
              child: const Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () {
                // ลบสินค้าจาก Hive
                int hiveIndex = productBox!.values.toList().indexOf(product);
                if (hiveIndex != -1) {
                  productBox!.deleteAt(hiveIndex);
                  // อัปเดตรายการสินค้าใน State
                  setState(() {
                    allProducts = productBox!.values.toList();
                  });
                }
                Navigator.pop(context); // ปิด Dialog หลังลบเสร็จ
              },
              child: const Text("ลบ", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// ฟังก์ชันแสดง Dialog สำหรับค้นหาสินค้า
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // ประกาศตัวแปรที่นี่
        String query = '';
        List<ProductModel> searchResults = [];

        return StatefulBuilder(
          builder: (BuildContext context,
              void Function(void Function()) setStateDialog) {
            // ฟังก์ชันค้นหา
            void handleSearch(String value) {
              query = value;
              if (query.isEmpty) {
                searchResults = [];
              } else {
                searchResults = allProducts
                    .where((product) => product.name
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
              }
              setStateDialog(() {}); // รีเฟรชใน Dialog
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "ค้นหาสินค้า",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // ช่องค้นหา
                    TextField(
                      onChanged: handleSearch,
                      decoration: InputDecoration(
                        labelText: "พิมพ์ชื่อสินค้า",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // รายการผลลัพธ์
                    SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: query.isEmpty
                          ? const Center(child: Text("ยังไม่ได้ค้นหา"))
                          : searchResults.isEmpty
                              ? const Center(child: Text("ไม่พบสินค้า"))
                              : ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    var product = searchResults[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(product.name),
                                        subtitle: Text(
                                            "หมวดหมู่: ${product.category}"),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // ปุ่มแก้ไข
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                // อย่า pop dialog ทิ้ง ให้ push ตรง ๆ
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditProductPage(
                                                      product: product,
                                                    ),
                                                  ),
                                                ).then((result) {
                                                  if (result == true) {
                                                    // โหลดข้อมูลใหม่จาก Hive
                                                    setState(() {
                                                      allProducts = productBox!
                                                          .values
                                                          .toList();
                                                    });
                                                    // กรองตาม query เดิม
                                                    setStateDialog(() {
                                                      searchResults = allProducts
                                                          .where((p) => p.name
                                                              .toLowerCase()
                                                              .contains(query
                                                                  .toLowerCase()))
                                                          .toList();
                                                    });
                                                  }
                                                });
                                              },
                                            ),
                                            // ปุ่มลบ
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                int hiveIndex = productBox!
                                                    .values
                                                    .toList()
                                                    .indexOf(product);
                                                if (hiveIndex != -1) {
                                                  productBox!
                                                      .deleteAt(hiveIndex);
                                                  setState(() {
                                                    allProducts = productBox!
                                                        .values
                                                        .toList();
                                                  });
                                                  setStateDialog(() {
                                                    searchResults
                                                        .removeAt(index);
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("ปิด",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        color: const Color.fromARGB(255, 255, 255, 255),
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
                        // แถวสำหรับ Label + ปุ่มค้นหา
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "เลือกหมวดหมู่:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search,
                                  color: Colors.orange),
                              onPressed: _showSearchDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Dropdown สำหรับเลือกหมวดหมู่
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(
                                  child: Text("ไม่มีสินค้าในหมวดหมู่นี้"))
                              : ListView.builder(
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    var product = filteredProducts[index];
                                    bool isExpanded = _expandedIndex ==
                                        index; // เช็คว่าการ์ดนี้ถูกกดอยู่หรือไม่

                                    return Column(
                                      children: [
                                        // การ์ดหลัก
                                        Card(
                                          elevation: 2,
                                          color: Colors
                                              .white, // ✅ ตั้งค่าพื้นหลังของการ์ดให้ขาว
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 5),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                // หากกดซ้ำ ให้ปิดการขยาย
                                                _expandedIndex =
                                                    isExpanded ? null : index;
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // แสดงชื่อสินค้า + ราคาปลีก
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
                                                          color: Color.fromARGB(
                                                              255, 7, 7, 7),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),

                                                  // แสดงหมวดหมู่ + ราคาส่ง
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
                                                left: 0, right: 0, bottom: 5),
                                            child: Container(
                                              width: double
                                                  .infinity, // ✅ ให้ขยายเต็มการ์ด
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 238, 232, 232),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color.fromARGB(
                                                      255, 187, 186, 186),
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // ----- แสดงรายละเอียดสินค้า -----
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "จำนวน: ${product.quantity} ",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
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
                                                  Row(
                                                    children: [
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
                                                      color:
                                                          Colors.grey.shade500),

                                                  // ----- แถวปุ่มแก้ไขและลบ -----
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      // ปุ่มแก้ไข (ดินสอ)
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    12,
                                                                    12,
                                                                    12)),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  EditProductPage(
                                                                      product:
                                                                          product),
                                                            ),
                                                          ).then((result) {
                                                            // ถ้า result เป็น true หมายถึงมีการอัปเดตสินค้า
                                                            if (result ==
                                                                true) {
                                                              setState(() {
                                                                _loadData();
                                                              });
                                                            }
                                                          });
                                                        },
                                                      ),

                                                      // ปุ่มลบ (ถังขยะ)
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.delete,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    5,
                                                                    5,
                                                                    5)),
                                                        onPressed: () {
                                                          // ✅ เรียกฟังก์ชันลบสินค้า (มีตัวอย่างด้านล่าง)
                                                          _deleteProduct(
                                                              product);
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
