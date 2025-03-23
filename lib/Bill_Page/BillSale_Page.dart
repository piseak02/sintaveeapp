import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart'; // ✅ เพิ่มไฟล์ header
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ ส่วนหัวด้วย TPrimaryHeaderContainer
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

          // ✅ ส่วนแสดงรายการบิล
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _billBox.listenable(),
              builder: (context, Box<BillModel> box, _) {
                if (box.values.isEmpty) {
                  return const Center(child: Text("ยังไม่มีบิลการขาย"));
                }
                final bills = box.values.toList().cast<BillModel>();
                return ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return Card(
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
