import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Database/lot_model.dart';
import '../Database/product_model.dart';
import '../Bottoom_Navbar/bottom_navbar.dart';

class ExpiryRankingPage extends StatefulWidget {
  const ExpiryRankingPage({Key? key}) : super(key: key);

  @override
  _ExpiryRankingPageState createState() => _ExpiryRankingPageState();
}

class _ExpiryRankingPageState extends State<ExpiryRankingPage> {
  Box<LotModel>? lotBox;
  Box<ProductModel>? productBox;
  List<LotModel> lots = [];

  // สำหรับค้นหาและกรอง
  String searchQuery = "";
  String selectedFilter = "ทั้งหมด"; // ตัวเลือก: "ทั้งหมด", "60", "90", "120"

  @override
  void initState() {
    super.initState();
    lotBox = Hive.box<LotModel>('lots');
    productBox = Hive.box<ProductModel>('products');
    _loadLots();
  }

  // โหลดข้อมูล Lot ทั้งหมดและเรียงลำดับตามวันหมดอายุที่เหลือ
  void _loadLots() {
    setState(() {
      lots = lotBox!.values.toList();
      lots.sort((a, b) =>
          a.expiryDate.difference(DateTime.now()).inDays.compareTo(
              b.expiryDate.difference(DateTime.now()).inDays));
    });
  }

  // ฟังก์ชันดึงชื่อสินค้าจาก productBox โดยใช้ productId
  String _getProductName(String productId) {
    try {
      final product = productBox!.values.firstWhere((p) => p.id == productId);
      return product.name;
    } catch (e) {
      return "ไม่ทราบชื่อสินค้า";
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // กรองล็อตตาม search query และตัวกรองวันหมดอายุ
    List<LotModel> filteredLots = lots.where((lot) {
      String productName = _getProductName(lot.productId);
      bool matchesSearch = productName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          lot.lotId.toLowerCase().contains(searchQuery.toLowerCase());
      int daysLeft = lot.expiryDate.difference(now).inDays;
      bool matchesFilter = true;
      if (selectedFilter != "ทั้งหมด") {
        int threshold = int.parse(selectedFilter);
        matchesFilter = daysLeft <= threshold;
      }
      return matchesSearch && matchesFilter;
    }).toList();

    // เรียงลำดับล็อตตามจำนวนวันเหลือก่อนหมด (น้อยสุดก่อน)
    filteredLots.sort((a, b) =>
        a.expiryDate.difference(now).inDays.compareTo(
            b.expiryDate.difference(now).inDays));

    return Scaffold(
      appBar: AppBar(
        title: const Text("ล็อตสินค้ากำลังจะหมดอายุ"),
      ),
      body: Padding(
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
                labelText: "ค้นหา (ชื่อสินค้า, Lot ID)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            // Dropdown สำหรับกรองวันหมดอายุ
            Row(
              children: [
                const Text("แสดงล็อตที่หมดอายุภายใน: "),
                DropdownButton<String>(
                  value: selectedFilter,
                  onChanged: (newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                  },
                  items: <String>["ทั้งหมด", "60", "90", "120"]
                      .map((filter) => DropdownMenuItem<String>(
                            value: filter,
                            child: Text(filter == "ทั้งหมด"
                                ? "ทั้งหมด"
                                : "$filter วัน"),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // แสดงรายการล็อตด้วย Dismissible
            Expanded(
              child: filteredLots.isEmpty
                  ? const Center(
                      child: Text("ไม่มีล็อตสินค้าที่ตรงกับเงื่อนไข"),
                    )
                  : ListView.builder(
                      itemCount: filteredLots.length,
                      itemBuilder: (context, index) {
                        final lot = filteredLots[index];
                        // แปลงวันหมดอายุเป็น dd/MM/yyyy
                        final expiryText =
                            "${lot.expiryDate.day.toString().padLeft(2, '0')}/"
                            "${lot.expiryDate.month.toString().padLeft(2, '0')}/"
                            "${lot.expiryDate.year}";
                        // แปลงวันที่บันทึกเป็น dd/MM/yyyy
                        final recordText =
                            "${lot.recordDate.day.toString().padLeft(2, '0')}/"
                            "${lot.recordDate.month.toString().padLeft(2, '0')}/"
                            "${lot.recordDate.year}";
                        final daysLeft = lot.expiryDate.difference(now).inDays;
                        return Dismissible(
                          key: ValueKey(lot.lotId),
                          direction: DismissDirection.endToStart,
                          background: Container(),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("ยืนยันการลบ"),
                                      content: Text("ต้องการลบล็อต \"${lot.lotId}\" หรือไม่?"),
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
                                ) ??
                                false;
                          },
                          onDismissed: (direction) async {
                            // ค้นหา index ใน box ของ lotBox และลบออก
                            final allLots = lotBox!.values.toList();
                            int deleteIndex = allLots.indexWhere((l) => l.lotId == lot.lotId);
                            if (deleteIndex != -1) {
                              await lotBox!.deleteAt(deleteIndex);
                              setState(() {
                                _loadLots();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("ลบล็อต \"${lot.lotId}\" เรียบร้อย")));
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text((index + 1).toString()),
                              ),
                              title: Text(lot.lotId),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("สินค้า: ${_getProductName(lot.productId)}"),
                                  Text("จำนวน: ${lot.quantity}"),
                                  Text("วันหมดอายุ: $expiryText"),
                                  Text("วันที่บันทึก: $recordText"),
                                  Text("เหลืออีก: $daysLeft วัน"),
                                  if (lot.note != null && lot.note!.isNotEmpty)
                                    Text("หมายเหตุ: ${lot.note}"),
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
      bottomNavigationBar: BottomNavbar(
        currentIndex: 0,
        onTap: (index) {
          // เพิ่ม Navigation logic หากต้องการ
        },
      ),
    );
  }
}
