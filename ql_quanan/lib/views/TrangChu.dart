// views/TrangChu.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:ql_quanan/views/admin/QuanLyHoaDonPage.dart';
import '../controllers/AuthController.dart';
import '../controllers/MonAnController.dart';
import '../controllers/CartController.dart';
import '../models/MonAn.dart';
import '../database/DatabaseHelper.dart'; // Import DatabaseHelper để lấy thông tin khách hàng/nhân viên
import 'DanhSachMonAn.dart';
import 'GioHang.dart';
import 'ThongTinCaNhan.dart';
import 'TrangLienHe.dart';
import 'auth/DangNhap.dart';
import 'admin/AdminDashboard.dart';
import 'admin/QuanLyHoaDonPage.dart'; // Import trang quản lý hóa đơn cho quản lý/nhân viên
import 'LichSuHoaDonKhachHang.dart'; // Import trang lịch sử hóa đơn cho khách hàng

class TrangChu extends StatefulWidget {
  @override
  _TrangChuState createState() => _TrangChuState();
}

class _TrangChuState extends State<TrangChu> {
  final MonAnController _monAnController = MonAnController();
  List<MonAn> _mostPopularFoods = [];
  bool _isLoadingPopular = true;

  @override
  void initState() {
    super.initState();
    _loadPopularFoods();
  }

  Future<void> _loadPopularFoods() async {
    setState(() {
      _isLoadingPopular = true;
    });
    _mostPopularFoods = await _monAnController.fetchAllMonAn();
    // Sắp xếp giảm dần theo đơn giá để lấy món phổ biến nhất
    _mostPopularFoods.sort((a, b) => b.donGia!.compareTo(a.donGia!));
    _mostPopularFoods =
        _mostPopularFoods.take(5).toList(); // Lấy 5 món phổ biến nhất
    setState(() {
      _isLoadingPopular = false;
    });
  }

  // Hàm để lấy đường dẫn ảnh dựa trên vai trò và mã liên quan
  Future<String> _getUserImagePath(String? maVaiTro, String? maLienQuan) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    String defaultPath =
        'assets/HinhAnh/default_avatar.jpg'; // Ảnh mặc định chung

    if (maLienQuan == null) return defaultPath;

    if (maVaiTro == 'KH') {
      final khachHang = await dbHelper.getKhachHangByMa(maLienQuan);
      if (khachHang != null && khachHang['hinh_anh'] != null) {
        return 'assets/HinhAnh/KhachHang/${khachHang['hinh_anh']}';
      }
    } else if (maVaiTro == 'NV' || maVaiTro == 'QL') {
      final nhanVien = await dbHelper.getNhanVienByMa(maLienQuan);
      if (nhanVien != null && nhanVien['hinh_anh'] != null) {
        return 'assets/HinhAnh/NhanVien/${nhanVien['hinh_anh']}';
      }
    }
    return defaultPath;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;

    // Kiểm tra vai trò của người dùng
    final bool isCustomer = user != null && user.maVaiTro == 'KH';
    final bool isEmployeeOrManager =
        user != null && (user.maVaiTro == 'NV' || user.maVaiTro == 'QL');
    final bool isAdmin = user != null && user.maVaiTro == 'QL';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(
                'assets/HinhAnh/Logo.jpg',
              ), // Logo quán ăn
            ),
            const SizedBox(width: 10),
            const Text(
              'Quán Ăn Ngon',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GioHang()),
                  );
                },
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Consumer<CartController>(
                  builder: (context, cart, child) {
                    return Visibility(
                      visible: cart.totalItems > 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      drawer: Drawer(
        child: Container(
          color: Colors.pink[50], // Màu nền hồng nhạt cho Drawer
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Header của Drawer
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB2D9),
                ), // Màu hồng pastel
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getUserImagePath(
                        user?.maVaiTro,
                        user?.maLienQuan,
                      ),
                      builder: (context, snapshot) {
                        String imagePath =
                            snapshot.data ??
                            'assets/HinhAnh/default_avatar.jpg'; // Default nếu không có
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(imagePath),
                          onBackgroundImageError: (exception, stackTrace) {
                            // Fallback to a default image if the specified image doesn't load
                            setState(() {
                              imagePath = 'assets/HinhAnh/default_avatar.jpg';
                            });
                          },
                        );
                      },
                    ),
                    Text(
                      user?.tenDangNhap ?? 'Khách',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? 'Chưa đăng nhập',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Các mục điều hướng chung
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFFE91E63)),
                title: Text(
                  'Trang Chủ',
                  style: TextStyle(color: Colors.pink[800]),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFFE91E63),
                ),
                title: Text(
                  'Thực Đơn',
                  style: TextStyle(color: Colors.pink[800]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrangDanhSachMonAn(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.contact_mail,
                  color: Color(0xFFE91E63),
                ),
                title: Text(
                  'Liên Hệ',
                  style: TextStyle(color: Colors.pink[800]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TrangLienHe()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFE91E63)),
                title: Text(
                  'Thông tin cá nhân',
                  style: TextStyle(color: Colors.pink[800]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThongTinCaNhan()),
                  );
                },
              ),
              // HIỂN THỊ LỊCH SỬ HÓA ĐƠN CHO KHÁCH HÀNG
              if (isCustomer && user?.maVaiTro == 'KH') ...[
                const Divider(color: Color(0xFFFFB2D9)),
                ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: Colors.blue,
                  ), // Icon lịch sử
                  title: Text(
                    'Lịch Sử Hóa Đơn',
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                  // START: Vị trí của đoạn code bạn hỏi
                  onTap: () async {
                    Navigator.pop(context);
                    // Lấy tên khách hàng để truyền vào trang lịch sử hóa đơn
                    final khachHangData = await QLQuanAnDatabaseHelper.instance
                        .getKhachHangByMa(user!.maLienQuan!);
                    final tenKhachHang =
                        khachHangData?['ten_khach_hang'] ?? user.tenDangNhap;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => LichSuHoaDonKhachHang(
                              maKhachHang:
                                  user.maLienQuan!, // <-- TRUYỀN MA_KHÁCH_HÀNG VÀO ĐÂY
                              tenKhachHang: tenKhachHang,
                            ),
                      ),
                    );
                  },
                  // END: Vị trí của đoạn code bạn hỏi
                ),
              ],
              // HIỂN THỊ MỤC QUẢN LÝ HÓA ĐƠN CHO NHÂN VIÊN VÀ QUẢN LÝ
              if (isEmployeeOrManager) ...[
                // <--- Đã sửa điều kiện về đúng `isEmployeeOrManager`
                const Divider(color: Color(0xFFFFB2D9)),
                ListTile(
                  leading: const Icon(
                    Icons.description,
                    color: Colors.purple,
                  ), // Icon hóa đơn
                  title: Text(
                    'Quản Lý Hóa Đơn',
                    style: TextStyle(color: Colors.purple[800]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuanLyHoaDonPage(),
                      ), // <--- Điều hướng đến QuanLyHoaDon
                    );
                  },
                ),
              ],
              // HIỂN THỊ CÁC MỤC QUẢN LÝ KHÁC CHỈ KHI LÀ ADMIN
              if (isAdmin) ...[
                const Divider(color: Color(0xFFFFB2D9)),
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    'Bảng Điều Khiển Quản Lý',
                    style: TextStyle(
                      color: Colors.deepPurple[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDashboard()),
                    );
                  },
                ),
              ],
              const Divider(color: Color(0xFFFFB2D9)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Đăng Xuất',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  authController.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => DangNhap()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Món Ăn Phổ Biến Nhất',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
              ),
            ),
            _isLoadingPopular
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFB2D9),
                    ),
                  ),
                )
                : _mostPopularFoods.isEmpty
                ? Center(
                  child: Text('Không có món ăn phổ biến nào để hiển thị.'),
                )
                : CarouselSlider.builder(
                  itemCount: _mostPopularFoods.length,
                  itemBuilder: (
                    BuildContext context,
                    int itemIndex,
                    int pageViewIndex,
                  ) {
                    final monAn = _mostPopularFoods[itemIndex];
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: Image.asset(
                                    'assets/HinhAnh/MonAn/${monAn.hinh}',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Text('Không có hình ảnh'),
                                            ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  monAn.tenMon,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  options: CarouselOptions(
                    height: 250,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enableInfiniteScroll: true,
                    autoPlayAnimationDuration: const Duration(
                      milliseconds: 800,
                    ),
                    viewportFraction: 0.8,
                  ),
                ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Thực Đơn Đa Dạng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrangDanhSachMonAn(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Xem Toàn Bộ Thực Đơn'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
