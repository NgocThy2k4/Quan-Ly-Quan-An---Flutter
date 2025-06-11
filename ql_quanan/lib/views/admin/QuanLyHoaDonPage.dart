import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/DatabaseHelper.dart'; // Import DatabaseHelper

class QuanLyHoaDonPage extends StatefulWidget {
  @override
  _QuanLyHoaDonState createState() => _QuanLyHoaDonState();
}

class _QuanLyHoaDonState extends State<QuanLyHoaDonPage> {
  late Future<List<Map<String, dynamic>>> _hoaDonListFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
  );

  @override
  void initState() {
    super.initState();
    _loadHoaDonList(); // Tải danh sách hóa đơn khi trang được khởi tạo
  }

  // Hàm để tải danh sách hóa đơn từ cơ sở dữ liệu
  void _loadHoaDonList() {
    setState(() {
      _hoaDonListFuture = QLQuanAnDatabaseHelper.instance.getAllHoaDon();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Hóa Đơn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9), // Màu hồng pastel
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFFCE4EC), // Màu hồng nhạt cho nền
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _hoaDonListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Hiển thị vòng tròn loading khi đang chờ dữ liệu
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Hiển thị thông báo lỗi nếu có lỗi
            return Center(
              child: Text('Lỗi khi tải hóa đơn: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Hiển thị thông báo nếu không có hóa đơn nào
            return const Center(child: Text('Chưa có hóa đơn nào được tạo.'));
          } else {
            // Hiển thị danh sách hóa đơn
            final hoaDonList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: hoaDonList.length,
              itemBuilder: (context, index) {
                final hoaDon = hoaDonList[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15.0),
                    leading: const Icon(
                      Icons.receipt,
                      color: Color(0xFFE91E63),
                      size: 40,
                    ),
                    title: Text(
                      'Mã Hóa Đơn: ${hoaDon['ma_hoa_don']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text('Ngày đặt: ${hoaDon['ngay_dat']}'),
                        Text(
                          'Tổng tiền: ${_currencyFormat.format(hoaDon['tong_tien'])}',
                        ),
                        Text('Hình thức: ${hoaDon['hinh_thuc_thanh_toan']}'),
                        Text('Khách hàng: ${hoaDon['ma_khach_hang']}'),
                        Text('Nhân viên: ${hoaDon['ma_nhan_vien']}'),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      // Xử lý khi người dùng nhấn vào một hóa đơn để xem chi tiết
                      _showHoaDonDetails(context, hoaDon['ma_hoa_don']);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Hàm hiển thị chi tiết hóa đơn trong một dialog
  void _showHoaDonDetails(BuildContext context, String maHoaDon) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    final chiTietList = await dbHelper.getChiTietHoaDonByMaHoaDon(maHoaDon);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Chi Tiết Hóa Đơn: $maHoaDon'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  chiTietList.isEmpty
                      ? const Text('Không có chi tiết cho hóa đơn này.')
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: chiTietList.length,
                        itemBuilder: (context, index) {
                          final item = chiTietList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '- Mã món: ${item['ma_mon']} | SL: ${item['so_luong']} | Đơn giá: ${_currencyFormat.format(item['don_gia'])}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }
}
