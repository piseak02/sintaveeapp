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

  String searchQuery = '';
  String? _selectedNameFilter;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    supplierBox = Hive.box<SupplierModel>('suppliers');
    supplierNameBox = Hive.box<SupplierNameModel>('supplierNames');
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickDateRange() async {
    final pickedRange = await showDateRangePicker(
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

  void _clearDateFilter() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  List<DropdownMenuItem<String>> supplierNameBoxValues() {
    return supplierNameBox.values.map((supplierName) {
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
          // Header
          TPrimaryHeaderContainer(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'รายการซัพพายเออร์',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'ค้นหา...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Filters: Name and Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'ชื่อซัพพายเออร์',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    value: _selectedNameFilter,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('ทั้งหมด'),
                      ),
                      ...supplierNameBoxValues(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedNameFilter = value == '' ? null : value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  label: Text(
                    _selectedStartDate != null && _selectedEndDate != null
                        ? '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year} - '
                            '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}'
                        : 'เลือกวันที่',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
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
          // List and Totals
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: supplierBox.listenable(),
              builder: (context, Box<SupplierModel> box, _) {
                final allSuppliers = box.values.toList().cast<SupplierModel>();
                final filtered = allSuppliers.where((s) {
                  final matchesSearch =
                      s.name.toLowerCase().contains(searchQuery.toLowerCase());
                  final matchesName = _selectedNameFilter == null ||
                      _selectedNameFilter!.isEmpty ||
                      s.name == _selectedNameFilter;
                  final matchesDate =
                      _selectedStartDate == null || _selectedEndDate == null
                          ? true
                          : () {
                              final date = DateTime(s.recordDate.year,
                                  s.recordDate.month, s.recordDate.day);
                              final start = DateTime(
                                  _selectedStartDate!.year,
                                  _selectedStartDate!.month,
                                  _selectedStartDate!.day);
                              final end = DateTime(
                                  _selectedEndDate!.year,
                                  _selectedEndDate!.month,
                                  _selectedEndDate!.day);
                              return (date.isAtSameMomentAs(start) ||
                                      date.isAfter(start)) &&
                                  (date.isAtSameMomentAs(end) ||
                                      date.isBefore(end));
                            }();
                  return matchesSearch && matchesName && matchesDate;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('ไม่มีข้อมูล Supplier'));
                }

                final totalAll = allSuppliers.fold<double>(
                    0, (sum, s) => sum + s.paymentAmount);
                final totalFiltered =
                    filtered.fold<double>(0, (sum, s) => sum + s.paymentAmount);

                return Column(
                  children: [
                    // Items
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final s = filtered[index];
                          return Dismissible(
                            key: ValueKey(s),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async => await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('ยืนยันการลบ'),
                                content:
                                    Text('คุณต้องการลบ ${s.name} หรือไม่?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('ยกเลิก')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('ลบ',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ),
                            onDismissed: (_) {
                              final actualIndex =
                                  box.values.toList().indexOf(s);
                              if (actualIndex >= 0) {
                                supplierBox.deleteAt(actualIndex);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('ลบ ${s.name} สำเร็จ')));
                            },
                            child: Card(
                              margin: const EdgeInsets.all(8.0),
                              child: ListTile(
                                leading: s.billImagePath != null
                                    ? Image.file(File(s.billImagePath!),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.image),
                                title: Text(s.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'จ่ายเงิน: ${s.paymentAmount.toStringAsFixed(2)} บาท'),
                                    Text(
                                        'วันที่: ${s.recordDate.day}/${s.recordDate.month}/${s.recordDate.year}'),
                                  ],
                                ),
                                onTap: () {
                                  if (s.billImagePath != null) {
                                    final paths = s.billImagePath!.split(',');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => FullScreenImagePage(
                                              imagePaths: paths)),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Totals
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_selectedStartDate != null &&
                                _selectedEndDate != null)
                              Text(
                                'ยอดรวมระหว่าง ${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year} - '
                                '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}: ${totalFiltered.toStringAsFixed(2)} บาท',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            Text(
                              'ยอดรวมทั้งหมด: ${totalAll.toStringAsFixed(2)} บาท',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
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
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final List<String> imagePaths;
  const FullScreenImagePage({Key? key, required this.imagePaths})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ภาพบิล')),
      body: PageView(
        children: imagePaths.map((path) {
          return InteractiveViewer(
            child: Image.file(File(path), fit: BoxFit.contain),
          );
        }).toList(),
      ),
    );
  }
}
