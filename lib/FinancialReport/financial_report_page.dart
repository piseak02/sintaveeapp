import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';

// Import models
import '../Database/bill_model.dart';
import '../Database/supplier_model.dart';
// Import header widget
import '../widgets/castom_shapes/Containers/primary_header_container.dart';

// Enum for chart view options
enum ChartView { thisYear, last12Months }

class FinancialReportPage extends StatefulWidget {
  const FinancialReportPage({Key? key}) : super(key: key);

  @override
  _FinancialReportPageState createState() => _FinancialReportPageState();
}

class _FinancialReportPageState extends State<FinancialReportPage> {
  int _selectedIndex = 1;
  double _salesThisMonth = 0;
  double _profitThisMonth = 0;
  double _salesThisYear = 0;
  double _profitThisYear = 0;
  final Map<int, double> _yearlyMonthlySales = {};
  final Map<int, double> _last12MonthsSales = {};
  ChartView _selectedChartView = ChartView.thisYear;
  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'th');
  final DateFormat _monthYearFormat = DateFormat.yMMMM('th');

  @override
  void initState() {
    super.initState();
    _calculateFinancials();
  }

  void _calculateFinancials() {
    final billBox = Hive.box<BillModel>('bills');
    final supplierBox = Hive.box<SupplierModel>('suppliers');
    final now = DateTime.now();
    // Current month
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
    // Current year
    final startOfYear = DateTime(now.year, 1, 1);
    _salesThisYear = billBox.values
        .where((b) => b.billDate.isAfter(startOfYear))
        .fold(0.0, (sum, b) => sum + b.netTotal);
    final costsThisYear = supplierBox.values
        .where((s) => s.recordDate.isAfter(startOfYear))
        .fold(0.0, (sum, s) => sum + s.paymentAmount);
    _profitThisYear = _salesThisYear - costsThisYear;
    // Yearly monthly
    _yearlyMonthlySales.clear();
    for (int m = 1; m <= 12; m++) {
      final sales = billBox.values
          .where((b) => b.billDate.year == now.year && b.billDate.month == m)
          .fold<double>(0.0, (sum, b) => sum + b.netTotal);
      _yearlyMonthlySales[m] = sales;
    }
    // Last 12 months
    _last12MonthsSales.clear();
    for (int i = 0; i < 12; i++) {
      final target = DateTime(now.year, now.month - i, 1);
      final key = target.year * 100 + target.month;
      final sales = billBox.values
          .where((b) =>
              b.billDate.year == target.year &&
              b.billDate.month == target.month)
          .fold<double>(0.0, (sum, b) => sum + b.netTotal);
      _last12MonthsSales[key] = sales;
    }
    if (mounted) setState(() {});
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: TPrimaryHeaderContainer(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'รายงานสรุปยอดขาย',
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('สรุปยอดเดือนนี้',
                        _monthYearFormat.format(DateTime.now()), [
                      _buildSimpleCard('ยอดขาย', _salesThisMonth, Colors.black),
                      const SizedBox(width: 16),
                      _buildSimpleCard('กำไร/ขาดทุน', _profitThisMonth,
                          _profitThisMonth >= 0 ? Colors.black : Colors.red),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(
                        'ภาพรวมปีนี้', 'พ.ศ. ${DateTime.now().year + 543}', [
                      _buildSimpleCard('ยอดขาย', _salesThisYear, Colors.black),
                      const SizedBox(width: 16),
                      _buildSimpleCard('กำไร/ขาดทุน', _profitThisYear,
                          _profitThisYear >= 0 ? Colors.black : Colors.red),
                    ]),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 16),
        Row(children: cards),
      ],
    );
  }

  Widget _buildSimpleCard(String label, double value, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_currencyFormat.format(value)} บาท',
                style: TextStyle(color: textColor, fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('กราฟยอดขาย',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            ToggleButtons(
              isSelected: [
                _selectedChartView == ChartView.thisYear,
                _selectedChartView == ChartView.last12Months
              ],
              onPressed: (i) =>
                  setState(() => _selectedChartView = ChartView.values[i]),
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Colors.orange,
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ปีนี้')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('12 เดือนล่าสุด')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            _buildBarChartData(
              _selectedChartView == ChartView.thisYear
                  ? _yearlyMonthlySales
                  : _last12MonthsSales,
              isLast12Months: _selectedChartView == ChartView.last12Months,
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(Map<int, double> data,
      {bool isLast12Months = false}) {
    final keys = data.keys.toList()..sort();
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: keys
          .map(
            (k) => BarChartGroupData(
              x: k,
              barRods: [
                BarChartRodData(
                  toY: data[k]!,
                  gradient: const LinearGradient(
                      colors: [Colors.orangeAccent, Colors.orange]),
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          )
          .toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (v, meta) {
              int month = isLast12Months ? v.toInt() % 100 : v.toInt();
              const monthNames = [
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
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(monthNames[month],
                    style: const TextStyle(fontSize: 12, color: Colors.black)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (v, meta) {
              if (v == 0) return const SizedBox.shrink();
              String text = v >= 1000
                  ? '\${(v / 1000).toStringAsFixed(0)}K'
                  : v.toStringAsFixed(0);
              return Text(text,
                  style: const TextStyle(color: Colors.black, fontSize: 12));
            },
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
          getDrawingHorizontalLine: (v) =>
              const FlLine(color: Colors.black12, strokeWidth: 1)),
      barTouchData: BarTouchData(
        enabled: false, // ปิดไม่ให้แสดง tooltip หรือโต้ตอบใดๆ
      ),
    );
  }
}
