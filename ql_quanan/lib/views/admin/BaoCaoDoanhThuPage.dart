import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/DatabaseHelper.dart';
import 'package:fl_chart/fl_chart.dart'; // Thêm thư viện biểu đồ

class BaoCaoDoanhThuPage extends StatefulWidget {
  const BaoCaoDoanhThuPage({Key? key}) : super(key: key);

  @override
  _BaoCaoDoanhThuPageState createState() => _BaoCaoDoanhThuPageState();
}

class _BaoCaoDoanhThuPageState extends State<BaoCaoDoanhThuPage> {
  final QLQuanAnDatabaseHelper _dbHelper = QLQuanAnDatabaseHelper.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
  );

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  double _totalRevenue = 0.0;
  double _totalExpense = 0.0;
  List<Map<String, dynamic>> _revenueByDay = [];
  List<Map<String, dynamic>> _revenueByMenuItem = [];
  List<Map<String, dynamic>> _expenseByCategory = [];
  List<Map<String, dynamic>> _customerSpending = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _totalRevenue = 0.0;
      _totalExpense = 0.0;
      _revenueByDay = [];
      _revenueByMenuItem = [];
      _expenseByCategory = [];
      _customerSpending = [];
    });

    // Tổng doanh thu
    _totalRevenue = await _dbHelper.getTotalRevenue(
      startDate: _startDate,
      endDate: _endDate,
    );

    // Tổng chi phí
    _totalExpense = await _dbHelper.getTotalExpense(
      startDate: _startDate,
      endDate: _endDate,
    );

    // Doanh thu theo ngày
    _revenueByDay = await _dbHelper.getRevenueByDateRange(
      startDate: _startDate,
      endDate: _endDate,
    );

    // Doanh thu theo món ăn
    _revenueByMenuItem = await _dbHelper.getRevenueByMonAn(
      // Changed to getRevenueByMonAn
      startDate: _startDate,
      endDate: _endDate,
    );

    // Chi phí theo danh mục
    _expenseByCategory = await _dbHelper.getExpenseByCategory(
      startDate: _startDate,
      endDate: _endDate,
    );

    // Chi tiêu khách hàng
    _customerSpending = await _dbHelper.getCustomerSpending();

    setState(() {});
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      currentDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lợi nhuận ròng
    double netProfit = _totalRevenue - _totalExpense;

    // Lợi nhuận gộp: Doanh thu trừ chi phí nguyên liệu
    // Cần tìm tổng chi phí nguyên liệu từ _expenseByCategory
    double rawMaterialCost =
        _expenseByCategory.firstWhere(
              (e) => e['loai_chi_phi'] == 'nguyen_lieu',
              orElse: () => {'total_expense': 0.0},
            )['total_expense']
            as double? ??
        0.0;

    double grossProfit = _totalRevenue - rawMaterialCost;

    // Tỷ lệ lợi nhuận gộp
    double grossProfitMargin =
        _totalRevenue > 0 ? (grossProfit / _totalRevenue) * 100 : 0.0;
    // Tỷ lệ lợi nhuận ròng
    double netProfitMargin =
        _totalRevenue > 0 ? (netProfit / _totalRevenue) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Báo Cáo Doanh Thu & Lợi Nhuận',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _selectDateRange,
            tooltip: 'Chọn khoảng thời gian',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Từ ngày: ${DateFormat('dd/MM/yyyy').format(_startDate)} - Đến ngày: ${DateFormat('dd/MM/yyyy').format(_endDate)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            _buildSummaryCard(
              title: 'Tổng Doanh Thu',
              value: _currencyFormat.format(_totalRevenue),
              icon: Icons.attach_money,
              color: Colors.green.shade600,
            ),
            _buildSummaryCard(
              title: 'Tổng Chi Phí',
              value: _currencyFormat.format(_totalExpense),
              icon: Icons.money_off,
              color: Colors.red.shade600,
            ),
            _buildSummaryCard(
              title: 'Lợi Nhuận Ròng',
              value: _currencyFormat.format(netProfit),
              icon: Icons.trending_up,
              color:
                  netProfit >= 0
                      ? Colors.blue.shade600
                      : Colors.deepOrange.shade600,
            ),
            _buildSummaryCard(
              title: 'Tỷ Lệ Lợi Nhuận Gộp',
              value: '${grossProfitMargin.toStringAsFixed(2)}%',
              icon: Icons.pie_chart,
              color: Colors.purple.shade600,
            ),
            _buildSummaryCard(
              title: 'Tỷ Lệ Lợi Nhuận Ròng',
              value: '${netProfitMargin.toStringAsFixed(2)}%',
              icon: Icons.percent,
              color: Colors.pink.shade600,
            ),

            // const SizedBox(height: 20),
            // _buildSectionTitle('Doanh Thu Theo Ngày'),
            // _buildLineChartCard(_revenueByDay),

            // const SizedBox(height: 20),
            // _buildSectionTitle('Doanh Thu Theo Món Ăn'),
            // _buildPieChartCard(
            //   _revenueByMenuItem,
            //   'item_revenue',
            //   'ten_mon',
            // ), // Ensure 'item_revenue' is the correct key

            // const SizedBox(height: 20),
            // _buildSectionTitle('Chi Phí Theo Danh Mục'),
            // _buildPieChartCard(
            //   _expenseByCategory,
            //   'total_expense',
            //   'loai_chi_phi',
            // ),

            // const SizedBox(height: 20),
            // _buildSectionTitle('Chi Tiêu Khách Hàng'),
            // _buildCustomerSpendingList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE91E63), // Màu hồng đậm
        ),
      ),
    );
  }

  Widget _buildLineChartCard(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu doanh thu theo ngày.'));
    }

    // Lấy tất cả các ngày trong khoảng từ _startDate đến _endDate
    final List<DateTime> allDates = [];
    for (int i = 0; i <= _endDate.difference(_startDate).inDays; i++) {
      allDates.add(_startDate.add(Duration(days: i)));
    }

    // Tạo map để dễ dàng truy cập doanh thu theo ngày
    final Map<String, double> dailyRevenueMap = {
      for (var item in data)
        item['ngay_dat'].toString(): (item['daily_revenue'] as num).toDouble(),
    };

    // Tạo FlSpot cho tất cả các ngày, gán 0 nếu không có doanh thu
    final List<FlSpot> spots =
        allDates.asMap().entries.map((entry) {
          int index = entry.key;
          DateTime date = entry.value;
          String formattedDate = DateFormat('yyyy-MM-dd').format(date);
          return FlSpot(
            index.toDouble(),
            dailyRevenueMap[formattedDate] ?? 0.0,
          );
        }).toList();

    // Tìm giá trị max Y để làm giới hạn trục Y
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100.0; // Avoid division by zero if all values are 0

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval:
                        (allDates.length / 5)
                            .ceil()
                            .toDouble(), // Show fewer labels for long ranges
                    getTitlesWidget: (value, meta) {
                      final dateIndex = value.toInt();
                      if (dateIndex >= 0 && dateIndex < allDates.length) {
                        return Padding(
                          // Changed from SideTitleWidget to Padding
                          padding: const EdgeInsets.only(
                            top: 8.0,
                          ), // Apply padding here
                          child: Text(
                            DateFormat('dd/MM').format(allDates[dateIndex]),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _currencyFormat.format(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    interval: maxY / 3, // Khoảng cách hợp lý cho trục Y
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: 0,
              maxX: (allDates.length - 1).toDouble(),
              minY: 0,
              maxY:
                  maxY * 1.2, // Thêm 20% vào max Y để đồ thị không bị chạm đỉnh
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFFFF6790),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFFFFB2D9).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartCard(
    List<Map<String, dynamic>> data,
    String valueKey,
    String titleKey,
  ) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu ${titleKey.contains('mon') ? 'món ăn' : 'chi phí'}.',
        ),
      );
    }

    double totalValue = data.fold(
      0.0,
      (sum, item) => sum + (item[valueKey] as num).toDouble(),
    );

    final List<PieChartSectionData> sections =
        data.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;
          final double value = (item[valueKey] as num).toDouble();
          final String title = item[titleKey].toString();
          final double percentage =
              totalValue > 0 ? (value / totalValue) * 100 : 0.0;
          final Color color = Colors.primaries[index % Colors.primaries.length];

          return PieChartSectionData(
            color: color,
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            // Removed badgeWidget to avoid overlapping text
            // You can create a custom legend outside the PieChart if needed for titles
          );
        }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                  // touchCallback is simplified to avoid the error
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Do nothing here if you don't need interactive slices
                      // Or handle touchedSectionIndex if you want to highlight a slice
                      // For example:
                      // setState(() {
                      //   if (event.isInterestedForInteractions) {
                      //     print('Touched index: ${pieTouchResponse?.touchedSection?.touchedSectionIndex}');
                      //   }
                      // });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children:
                  data.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> item = entry.value;
                    final String title = item[titleKey].toString();
                    final Color color =
                        Colors.primaries[index % Colors.primaries.length];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 16, height: 16, color: color),
                        const SizedBox(width: 4),
                        Text(title, style: const TextStyle(fontSize: 12)),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSpendingList() {
    if (_customerSpending.isEmpty) {
      return const Center(child: Text('Không có dữ liệu chi tiêu khách hàng.'));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              _customerSpending.map((customer) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${customer['ten_khach_hang']} (${customer['ma_khach_hang']}): '
                    '${_currencyFormat.format(customer['total_spending'])} (${customer['total_orders']} đơn)',
                    style: const TextStyle(fontSize: 15),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
