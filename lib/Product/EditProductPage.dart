import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Database/product_model.dart';
import '../Database/category_model.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product;

  const EditProductPage({super.key, required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  Box<ProductModel>? productBox;
  Box<CategoryModel>? categoryBox;
  List<String> _categories = [];
  String? _selectedCategory;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _Retail_priceController = TextEditingController();
  final TextEditingController _Wholesale_priceController =
      TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    productBox = Hive.box<ProductModel>('products');
    categoryBox = Hive.box<CategoryModel>('categories');
    _loadCategories();

    // เติมค่าข้อมูลที่ต้องแก้ไข
    _productNameController.text = widget.product.name;
_Retail_priceController.text = widget.product.retailPrice.toString();
_Wholesale_priceController.text = widget.product.wholesalePrice.toString();
    _barcodeController.text = widget.product.barcode ?? '';
    _selectedCategory = widget.product.category;
  }

  void _loadCategories() {
    setState(() {
      _categories = categoryBox!.values.map((c) => c.name).toList();
    });
  }

void _updateProduct() {
  final updatedProduct = ProductModel(
    id: widget.product.id, // ต้องคง ID เดิมไว้
    name: _productNameController.text.trim(),
    retailPrice: double.tryParse(_Retail_priceController.text) ?? 0,
    wholesalePrice: double.tryParse(_Wholesale_priceController.text) ?? 0,
    category: _selectedCategory ?? "ไม่ระบุ",
    barcode: _barcodeController.text.trim(),
    imageUrl: widget.product.imageUrl,
  );

  int index = productBox!.values.toList().indexOf(widget.product);
  if (index != -1) {
    productBox!.putAt(index, updatedProduct);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("อัปเดตสินค้าสำเร็จ")),
    );
    Navigator.pop(context, true);
  }
}

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
    );

    if (result != null && result != '-1') {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      print("✅ อนุญาตใช้กล้องแล้ว");
    } else {
      print("❌ ปฏิเสธการใช้กล้อง");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TPrimaryHeaderContainer(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "แก้ไขรายการสินค้า",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "เลือกหมวดหมู่:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
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
                        _buildTextField(
                            controller: _productNameController,
                            label: "ชื่อสินค้า"),
                        _buildTextField(
                            controller: _Retail_priceController,
                            label: "ราคาปลีก"),
                        _buildTextField(
                            controller: _Wholesale_priceController,
                            label: "ราคาส่ง"),
                        TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: "บาร์โค้ดสินค้า",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(Icons.qr_code_scanner,
                                  color: Colors.blue),
                              onPressed: _scanBarcode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _updateProduct,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.orange,
                            ),
                            child: Text("บันทึกการแก้ไข",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
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
      bottomNavigationBar: BottomNavbar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
