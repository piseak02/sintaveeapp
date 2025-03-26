import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import '../Database/supplier_model.dart';
import '../Database/supplier_name_model.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({Key? key}) : super(key: key);

  @override
  _SupplierListPageState createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  late Box<SupplierModel> supplierBox;
  late Box<SupplierNameModel> supplierNameBox;

  String searchQuery = "";
  String? _selectedNameFilter; // Filter จาก SupplierNameModel
  DateTime? _selectedStartDate; // เริ่มต้นของช่วงวันที่
  DateTime? _selectedEndDate; // สิ้นสุดของช่วงวันที่

  int _selectedIndex = 4;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    supplierBox = Hive.box<SupplierModel>('suppliers');
    supplierNameBox = Hive.box<SupplierNameModel>('supplierNames');
  }

  /// เลือกช่วงวันที่สำหรับกรอง (recordDate)
  Future<void> _pickDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedRange != null) {
      setState(() {
        _selectedStartDate = pickedRange.start;
        _selectedEndDate = pickedRange.end;
      });
    }
  }

  /// เคลียร์ตัวกรองวันที่
  void _clearDateFilter() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  List<DropdownMenuItem<String>> supplierNameBoxValues() {
    final box = Hive.box<SupplierNameModel>('supplierNames');
    return box.values.map((supplierName) {
      return DropdownMenuItem<String>(
        value: supplierName.name,
        child: Text(supplierName.name),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ส่วนหัวที่ใช้ TPrimaryHeaderContainer
          TPrimaryHeaderContainer(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "รายการซัพพายเออร์",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // ช่องค้นหา (เพิ่มเติม)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "ค้นหา...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Row สำหรับตัวกรอง: Dropdown ชื่อ (จาก SupplierNameModel) และตัวเลือกวันที่ (ช่วง)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "ชื่อซัพพายเออร์",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    value: _selectedNameFilter,
                    items: [
                      const DropdownMenuItem<String>(
                        value: "",
                        child: Text("ทั้งหมด"),
                      ),
                      ...supplierNameBoxValues()
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedNameFilter = (value == "" ? null : value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                  ),
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  label: Text(
                    _selectedStartDate == null || _selectedEndDate == null
                        ? "เลือกวันที่"
                        : "${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year} - ${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: _clearDateFilter,
                ),
              ],
            ),
          ),
          // แสดงรายการ Supplier
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: supplierBox.listenable(),
              builder: (context, Box<SupplierModel> box, _) {
                // คำนวณรายชื่อ Supplier ภายใน builder เพื่อให้ได้ข้อมูลล่าสุด
                List<SupplierModel> suppliers =
                    box.values.toList().cast<SupplierModel>();

                // กรองข้อมูลตาม searchQuery
                if (searchQuery.isNotEmpty) {
                  suppliers = suppliers
                      .where((supplier) => supplier.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                      .toList();
                }
                // กรองข้อมูลตามชื่อที่เลือก (จาก SupplierNameModel)
                if (_selectedNameFilter != null &&
                    _selectedNameFilter!.isNotEmpty) {
                  suppliers = suppliers
                      .where((supplier) => supplier.name == _selectedNameFilter)
                      .toList();
                }
                // กรองข้อมูลตามช่วงวันที่ (recordDate)
                if (_selectedStartDate != null && _selectedEndDate != null) {
                  suppliers = suppliers.where((supplier) {
                    final supplierDate = DateTime(
                      supplier.recordDate.year,
                      supplier.recordDate.month,
                      supplier.recordDate.day,
                    );
                    final startDate = DateTime(
                      _selectedStartDate!.year,
                      _selectedStartDate!.month,
                      _selectedStartDate!.day,
                    );
                    final endDate = DateTime(
                      _selectedEndDate!.year,
                      _selectedEndDate!.month,
                      _selectedEndDate!.day,
                    );
                    return supplierDate.compareTo(startDate) >= 0 &&
                        supplierDate.compareTo(endDate) <= 0;
                  }).toList();
                }

                if (suppliers.isEmpty) {
                  return const Center(
                    child: Text("ไม่มีข้อมูล Supplier"),
                  );
                }
                return ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return Dismissible(
                      key: ValueKey(supplier),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("ยืนยันการลบ"),
                              content: Text(
                                  "คุณต้องการลบ ${supplier.name} หรือไม่?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("ยกเลิก"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("ลบ",
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        final int actualIndex =
                            box.values.toList().indexOf(supplier);
                        if (actualIndex != -1) {
                          supplierBox.deleteAt(actualIndex);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("ลบ ${supplier.name} สำเร็จ")),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: supplier.billImagePath != null
                              ? Image.file(
                                  File(supplier.billImagePath!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image),
                          title: Text(supplier.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "จ่ายเงิน: ${supplier.paymentAmount.toStringAsFixed(2)} บาท"),
                              Text(
                                  "วันที่: ${supplier.recordDate.day}/${supplier.recordDate.month}/${supplier.recordDate.year}"),
                            ],
                          ),
                          onTap: () {
                            if (supplier.billImagePath != null) {
                              List<String> imagePaths =
                                  supplier.billImagePath!.split(',');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImagePage(
                                    imagePaths: imagePaths,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}

/// Widget สำหรับแสดงภาพบิลแบบเต็มหน้าจอ (รองรับหลายรูปด้วย PageView)
class FullScreenImagePage extends StatelessWidget {
  final List<String> imagePaths;
  const FullScreenImagePage({Key? key, required this.imagePaths})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ภาพบิล"),
      ),
      body: PageView(
        children: imagePaths.map((path) {
          return InteractiveViewer(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
            ),
          );
        }).toList(),
      ),
    );
  }
}
