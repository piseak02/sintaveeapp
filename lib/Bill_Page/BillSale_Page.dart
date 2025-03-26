import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import '../Database/bill_model.dart';
import 'bill_detail_page.dart';

class BillSale_Page extends StatefulWidget {
  const BillSale_Page({Key? key}) : super(key: key);

  @override
  _BillSale_PageState createState() => _BillSale_PageState();
}

class _BillSale_PageState extends State<BillSale_Page> {
  late Box<BillModel> _billBox;
  int _selectedIndex = 3;
  String searchQuery = "";
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _billBox = Hive.box<BillModel>('bills');
  }

  /// เลือกช่วงวันที่สำหรับกรอง (recordDate)
  Future<void> _pickDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: (_selectedStartDate != null && _selectedEndDate != null)
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

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลบิลทั้งหมดจาก Hive
    List<BillModel> bills = _billBox.values.toList().cast<BillModel>();

    // กรองข้อมูลตาม searchQuery (ที่ billId)
    if (searchQuery.isNotEmpty) {
      bills = bills
          .where((bill) =>
              bill.billId.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // กรองข้อมูลตามช่วงวันที่ (recordDate)
    if (_selectedStartDate != null && _selectedEndDate != null) {
      bills = bills.where((bill) {
        // สร้าง DateTime ใหม่สำหรับบิลโดยเอาแค่ปี เดือน วัน
        final billDate = DateTime(
          bill.billDate.year,
          bill.billDate.month,
          bill.billDate.day,
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
        return billDate.compareTo(startDate) >= 0 &&
            billDate.compareTo(endDate) <= 0;
      }).toList();
    }

   return Scaffold(
  body: Column(
    children: [
      // ส่วนหัวด้วย TPrimaryHeaderContainer
      TPrimaryHeaderContainer(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "รายการบิล / การขาย",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ),
      // ช่องค้นหาและตัวเลือกช่วงวันที่
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ช่องค้นหา
            TextField(
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
            const SizedBox(height: 16),
            // Row สำหรับเลือกช่วงวันที่
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
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
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: _clearDateFilter,
                ),
              ],
            ),
          ],
        ),
      ),
      // ส่วนแสดงรายการบิล
      Expanded(
        child: ValueListenableBuilder(
          valueListenable: _billBox.listenable(),
          builder: (context, Box<BillModel> box, _) {
            // คำนวณรายชื่อบิลภายใน builder เพื่อให้ได้ข้อมูลล่าสุด
            List<BillModel> bills = box.values.toList().cast<BillModel>();

            // กรองข้อมูลตาม searchQuery (ที่ billId)
            if (searchQuery.isNotEmpty) {
              bills = bills
                  .where((bill) => bill.billId
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();
            }

            // กรองข้อมูลตามช่วงวันที่ (recordDate)
            if (_selectedStartDate != null && _selectedEndDate != null) {
              bills = bills.where((bill) {
                // สร้าง DateTime ใหม่สำหรับบิลโดยเอาแค่ปี เดือน วัน
                final billDate = DateTime(
                  bill.billDate.year,
                  bill.billDate.month,
                  bill.billDate.day,
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
                return billDate.compareTo(startDate) >= 0 &&
                    billDate.compareTo(endDate) <= 0;
              }).toList();
            }

            if (bills.isEmpty) {
              return const Center(child: Text("ไม่พบบิลที่ตรงกับการค้นหา"));
            }
            return ListView.builder(
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];
                return Dismissible(
                  key: Key(bill.billId),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("ยืนยันการลบ"),
                          content: Text("คุณต้องการลบบิล \"${bill.billId}\" ใช่ไหม?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("ยกเลิก"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("ลบ",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    // ค้นหา index ของบิลใน Hive แล้วลบออก
                    final int billIndex = box.values.toList().indexOf(bill);
                    if (billIndex != -1) {
                      _billBox.deleteAt(billIndex);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("ลบบิล ${bill.billId} เรียบร้อย")),
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
                      title: Text(
                        "บิล: ${bill.billId}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "วันที่: ${bill.billDate.toLocal().toString().split(' ')[0]}\n"
                        "ยอดรวมสุทธิ: ${bill.netTotal.toStringAsFixed(2)} บาท",
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillDetailPage(bill: bill),
                          ),
                        );
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
