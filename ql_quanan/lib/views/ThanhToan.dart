import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/CartController.dart'; // Import CartController
import '../database/DatabaseHelper.dart'; // Import DatabaseHelper để tương tác với DB
import '../models/User.dart'; // Import User model
import '../models/KhachHang.dart'; // Import KhachHang model
import '../models/NhanVien.dart'; // Import NhanVien model
import '../controllers/AuthController.dart'; // Import AuthController

// Enum để định nghĩa các phương thức thanh toán
enum PaymentMethod { cash, qrCode, card }

class ThanhToan extends StatefulWidget {
  const ThanhToan({Key? key}) : super(key: key); // Add const keyword and Key

  @override
  _ThanhToanState createState() => _ThanhToanState();
}

class _ThanhToanState extends State<ThanhToan> {
  // Biến trạng thái để lưu phương thức thanh toán được chọn, mặc định là Tiền mặt
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  // Controllers cho các trường nhập liệu của phương thức thanh toán bằng thẻ
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderNameController =
      TextEditingController();

  User? _currentUser;
  String? _maKhachHang; // Mã khách hàng thực tế từ người dùng đăng nhập
  String?
  _maNhanVien; // Mã nhân viên thực tế (tạm thời, có thể cần lấy từ AuthController)

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // Load user info when the widget initializes
  }

  // Function to load user information for populating maKhachHang/maNhanVien
  Future<void> _loadUserInfo() async {
    _currentUser =
        Provider.of<AuthController>(context, listen: false).currentUser;

    if (_currentUser != null) {
      if (_currentUser!.maVaiTro == 'KH' && _currentUser!.maLienQuan != null) {
        _maKhachHang = _currentUser!.maLienQuan;
      } else if ((_currentUser!.maVaiTro == 'NV' ||
              _currentUser!.maVaiTro == 'QL') &&
          _currentUser!.maLienQuan != null) {
        // If a staff/manager is logged in, they are likely the one processing, or we need a default customer
        // For simplicity, if an NV/QL is logged in, we'll assign a default customer ID,
        // or you can implement a customer selection mechanism.
        // For now, if NV/QL logs in, payment will be linked to a default customer.
        // You'll need to modify this logic if you want NV/QL to select a customer for the order.
        _maKhachHang = 'KH01'; // Default customer for staff/manager orders
        _maNhanVien = _currentUser!.maLienQuan;
      }
    } else {
      // If no user is logged in, use default IDs or handle as anonymous.
      _maKhachHang = 'KH01'; // Fallback to a default customer
      _maNhanVien = 'NV01'; // Fallback to a default employee
    }
    setState(() {}); // Update the UI after loading user info
  }

  @override
  void dispose() {
    // Đảm bảo giải phóng các controllers khi widget bị hủy để tránh rò rỉ bộ nhớ
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy CartController từ Provider để truy cập thông tin giỏ hàng
    final cartController = Provider.of<CartController>(context);
    // Định dạng tiền tệ Việt Nam Đồng
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thanh Toán',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9), // Màu hồng pastel
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFFCE4EC), // Màu hồng nhạt cho nền
      body: SingleChildScrollView(
        // Vẫn giữ SingleChildScrollView để cuộn toàn bộ trang
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xác nhận đơn hàng',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63), // Màu hồng đậm
              ),
            ),
            const SizedBox(height: 20),
            // Hiển thị danh sách các món ăn trong giỏ hàng
            // Container này giới hạn chiều cao của danh sách món ăn
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ), // Giới hạn chiều cao của danh sách món ăn
              child: ListView.builder(
                // Cho phép ListView này tự cuộn nếu nội dung vượt quá maxHeight của Container cha.
                itemCount: cartController.items.length,
                itemBuilder: (context, index) {
                  final item = cartController.items[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          // Ảnh món ăn
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.asset(
                              'assets/HinhAnh/MonAn/${item.monAn.hinh}', // Đường dẫn ảnh
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Thông tin món ăn
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.monAn.tenMon,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Số lượng: ${item.quantity}'),
                                Text(
                                  'Giá: ${currencyFormat.format(item.totalPrice)}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            // Hiển thị tổng cộng số tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(cartController.getTotalPrice()),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Chọn phương thức thanh toán:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 10), // Added some space
            // Bọc phần chọn phương thức thanh toán trong Card để dễ nhìn hơn
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    RadioListTile<PaymentMethod>(
                      title: const Text('Tiền mặt'),
                      value: PaymentMethod.cash,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                          debugPrint(
                            'Selected Payment Method: $_selectedPaymentMethod',
                          ); // Debug print
                        });
                      },
                      activeColor: const Color(0xFFE91E63), // Màu chủ đạo
                    ),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Chuyển khoản quét mã QR'),
                      value: PaymentMethod.qrCode,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                          debugPrint(
                            'Selected Payment Method: $_selectedPaymentMethod',
                          ); // Debug print
                        });
                      },
                      activeColor: const Color(0xFFE91E63),
                    ),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Thẻ Tín dụng/Ghi nợ'),
                      value: PaymentMethod.card,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (PaymentMethod? value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                          debugPrint(
                            'Selected Payment Method: $_selectedPaymentMethod',
                          ); // Debug print
                        });
                      },
                      activeColor: const Color(0xFFE91E63),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Hiển thị chi tiết phương thức thanh toán dựa trên lựa chọn
            _buildPaymentDetails(),
            const SizedBox(height: 30),
            // Nút "Hoàn tất Thanh toán"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Xử lý logic thanh toán khi nút được nhấn
                  _processPayment(context, cartController);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFFF6790,
                  ), // Màu nút thanh toán hồng đậm
                  foregroundColor: Colors.white, // Màu chữ trên nút
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Bo tròn nút
                  ),
                ),
                child: const Text(
                  'Hoàn tất Thanh toán',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm xây dựng giao diện chi tiết cho từng phương thức thanh toán
  Widget _buildPaymentDetails() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        return Card(
          elevation: 2,
          color: Colors.yellow[50], // Nền màu vàng nhạt cho thông báo
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 30,
                ), // Icon thông tin
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vui lòng gửi tiền mặt đến nhân viên thu ngân để hoàn tất thanh toán.',
                    style: TextStyle(fontSize: 16, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        );
      case PaymentMethod.qrCode:
        return Card(
          elevation: 2,
          color: Colors.blue[50], // Nền màu xanh nhạt cho thông tin QR
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Quét mã QR để thanh toán:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                // Hình ảnh mã QR code (bạn cần thay thế bằng mã QR thực tế)
                Image.asset(
                  'assets/HinhAnh/QR_placeholder.png', // <--- Cần thêm ảnh QR code vào đây
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    // Hiển thị thông báo nếu không tìm thấy ảnh
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text(
                          'Mã QR không có sẵn\nVui lòng liên hệ nhân viên',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ngân hàng: VIETCOMBANK',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  'Số tài khoản: 0123456789',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  'Tên tài khoản: NGUYEN VAN A',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Nội dung chuyển khoản: THANH TOAN DON HANG [Mã đơn hàng của bạn]',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      case PaymentMethod.card:
        return Card(
          elevation: 2,
          color: Colors.green[50], // Nền màu xanh lá nhạt cho thông tin thẻ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Thông tin thẻ Tín dụng/Ghi nợ:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 15),
                // Trường nhập số thẻ
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số thẻ',
                    hintText: 'xxxx xxxx xxxx xxxx',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.credit_card),
                  ),
                  maxLength: 19, // 16 số + 3 khoảng trắng
                  onChanged: (value) {
                    // Tự động thêm khoảng trắng sau mỗi 4 chữ số
                    String newValue = value.replaceAll(
                      RegExp(r'\s'),
                      '',
                    ); // Xóa khoảng trắng cũ
                    if (newValue.isNotEmpty) {
                      newValue = newValue.replaceAllMapped(
                        RegExp(r'.{4}'),
                        (match) => '${match.group(0)} ',
                      );
                    }
                    if (newValue != _cardNumberController.text) {
                      _cardNumberController.value = TextEditingValue(
                        text:
                            newValue
                                .trimRight(), // Xóa khoảng trắng thừa ở cuối
                        selection: TextSelection.collapsed(
                          offset: newValue.trimRight().length,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Trường nhập tên chủ thẻ
                TextFormField(
                  controller: _cardHolderNameController,
                  textCapitalization:
                      TextCapitalization.characters, // Tự động viết hoa
                  decoration: InputDecoration(
                    labelText: 'Tên chủ thẻ',
                    hintText: 'NGUYEN VAN A',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                // Trường nhập ngày hết hạn và CVV
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'Ngày hết hạn',
                          hintText: 'MM/YY',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        maxLength: 5, // MM/YY
                        onChanged: (value) {
                          // Tự động thêm '/' sau 2 chữ số
                          String newValue = value.replaceAll(
                            RegExp(r'\D'),
                            '',
                          ); // Xóa ký tự không phải số
                          if (newValue.length >= 2) {
                            newValue =
                                newValue.substring(0, 2) +
                                (newValue.length > 2
                                    ? '/' + newValue.substring(2)
                                    : '');
                          }
                          if (newValue.length > 5) {
                            newValue = newValue.substring(
                              0,
                              5,
                            ); // Đảm bảo không vượt quá MM/YY
                          }

                          if (newValue != _expiryDateController.text) {
                            _expiryDateController.value = TextEditingValue(
                              text: newValue,
                              selection: TextSelection.collapsed(
                                offset: newValue.length,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: 'XXX',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        maxLength: 3, // 3 chữ số cho CVV
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Thông tin thẻ của bạn sẽ được bảo mật tuyệt đối.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      default:
        return Container(); // Không hiển thị gì nếu không có phương thức nào được chọn (trường hợp này không xảy ra)
    }
  }

  // Hàm xử lý thanh toán khi nhấn nút "Hoàn tất Thanh toán"
  void _processPayment(
    BuildContext context,
    CartController cartController,
  ) async {
    // Make this async
    String paymentMessage = '';
    bool isValid = true; // Biến kiểm tra tính hợp lệ của dữ liệu nhập vào

    // Xử lý dựa trên phương thức thanh toán đã chọn
    if (_selectedPaymentMethod == PaymentMethod.card) {
      // Kiểm tra validation cho thanh toán thẻ
      if (_cardNumberController.text.isEmpty ||
          _expiryDateController.text.isEmpty ||
          _cvvController.text.isEmpty ||
          _cardHolderNameController.text.isEmpty) {
        paymentMessage = 'Vui lòng nhập đầy đủ thông tin thẻ.';
        isValid = false;
      } else if (_cardNumberController.text.replaceAll(' ', '').length < 16) {
        paymentMessage = 'Số thẻ không hợp lệ. Vui lòng kiểm tra lại.';
        isValid = false;
      } else if (!RegExp(
        r'^\d{2}\/\d{2}$',
      ).hasMatch(_expiryDateController.text)) {
        paymentMessage = 'Ngày hết hạn không hợp lệ (MM/YY).';
        isValid = false;
      } else if (!RegExp(r'^\d{3}$').hasMatch(_cvvController.text)) {
        paymentMessage = 'Mã CVV không hợp lệ (3 chữ số).';
        isValid = false;
      } else {
        paymentMessage = 'Đang xử lý thanh toán bằng thẻ...';
      }
    } else if (_selectedPaymentMethod == PaymentMethod.cash) {
      paymentMessage =
          'Đơn hàng đã được xác nhận. Vui lòng thanh toán tiền mặt cho nhân viên thu ngân.';
    } else if (_selectedPaymentMethod == PaymentMethod.qrCode) {
      paymentMessage =
          'Đơn hàng đã được xác nhận. Vui lòng quét mã QR để chuyển khoản.';
    }

    // Hiển thị dialog thông báo lỗi hoặc đang xử lý
    if (!isValid) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Lỗi Thanh Toán'),
              content: Text(paymentMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
      );
    } else {
      // Giả lập quá trình xử lý thanh toán
      showDialog(
        context: context,
        barrierDismissible:
            false, // Không cho phép đóng dialog bằng cách chạm ra ngoài
        builder:
            (ctx) => AlertDialog(
              title: const Text('Thông báo thanh toán'),
              content: Text(paymentMessage),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Make this async to await database operations
                    Navigator.of(
                      ctx,
                    ).pop(); // Đóng dialog hiện tại (thông báo xử lý)

                    // Lưu hóa đơn vào cơ sở dữ liệu
                    await _saveOrderToDatabase(cartController);

                    // Sau đó hiển thị dialog thành công và quay về trang chính
                    cartController
                        .clearCart(); // Xóa giỏ hàng sau khi thanh toán
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Thanh toán thành công!'),
                            content: const Text(
                              'Đơn hàng của bạn đã được tiếp nhận.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Đóng dialog thành công
                                  // Quay về trang chính (ví dụ: trang đầu tiên trong stack điều hướng)
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  // Hàm để lưu thông tin đơn hàng vào cơ sở dữ liệu
  Future<void> _saveOrderToDatabase(CartController cartController) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    try {
      // Generate a unique invoice ID
      // This is where the issue might be. We need to ensure getNextHoaDonId()
      // provides a genuinely new, incremented ID each time it's called.
      final nextInvoiceNumber = await dbHelper.getNextHoaDonId();
      final maHoaDon =
          'HD${nextInvoiceNumber.toString().padLeft(3, '0')}'; // Ví dụ: HD001, HD002

      // Lấy ngày hiện tại
      final ngayDat = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Mã khách hàng và nhân viên
      // Cần lấy từ _maKhachHang và _maNhanVien đã được load từ AuthController
      final maKhachHangFinal = _maKhachHang ?? 'KH01'; // Fallback if not set
      final maNhanVienFinal = _maNhanVien ?? 'NV01'; // Fallback if not set

      final tongTien = cartController.getTotalPrice();
      final hinhThucThanhToan =
          _selectedPaymentMethod == PaymentMethod.cash
              ? 'Tiền mặt'
              : (_selectedPaymentMethod == PaymentMethod.qrCode
                  ? 'Chuyển khoản'
                  : 'Thẻ');

      // Chuẩn bị dữ liệu cho bảng hoa_don
      final hoaDonData = {
        'ma_hoa_don': maHoaDon,
        'ma_khach_hang': maKhachHangFinal,
        'ma_nhan_vien': maNhanVienFinal,
        'ngay_dat': ngayDat,
        'tong_tien': tongTien,
        'tien_dat_coc': tongTien, // Giả định thanh toán đủ tiền
        'con_lai': 0.0, // Giả định thanh toán đủ tiền
        'hinh_thuc_thanh_toan': hinhThucThanhToan,
        'ghi_chu': 'Thanh toán online qua ứng dụng',
      };

      // Chèn dữ liệu vào bảng hoa_don
      await dbHelper.insert('hoa_don', hoaDonData);
      print('DBG: Đã chèn hóa đơn: $hoaDonData');

      // Chèn dữ liệu vào bảng chi_tiet_hoa_don cho từng món trong giỏ hàng
      for (var item in cartController.items) {
        final chiTietHoaDonData = {
          'ma_hoa_don': maHoaDon,
          'ma_mon': item.monAn.maMon,
          'so_luong': item.quantity,
          'don_gia': item.monAn.donGia, // Lấy đơn giá từ đối tượng MonAn
          'mon_thuc_don':
              1, // Giả định là món trong thực đơn chính. Điều chỉnh nếu có loại khác.
        };
        await dbHelper.insert('chi_tiet_hoa_don', chiTietHoaDonData);
        print('DBG: Đã chèn chi tiết hóa đơn: $chiTietHoaDonData');
      }
    } catch (e) {
      print('Lỗi khi lưu đơn hàng vào cơ sở dữ liệu: $e');
      // Có thể hiển thị thông báo lỗi cho người dùng tại đây
    }
  }
}
