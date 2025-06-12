import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/DatabaseHelper.dart'; // Import DatabaseHelper

class QuanLyTrangThaiDonHang extends StatefulWidget {
  const QuanLyTrangThaiDonHang({Key? key}) : super(key: key);

  @override
  _QuanLyTrangThaiDonHangState createState() => _QuanLyTrangThaiDonHangState();
}

class _QuanLyTrangThaiDonHangState extends State<QuanLyTrangThaiDonHang> {
  late Future<List<Map<String, dynamic>>> _hoaDonListFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
  );
  String? _selectedFilterStatus; // State variable for selected filter

  @override
  void initState() {
    super.initState();
    _loadHoaDonList(); // Tải danh sách hóa đơn khi trang được khởi tạo
  }

  // Hàm để tải danh sách hóa đơn từ cơ sở dữ liệu và sắp xếp
  void _loadHoaDonList() {
    setState(() {
      _hoaDonListFuture = QLQuanAnDatabaseHelper.instance
          .getAllHoaDonWithDetails()
          .then((list) {
            // Định nghĩa thứ tự ưu tiên của trạng thái
            int _getStatusPriority(String status) {
              switch (status) {
                case 'Đang chờ xác nhận':
                  return 1;
                case 'Đang chuẩn bị':
                  return 2;
                case 'Đã sẵn sàng':
                  return 3;
                case 'Đã phục vụ':
                  return 4;
                case 'Đã hủy':
                  return 5;
                default:
                  return 99; // Các trạng thái không xác định hoặc ít ưu tiên hơn
              }
            }

            // Lọc danh sách nếu có filter được chọn
            List<Map<String, dynamic>> filteredList = list;
            if (_selectedFilterStatus != null &&
                _selectedFilterStatus != 'Tất cả') {
              filteredList =
                  list
                      .where(
                        (hoaDon) =>
                            hoaDon['trang_thai'] == _selectedFilterStatus,
                      )
                      .toList();
            }

            // Sắp xếp danh sách hóa đơn đã lọc
            filteredList.sort((a, b) {
              final aStatus = a['trang_thai'] ?? 'Unknown';
              final bStatus = b['trang_thai'] ?? 'Unknown';

              final aPriority = _getStatusPriority(aStatus);
              final bPriority = _getStatusPriority(bStatus);

              // Sắp xếp theo ưu tiên trạng thái
              if (aPriority != bPriority) {
                return aPriority.compareTo(bPriority);
              }

              // Nếu cùng trạng thái, sắp xếp theo ngày đặt (từ cũ đến mới)
              final aDate =
                  DateTime.tryParse(a['ngay_dat'] ?? '') ?? DateTime(0);
              final bDate =
                  DateTime.tryParse(b['ngay_dat'] ?? '') ?? DateTime(0);
              return aDate.compareTo(bDate);
            });
            return filteredList;
          });
    });
  }

  // Hàm để lấy màu sắc tương ứng với trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang chờ xác nhận':
        return Colors.orange;
      case 'Đang chuẩn bị':
        return Colors.blue;
      case 'Đã sẵn sàng':
        return Colors.lightGreen;
      case 'Đã phục vụ':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Hàm cập nhật trạng thái hóa đơn (cho các trạng thái thông thường)
  Future<void> _updateOrderStatus(String maHoaDon, String currentStatus) async {
    String? newStatus;
    switch (currentStatus) {
      case 'Đang chờ xác nhận':
        newStatus = 'Đang chuẩn bị';
        break;
      case 'Đang chuẩn bị':
        newStatus = 'Đã sẵn sàng';
        break;
      case 'Đã sẵn sàng':
        newStatus = 'Đã phục vụ';
        break;
      // Nếu trạng thái là 'Đã phục vụ' hoặc 'Đã hủy', không cho phép cập nhật tiếp
      default:
        newStatus = null;
    }

    if (newStatus != null) {
      await QLQuanAnDatabaseHelper.instance.updateHoaDonStatus(
        maHoaDon,
        newStatus,
      );
      _loadHoaDonList(); // Tải lại danh sách sau khi cập nhật
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật trạng thái hóa đơn $maHoaDon thành "$newStatus"',
          ),
          duration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật trạng thái hóa đơn này.'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  // Hàm hiển thị dialog hủy đơn hàng cho nhân viên/quản lý với lý do
  Future<void> _showCancelOrderDialogForStaff(String maHoaDon) async {
    final TextEditingController reasonController = TextEditingController();
    String? selectedReason;
    final List<String> commonReasons = [
      'Hết món',
      'Món ăn chưa đến',
      'Hết nguyên liệu',
      'Khác (ghi rõ)',
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hủy đơn hàng và nhập lý do'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Chọn lý do hủy',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedReason,
                  items:
                      commonReasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    selectedReason = newValue;
                    if (newValue != 'Khác (ghi rõ)') {
                      reasonController.text = newValue ?? '';
                    } else {
                      reasonController
                          .clear(); // Xóa nếu chọn "Khác" để người dùng nhập
                    }
                    (ctx as Element)
                        .markNeedsBuild(); // Rebuild dialog to update TextFormField
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do chi tiết (nếu có)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy bỏ'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.isNotEmpty) {
                  await QLQuanAnDatabaseHelper.instance.updateHoaDonStatus(
                    maHoaDon,
                    'Đã hủy',
                    ghiChu: 'NV/QL hủy: ${reasonController.text}',
                  );
                  _loadHoaDonList(); // Tải lại danh sách sau khi cập nhật
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã hủy hóa đơn $maHoaDon thành công.'),
                      duration: const Duration(milliseconds: 500),
                    ),
                  );
                  Navigator.of(ctx).pop(); // Đóng dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập lý do hủy.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        );
      },
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
    // List of filter options for the dropdown
    final List<String> filterOptions = [
      'Tất cả',
      'Đang chờ xác nhận',
      'Đang chuẩn bị',
      'Đã sẵn sàng',
      'Đã phục vụ',
      'Đã hủy',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Trạng Thái Đơn Hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilterStatus ?? 'Tất cả', // Default value
                icon: const Icon(Icons.filter_list, color: Colors.white),
                style: const TextStyle(color: Colors.black, fontSize: 16),
                dropdownColor: Colors.white,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilterStatus = newValue;
                    _loadHoaDonList(); // Reload list with new filter
                  });
                },
                items:
                    filterOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _hoaDonListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi khi tải đơn hàng: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Hiện chưa có đơn hàng nào.'));
          } else {
            final hoaDonList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: hoaDonList.length,
              itemBuilder: (context, index) {
                final hoaDon = hoaDonList[index];
                final statusColor = _getStatusColor(
                  hoaDon['trang_thai'] ?? 'Unknown',
                );
                final String currentStatus = hoaDon['trang_thai'] ?? 'Unknown';
                // Điều kiện để nút Hủy hiển thị và kích hoạt cho nhân viên/quản lý
                final bool canStaffCancel =
                    currentStatus != 'Đã phục vụ' && currentStatus != 'Đã hủy';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: statusColor,
                      width: 2,
                    ), // Viền theo trạng thái
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(15.0),
                    leading: Icon(
                      Icons.receipt_long,
                      color: statusColor,
                      size: 40,
                    ),
                    title: Text(
                      'Hóa Đơn: ${hoaDon['ma_hoa_don']} - Bàn: ${hoaDon['so_ban'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        // Thêm hiển thị Mã Khách Hàng và Mã Nhân Viên
                        Text(
                          'Mã khách hàng: ${hoaDon['ma_khach_hang'] ?? 'N/A'}',
                        ),
                        Text(
                          'Mã nhân viên: ${hoaDon['ma_nhan_vien'] ?? 'N/A'}',
                        ),
                        Text('Ngày đặt: ${hoaDon['ngay_dat']}'),
                        Text(
                          'Tổng tiền: ${_currencyFormat.format(hoaDon['tong_tien'])}',
                        ),
                        Text('Hình thức: ${hoaDon['hinh_thuc_thanh_toan']}'),
                        Row(
                          children: [
                            Text(
                              'Trạng thái: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hoaDon['trang_thai'] ?? 'Unknown',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ghi chú: ${hoaDon['ghi_chu'] ?? 'Không có'}'),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _showHoaDonDetails(
                                      context,
                                      hoaDon['ma_hoa_don'],
                                    ),
                                icon: const Icon(Icons.info_outline),
                                label: const Text('Xem Chi Tiết Món Ăn'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB2D9),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Nút cập nhật trạng thái
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    currentStatus == 'Đã phục vụ' ||
                                            currentStatus == 'Đã hủy'
                                        ? null // Disable button if status is 'Đã phục vụ' or 'Đã hủy'
                                        : () => _updateOrderStatus(
                                          hoaDon['ma_hoa_don'],
                                          currentStatus,
                                        ),
                                icon: const Icon(Icons.update),
                                label: Text(
                                  _getNextStatusAction(currentStatus),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getStatusColor(
                                    currentStatus,
                                  ),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Nút Hủy đơn hàng cho nhân viên/quản lý
                            if (canStaffCancel) // Chỉ hiển thị nút hủy nếu đơn hàng chưa phục vụ/hủy
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _showCancelOrderDialogForStaff(
                                        hoaDon['ma_hoa_don'],
                                      ),
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Hủy Đơn Hàng',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.red.shade700, // Màu đỏ đậm hơn
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Helper function to get the next status action button text
  String _getNextStatusAction(String currentStatus) {
    switch (currentStatus) {
      case 'Đang chờ xác nhận':
        return 'Xác nhận đơn hàng';
      case 'Đang chuẩn bị':
        return 'Hoàn thành chuẩn bị';
      case 'Đã sẵn sàng':
        return 'Đã phục vụ';
      case 'Đã phục vụ':
        return 'Đã hoàn tất'; // Hoặc ẩn nút
      case 'Đã hủy':
        return 'Đã hủy'; // Hoặc ẩn nút
      default:
        return 'Không thể cập nhật';
    }
  }
}
