import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/DatabaseHelper.dart';
import 'package:fl_chart/fl_chart.dart'; // Thêm thư viện biểu đồ

class ThongKePage extends StatefulWidget {
  const ThongKePage({Key? key}) : super(key: key);

  @override
  _ThongKePageState createState() => _ThongKePageState();
}

class _ThongKePageState extends State<ThongKePage> {
  final QLQuanAnDatabaseHelper _dbHelper = QLQuanAnDatabaseHelper.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
  );

  int _totalOrders = 0;
  int _uniqueCustomersCount = 0;
  double _averageOrderValue = 0.0;
  List<Map<String, dynamic>> _ordersByPaymentMethod = [];
  List<Map<String, dynamic>> _orderStatusBreakdown = [];

  @override
  void initState() {
    super.initState();
    _loadStatisticsData();
  }

  Future<void> _loadStatisticsData() async {
    setState(() {
      _totalOrders = 0;
      _uniqueCustomersCount = 0;
      _averageOrderValue = 0.0;
      _ordersByPaymentMethod = [];
      _orderStatusBreakdown = [];
    });

    _totalOrders = await _dbHelper.getTotalOrderCount();
    _uniqueCustomersCount = await _dbHelper.getUniqueCustomerCount();
    _averageOrderValue = await _dbHelper.getAverageOrderValue();
    _ordersByPaymentMethod = await _dbHelper.getOrdersByPaymentMethod();
    _orderStatusBreakdown = await _dbHelper.getOrderStatusBreakdown();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thống Kê Tổng Quan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStatisticsData,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Các Số Liệu Chính'),
            _buildSummaryCard(
              title: 'Tổng Số Đơn Hàng',
              value: _totalOrders.toString(),
              icon: Icons.receipt_long,
              color: Colors.blue.shade600,
            ),
            _buildSummaryCard(
              title: 'Tổng Số Khách Hàng',
              value: _uniqueCustomersCount.toString(),
              icon: Icons.people,
              color: Colors.orange.shade600,
            ),
            _buildSummaryCard(
              title: 'Giá Trị Trung Bình Mỗi Đơn',
              value: _currencyFormat.format(_averageOrderValue),
              icon: Icons.monetization_on,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Đơn Hàng Theo Phương Thức Thanh Toán'),
            _buildPieChartCard(
              _ordersByPaymentMethod,
              'count',
              'hinh_thuc_thanh_toan',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Tình Trạng Đơn Hàng'),
            _buildPieChartCard(_orderStatusBreakdown, 'count', 'trang_thai'),
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

  Widget _buildPieChartCard(
    List<Map<String, dynamic>> data,
    String valueKey,
    String titleKey,
  ) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu ${titleKey.contains('thanh_toan') ? 'phương thức thanh toán' : 'tình trạng đơn hàng'}.',
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
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Xử lý tương tác nếu cần
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
}
