import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import '../Database/supplier_model.dart';
import '../Database/supplier_name_model.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';

class add_Supplier extends StatefulWidget {
  const add_Supplier({Key? key}) : super(key: key);

  @override
  _addSupplierState createState() => _addSupplierState();
}

class _addSupplierState extends State<add_Supplier> {
  // ... โค้ดส่วนอื่นๆ ยังคงเหมือนเดิม ...
  final TextEditingController _paymentController = TextEditingController();

  List<File> _billImageFiles = [];

  late Box<SupplierModel> _supplierBox;
  List<String> _supplierNames = [];
  String? _selectedSupplierName;

  int _selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _supplierBox = Hive.box<SupplierModel>('suppliers');
    _loadSuppliers();
    _requestCameraPermission();
  }

  void _loadSuppliers() {
    final supplierNameBox = Hive.box<SupplierNameModel>('supplierNames');
    setState(() {
      _supplierNames = supplierNameBox.values.map((s) => s.name).toList();
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาให้สิทธิ์ใช้งานกล้อง")),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _billImageFiles.add(File(pickedFile.path));
      });
    }
  }

  void _createNewSupplierName() {
    final TextEditingController newNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("สร้างชื่อซัพพายเออร์"),
          content: TextField(
            controller: newNameController,
            decoration: const InputDecoration(
              labelText: "ชื่อซัพพายเออร์ใหม่",
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
                final newName = newNameController.text.trim();
                if (newName.isNotEmpty) {
                  final supplierNameBox =
                      Hive.box<SupplierNameModel>('supplierNames');
                  if (!supplierNameBox.values.any((s) => s.name == newName)) {
                    supplierNameBox.add(SupplierNameModel(name: newName));
                    setState(() {
                      _supplierNames.add(newName);
                      _selectedSupplierName = newName;
                    });
                  }
                }
                Navigator.pop(context);
              },
              child: const Text("บันทึก"),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog() {
    final nameBox = Hive.box<SupplierNameModel>('supplier_names');
    List<SupplierNameModel> allNames = nameBox.values.toList();

    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        List<SupplierNameModel> searchResults = List.from(allNames);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void doSearch(String val) {
              query = val;
              if (query.isEmpty) {
                searchResults = List.from(allNames);
              } else {
                searchResults = allNames
                    .where((s) =>
                        s.name.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              }
              setStateDialog(() {});
            }

            void deleteName(SupplierNameModel nameModel) {
              final index = allNames.indexOf(nameModel);
              if (index != -1) {
                nameBox.deleteAt(index);
                allNames.removeAt(index);
                searchResults.remove(nameModel);
                setState(() {
                  _supplierNames.remove(nameModel.name);
                  if (_selectedSupplierName == nameModel.name) {
                    _selectedSupplierName = null;
                  }
                });
                setStateDialog(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบ "${nameModel.name}" เรียบร้อย')),
                );
              }
            }

            return AlertDialog(
              title: const Text("ค้นหาชื่อซัพพายเออร์"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: doSearch,
                    decoration: const InputDecoration(
                      labelText: "พิมพ์ชื่อ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: searchResults.isEmpty
                        ? const Center(child: Text("ไม่พบข้อมูล"))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, i) {
                              final supplier = searchResults[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(supplier.name),
                                  onTap: () {
                                    setState(() {
                                      _selectedSupplierName = supplier.name;
                                    });
                                    Navigator.pop(context);
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => deleteName(supplier),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ปิด"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveSupplier() {
    if (_selectedSupplierName == null || _selectedSupplierName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกหรือสร้างชื่อซัพพายเออร์")),
      );
      return;
    }
    final payment = double.tryParse(_paymentController.text) ?? 0.0;
    final imagesCombined = _billImageFiles.map((f) => f.path).join(',');
    final newSupplier = SupplierModel(
      name: _selectedSupplierName!,
      billImagePath: imagesCombined.isEmpty ? null : imagesCombined,
      paymentAmount: payment,
      recordDate: DateTime.now(),
    );
    _supplierBox.add(newSupplier);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("บันทึก Supplier สำเร็จ")),
    );
    _clearFields();
  }

  void _clearFields() {
    _paymentController.clear();
    setState(() {
      _billImageFiles.clear();
      _selectedSupplierName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // --- [แก้ไข] แก้ไขที่บรรทัดนี้ ---
      body: SafeArea(
        top: false, // บอกให้ SafeArea ไม่ต้องเว้นที่ว่างด้านบน
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ส่วนหัวเต็มจอ
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: TPrimaryHeaderContainer(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "เพิ่มซัพพายเออร์",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // เนื้อหาหลัก
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Row ปุ่มค้นหา, สร้างชื่อซัพพายเออร์
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.blue),
                          tooltip: "ค้นหาชื่อซัพพายเออร์",
                          onPressed: _showSearchDialog,
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _createNewSupplierName,
                          child: const Text(
                            "สร้างชื่อซัพพายเออร์",
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ช่องเลือกซัพพายเออร์ (Dropdown)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "เลือกซัพพายเออร์",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      value: _selectedSupplierName,
                      items: _supplierNames
                          .map((name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSupplierName = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // ช่องกรอกจำนวนเงินที่จ่าย (ยอดรวม)
                    TextField(
                      controller: _paymentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "จำนวนเงินที่จ่าย (ยอดรวม)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // แสดงภาพบิลที่ถ่าย
                    _billImageFiles.isNotEmpty
                        ? SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _billImageFiles.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _billImageFiles[index],
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(child: Text("ยังไม่มีภาพบิล")),
                          ),
                    const SizedBox(height: 10),
                    // ปุ่มถ่ายบิลเพิ่มเติม
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("ถ่ายบิลเพิ่มเติม"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ปุ่มบันทึก
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                        ),
                        onPressed: _saveSupplier,
                        child: const Text(
                          "บันทึก Supplier",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
