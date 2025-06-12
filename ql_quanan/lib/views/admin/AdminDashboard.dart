import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/AuthController.dart';
import '../auth/DangNhap.dart'; // Import DangNhap nếu cần
import 'QuanLyNhanVienPage.dart';
import 'QuanLyKhachHangPage.dart';
import 'QuanLyMonAnPage.dart';
import 'QuanLyHoaDonPage.dart'; // Import trang quản lý hóa đơn
import 'QuanLyNguoiDungPage.dart'; // Import trang quản lý người dùng
import 'BaoCaoDoanhThuPage.dart'; // Import trang báo cáo
import 'ThongKePage.dart'; // Import trang thống kê mới

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    // Đảm bảo người dùng là Admin, nếu không thì redirect về DangNhap
    if (authController.currentUser == null ||
        authController.currentUser!.maVaiTro != 'QL') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DangNhap()),
          (Route<dynamic> route) => false,
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ), // Hoặc một màn hình loading/redirect
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bảng Điều Khiển Quản Lý',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          // Changed Column to ListView for scrollability
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.people,
                  color: Colors.blueAccent,
                  size: 30,
                ),
                title: const Text(
                  'Quản Lý Nhân Viên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuanLyNhanVienPage(),
                    ),
                  );
                },
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(Icons.group, color: Colors.green, size: 30),
                title: const Text(
                  'Quản Lý Khách Hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuanLyKhachHangPage(),
                    ),
                  );
                },
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.fastfood,
                  color: Colors.orange,
                  size: 30,
                ),
                title: const Text(
                  'Quản Lý Món Ăn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuanLyMonAnPage(),
                    ),
                  );
                },
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.receipt,
                  color: Colors.blueAccent,
                  size: 30,
                ),
                title: const Text(
                  'Quản Lý Hóa Đơn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuanLyHoaDonPage()),
                  );
                },
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.account_circle,
                  color: Colors.purple,
                  size: 30,
                ),
                title: const Text(
                  'Quản Lý Người Dùng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuanLyNguoiDungPage(),
                    ),
                  );
                },
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.analytics,
                  color: Colors.deepOrange,
                  size: 30,
                ),
                title: const Text(
                  'Báo Cáo Doanh Thu & Lợi Nhuận',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BaoCaoDoanhThuPage(),
                    ),
                  );
                },
              ),
            ),
            // Thêm chức năng Thống Kê Tổng Quan
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.bar_chart, // Icon cho thống kê
                  color: Colors.teal,
                  size: 30,
                ),
                title: const Text(
                  'Thống Kê Tổng Quan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const ThongKePage(), // Điều hướng đến ThongKePage
                    ),
                  );
                },
              ),
            ),
            // Thêm các chức năng quản lý khác ở đây
          ],
        ),
      ),
    );
  }
}
