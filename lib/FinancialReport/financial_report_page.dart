import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';

// models
import '../Database/bill_model.dart';
import '../Database/supplier_model.dart';
// header
import '../widgets/castom_shapes/Containers/primary_header_container.dart';

/// โหมดกราฟ 3 แบบ:
/// - last6Months: แสดง 6 เดือนล่าสุด (นับจากปัจจุบันย้อนหลัง)
/// - thisYear: แสดง 12 เดือนของปีนี้
/// - yearRange: แสดงยอดขายรวมรายปี โดยเลือกช่วงปีเริ่ม–สิ้นสุดได้
enum ChartView { last6Months, thisYear, yearRange }

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({Key? key}) : super(key: key);

  @override
  _FinancialReportPageState createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  int _selectedIndex = 1;

  // -------- สรุปตัวเลข --------
  double _salesThisMonth = 0;
  double _profitThisMonth = 0;
  double _salesThisYear = 0;
  double _profitThisYear = 0;

  // -------- ชุดข้อมูลสำหรับกราฟ --------
  final Map<int, double> _thisYearMonthlySales = {}; // เดือน 1..12 ของปีนี้
  final Map<int, double> _last12MonthsSales = {}; // key = yyyyMM
  final Map<int, double> _salesByYear = {}; // ยอดรวมต่อปี

  // -------- สถานะ UI --------
  ChartView _selectedChartView = ChartView.thisYear; // เริ่มต้น "ปีนี้"
  List<int> _availableYears = []; // ปีที่มีข้อมูล
  int? _rangeStartYear; // ปีเริ่มต้นสำหรับโหมดช่วงปี
  int? _rangeEndYear; // ปีสิ้นสุดสำหรับโหมดช่วงปี

  // รูปแบบตัวเลข/วันที่
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th');
  final NumberFormat _intFormat = NumberFormat('#,##0', 'th');
  final DateFormat _monthYearFormat = DateFormat.yMMMM('th');

  @override
  void initState() {
    super.initState();
    _calculateFinancials(); // โหลด/คำนวณทุกอย่างตอนเปิดหน้า
  }

  /// รวบรวม/คำนวณข้อมูลที่ต้องใช้แสดงผล
  void _calculateFinancials() {
    final billBox = Hive.box<BillModel>('bills');
    final supplierBox = Hive.box<SupplierModel>('suppliers');
    final now = DateTime.now();

    // ----- เดือนปัจจุบัน -----
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _salesThisMonth = billBox.values
        .where((b) =>
            b.billDate.isAfter(startOfMonth) && b.billDate.isBefore(endOfMonth))
        .fold(0.0, (sum, b) => sum + b.netTotal);

    final costsThisMonth = supplierBox.values
        .where((s) =>
            s.recordDate.isAfter(startOfMonth) &&
            s.recordDate.isBefore(endOfMonth))
        .fold(0.0, (sum, s) => sum + s.paymentAmount);

    _profitThisMonth = _salesThisMonth - costsThisMonth;

    // ----- ปีปัจจุบัน -----
    final startOfYear = DateTime(now.year, 1, 1);
    _salesThisYear = billBox.values
        .where((b) => b.billDate.isAfter(startOfYear))
        .fold(0.0, (s, b) => s + b.netTotal);

    final costsThisYear = supplierBox.values
        .where((s) => s.recordDate.isAfter(startOfYear))
        .fold(0.0, (s, x) => s + x.paymentAmount);

    _profitThisYear = _salesThisYear - costsThisYear;

    // ----- เติมยอดแบบรายเดือนของ "ปีนี้" -----
    _thisYearMonthlySales.clear();
    for (int m = 1; m <= 12; m++) {
      final sales = billBox.values
          .where((b) => b.billDate.year == now.year && b.billDate.month == m)
          .fold<double>(0.0, (sum, b) => sum + b.netTotal);
      _thisYearMonthlySales[m] = sales;
    }

    // ----- 12 เดือนล่าสุด (ไว้ตัดมาใช้ 6 เดือนล่าสุด) -----
    _last12MonthsSales.clear();
    for (int i = 0; i < 12; i++) {
      final target = DateTime(now.year, now.month - i, 1);
      final key = target.year * 100 + target.month; // yyyyMM
      final sales = billBox.values
          .where((b) =>
              b.billDate.year == target.year &&
              b.billDate.month == target.month)
          .fold<double>(0.0, (sum, b) => sum + b.netTotal);
      _last12MonthsSales[key] = sales;
    }

    // ----- ยอดรวมต่อปี + รายการปีที่มีข้อมูล -----
    _salesByYear.clear();
    final years = <int>{};
    for (final b in billBox.values) {
      years.add(b.billDate.year);
      _salesByYear[b.billDate.year] =
          (_salesByYear[b.billDate.year] ?? 0) + b.netTotal;
    }
    _availableYears = years.toList()..sort();
    if (_availableYears.isNotEmpty) {
      _rangeStartYear = _availableYears.first;
      _rangeEndYear = _availableYears.last;
    } else {
      _rangeStartYear = now.year;
      _rangeEndYear = now.year;
    }

    if (mounted) setState(() {});
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ส่วนหัวสีส้มด้านบน
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: TPrimaryHeaderContainer(
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'รายงานสรุปยอดขาย',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),

            // เนื้อหาที่เลื่อนขึ้นลงได้
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('สรุปยอดเดือนนี้',
                          _monthYearFormat.format(DateTime.now()), [
                        _buildSimpleCard(
                            'ยอดขาย', _salesThisMonth, Colors.black),
                        const SizedBox(width: 16.0),
                        _buildSimpleCard('กำไร/ขาดทุน', _profitThisMonth,
                            _profitThisMonth >= 0 ? Colors.black : Colors.red),
                      ]),
                      const SizedBox(height: 24.0),

                      _buildSection(
                          'ภาพรวมปีนี้', 'พ.ศ. ${DateTime.now().year + 543}', [
                        _buildSimpleCard(
                            'ยอดขาย', _salesThisYear, Colors.black),
                        const SizedBox(width: 16.0),
                        _buildSimpleCard('กำไร/ขาดทุน', _profitThisYear,
                            _profitThisYear >= 0 ? Colors.black : Colors.red),
                      ]),
                      const SizedBox(height: 24.0),

                      _buildChartSection(), // กราฟ + ปุ่มเลือกโหมด
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // ---------------- UI ชิ้นส่วนทั่วไป ----------------

  Widget _buildSection(String title, String subtitle, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 4.0),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 16.0),
        Row(children: cards),
      ],
    );
  }

  Widget _buildSimpleCard(String label, double value, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.0,
                offset: const Offset(0.0, 4.0))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text('${_currencyFormat.format(value)} บาท',
                style: TextStyle(color: textColor, fontSize: 20.0)),
          ],
        ),
      ),
    );
  }

  // ---------------- ส่วนกราฟ ----------------

  Widget _buildChartSection() {
    final monthNames = const [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];
    final thShort = DateFormat('MMM yy', 'th');

    // ตัวควบคุมช่วงปี (แสดงเฉพาะโหมดช่วงปี)
    Widget yearRangeControls = const SizedBox.shrink();
    if (_selectedChartView == ChartView.yearRange) {
      yearRangeControls = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: _rangeStartYear,
            underline: const SizedBox(),
            items: _availableYears
                .map((y) =>
                    DropdownMenuItem(value: y, child: Text('${y + 543}')))
                .toList(),
            onChanged: (y) {
              if (y == null) return;
              setState(() {
                _rangeStartYear = y;
                if ((_rangeEndYear ?? y) < y) _rangeEndYear = y;
              });
            },
          ),
          const Text(' - '),
          DropdownButton<int>(
            value: _rangeEndYear,
            underline: const SizedBox(),
            items: _availableYears
                .map((y) =>
                    DropdownMenuItem(value: y, child: Text('${y + 543}')))
                .toList(),
            onChanged: (y) {
              if (y == null) return;
              setState(() {
                _rangeEndYear = y;
                if ((_rangeStartYear ?? y) > y) _rangeStartYear = y;
              });
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('กราฟยอดขาย',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 8.0),

        // ปุ่มเลือกโหมด: 6 เดือนล่าสุด -> ปีนี้ -> ช่วงปี
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ToggleButtons(
              isSelected: [
                _selectedChartView == ChartView.last6Months, // ปุ่ม 1
                _selectedChartView == ChartView.thisYear, // ปุ่ม 2
                _selectedChartView == ChartView.yearRange, // ปุ่ม 3
              ],
              onPressed: (i) =>
                  setState(() => _selectedChartView = ChartView.values[i]),
              borderRadius: BorderRadius.circular(8.0),
              selectedColor: Colors.white,
              fillColor: Colors.orange,
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('6 เดือนล่าสุด')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('ปีนี้')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text('ช่วงปี')),
              ],
            ),
            if (_selectedChartView == ChartView.yearRange) yearRangeControls,
          ],
        ),

        const SizedBox(height: 8.0),
        const Divider(height: 1.0, thickness: 1.0, color: Colors.black12),
        const SizedBox(height: 12.0),

        // ตัวกราฟจริง
        SizedBox(
          height: 300.0,
          child: Builder(
            builder: (_) {
              switch (_selectedChartView) {
                case ChartView.thisYear:
                  final months = List<int>.generate(12, (i) => i + 1);
                  final yVals =
                      months.map((m) => _thisYearMonthlySales[m] ?? 0).toList();
                  return BarChart(_buildBarChartGeneric(
                    xValues: months,
                    yValues: yVals,
                    bottomLabel: (x) =>
                        (x >= 1 && x <= 12) ? monthNames[x] : '',
                  ));

                case ChartView.last6Months:
                  if (_last12MonthsSales.isEmpty) {
                    return const Center(child: Text('ยังไม่มีข้อมูลกราฟ'));
                  }
                  final keys = _last12MonthsSales.keys.toList()
                    ..sort(); // เก่าสุด -> ล่าสุด
                  final List<int> last6 = (keys.length <= 6)
                      ? List<int>.from(keys)
                      : keys.sublist(keys.length - 6);
                  final yVals =
                      last6.map((k) => _last12MonthsSales[k] ?? 0).toList();
                  final labels = last6
                      .map((k) => DateTime(k ~/ 100, k % 100, 1))
                      .map((d) => thShort.format(d))
                      .toList();
                  final xIdx = List<int>.generate(last6.length, (i) => i);
                  return BarChart(_buildBarChartGeneric(
                    xValues: xIdx,
                    yValues: yVals,
                    bottomLabel: (x) =>
                        (x >= 0 && x < labels.length) ? labels[x] : '',
                  ));

                case ChartView.yearRange:
                  if (_salesByYear.isEmpty) {
                    return const Center(child: Text('ยังไม่มีข้อมูลกราฟ'));
                  }
                  final startY = _rangeStartYear ?? _availableYears.first;
                  final endY = _rangeEndYear ?? _availableYears.last;
                  final years = [for (int y = startY; y <= endY; y++) y];
                  final yVals = years.map((y) => _salesByYear[y] ?? 0).toList();
                  return BarChart(_buildBarChartGeneric(
                    xValues: years,
                    yValues: yVals,
                    bottomLabel: (x) => '${x + 543}', // โชว์ พ.ศ.
                  ));
              }
            },
          ),
        ),
      ],
    );
  }

  /// ฟังก์ชันกลางสร้าง BarChartData
  /// - แกนซ้ายแสดง "เลขจริง" (format มีคอมม่า)
  /// - เส้นกริดแบ่ง 5 ช่วง โดยเส้นบนสุด = ค่าสูงสุดจริงของข้อมูล
  /// - *สำคัญ*: fl_chart ต้องการ `double` ในหลายพารามิเตอร์ -> เลยใส่ `.0` ให้ครบ
  BarChartData _buildBarChartGeneric({
    required List<int> xValues,
    required List<double> yValues,
    required String Function(int x) bottomLabel,
  }) {
    final double maxY = yValues.isEmpty ? 0.0 : yValues.reduce(math.max);
    final double safeMaxY = maxY <= 0.0 ? 1.0 : maxY;
    const int nTicks = 5;
    final double interval = safeMaxY / nTicks;

    final groups = <BarChartGroupData>[
      for (var i = 0; i < xValues.length; i++)
        BarChartGroupData(
          x: xValues[i],
          barRods: [
            BarChartRodData(
              toY: yValues[i],
              gradient: const LinearGradient(
                  colors: [Colors.orangeAccent, Colors.orange]),
              width: 16.0,
              borderRadius: BorderRadius.circular(6.0),
            ),
          ],
        ),
    ];

    return BarChartData(
      minY: 0.0,
      maxY: safeMaxY,
      alignment: BarChartAlignment.spaceAround,
      barGroups: groups,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30.0,
            getTitlesWidget: (v, meta) => SideTitleWidget(
              meta: meta,
              space: 4.0,
              child: Text(
                bottomLabel(v.toInt()),
                style: const TextStyle(fontSize: 12.0, color: Colors.black),
              ),
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50.0,
            interval: interval,
            getTitlesWidget: (v, meta) => Text(
              _intFormat.format(v.round()),
              style: const TextStyle(color: Colors.black, fontSize: 12.0),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (v) =>
            const FlLine(color: Colors.black12, strokeWidth: 1.0),
      ),
      barTouchData: BarTouchData(enabled: false),
    );
  }
}
