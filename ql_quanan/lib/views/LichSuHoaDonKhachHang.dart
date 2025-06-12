import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/DatabaseHelper.dart'; // Import DatabaseHelper

class LichSuHoaDonKhachHang extends StatefulWidget {
  final String maKhachHang; // Mã khách hàng sẽ được truyền vào
  final String tenKhachHang; // Tên khách hàng để hiển thị trên AppBar

  const LichSuHoaDonKhachHang({
    Key? key,
    required this.maKhachHang,
    required this.tenKhachHang,
  }) : super(key: key);

  @override
  _LichSuHoaDonKhachHangState createState() => _LichSuHoaDonKhachHangState();
}

class _LichSuHoaDonKhachHangState extends State<LichSuHoaDonKhachHang> {
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

  // Hàm để tải danh sách hóa đơn từ cơ sở dữ liệu dựa trên mã khách hàng
  void _loadHoaDonList() {
    setState(() {
      _hoaDonListFuture = QLQuanAnDatabaseHelper.instance
          .getHoaDonByMaKhachHang(widget.maKhachHang)
          .then((list) {
            // Sắp xếp các đơn hàng để đơn hàng đã hủy hiển thị ở cuối
            list.sort((a, b) {
              final aStatus = a['trang_thai'] ?? 'Unknown';
              final bStatus = b['trang_thai'] ?? 'Unknown';

              // Ưu tiên các trạng thái không phải 'Đã hủy' lên trên
              if (aStatus == 'Đã hủy' && bStatus != 'Đã hủy') {
                return 1;
              } else if (aStatus != 'Đã hủy' && bStatus == 'Đã hủy') {
                return -1;
              }

              // Nếu cùng trạng thái (cả hai là 'Đã hủy' hoặc cả hai không phải 'Đã hủy'),
              // sắp xếp theo ngày đặt (từ mới nhất đến cũ nhất)
              final aDate =
                  DateTime.tryParse(a['ngay_dat'] ?? '') ?? DateTime(0);
              final bDate =
                  DateTime.tryParse(b['ngay_dat'] ?? '') ?? DateTime(0);
              return bDate.compareTo(aDate); // Mới nhất lên trước
            });
            return list;
          });
    });
  }

  // Hàm cập nhật trạng thái hóa đơn thành "Đã hủy"
  Future<void> _cancelOrder(String maHoaDon) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    await dbHelper.updateHoaDonStatus(
      maHoaDon,
      'Đã hủy',
      ghiChu: 'Khách hàng hủy đơn',
    );
    _loadHoaDonList(); // Tải lại danh sách sau khi cập nhật
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã hủy hóa đơn $maHoaDon thành công.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Hàm hiển thị dialog xác nhận hủy đơn hàng
  void _showCancelConfirmationDialog(String maHoaDon) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xác nhận hủy đơn hàng'),
            content: Text('Bạn có chắc chắn muốn hủy hóa đơn $maHoaDon không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Không'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Đóng dialog
                  _cancelOrder(maHoaDon); // Thực hiện hủy đơn
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Có, Hủy'),
              ),
            ],
          ),
    );
  }

  void _showChiTietHoaDonDialog(String maHoaDon) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    final chiTietList = await dbHelper.getChiTietHoaDonByMaHoaDon(maHoaDon);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Chi Tiết Hóa Đơn: $maHoaDon'),
            content: SizedBox(
              width: double.maxFinite,
              height:
                  MediaQuery.of(context).size.height *
                  0.6, // Đặt chiều cao tối đa
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch Sử Hóa Đơn: ${widget.tenKhachHang}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFB2D9), // Màu hồng pastel
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _hoaDonListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có hóa đơn nào.'));
          } else {
            final hoaDonList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: hoaDonList.length,
              itemBuilder: (context, index) {
                final hoaDon = hoaDonList[index];
                final String currentStatus = hoaDon['trang_thai'] ?? 'Unknown';
                final bool canCancel = currentStatus == 'Đang chờ xác nhận';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã Hóa Đơn: ${hoaDon['ma_hoa_don']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mã Khách Hàng: ${hoaDon['ma_khach_hang'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Mã Nhân Viên: ${hoaDon['ma_nhan_vien'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Ngày Đặt: ${hoaDon['ngay_dat']}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Tổng Tiền: ${_currencyFormat.format(hoaDon['tong_tien'])}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Tiền Đặt Cọc: ${_currencyFormat.format(hoaDon['tien_dat_coc'])}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Còn Lại: ${_currencyFormat.format(hoaDon['con_lai'])}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Hình Thức TT: ${hoaDon['hinh_thuc_thanh_toan']}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Ghi Chú: ${hoaDon['ghi_chu'] ?? 'Không có'}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Số Bàn: ${hoaDon['so_ban'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 15),
                        ),
                        Text(
                          'Trạng Thái: ${hoaDon['trang_thai'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color:
                                currentStatus == 'Đã hủy'
                                    ? Colors.red
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (canCancel) // Chỉ hiển thị nút hủy nếu trạng thái là "Đang chờ xác nhận"
                              ElevatedButton.icon(
                                onPressed:
                                    () => _showCancelConfirmationDialog(
                                      hoaDon['ma_hoa_don'],
                                    ),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Hủy Đơn Hàng',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  () => _showChiTietHoaDonDialog(
                                    hoaDon['ma_hoa_don'],
                                  ),
                              child: const Text('Xem Chi Tiết'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6790),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
