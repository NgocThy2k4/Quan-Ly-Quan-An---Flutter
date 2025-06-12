import 'package:flutter/material.dart';
import '../../database/DatabaseHelper.dart';
import '../../models/User.dart';
import '../../models/NhanVien.dart'; // Import NhanVien
import '../../models/KhachHang.dart'; // Import KhachHang

class QuanLyNguoiDungPage extends StatefulWidget {
  const QuanLyNguoiDungPage({Key? key}) : super(key: key);

  @override
  _QuanLyNguoiDungPageState createState() => _QuanLyNguoiDungPageState();
}

class _QuanLyNguoiDungPageState extends State<QuanLyNguoiDungPage> {
  late Future<List<User>> _userListFuture;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _vaiTroOptions = [
    'QL',
    'NV',
    'KH',
  ]; // Các vai trò có thể có

  @override
  void initState() {
    super.initState();
    _loadUserList();
  }

  void _loadUserList() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _userListFuture = QLQuanAnDatabaseHelper.instance.getAllUsers2();
      } else {
        _userListFuture = QLQuanAnDatabaseHelper.instance.searchUsers(
          _searchController.text,
        );
      }
    });
  }

  void _showUserDialog({User? user}) {
    final _formKey = GlobalKey<FormState>();
    final _maNguoiDungController = TextEditingController(
      text: user?.maNguoiDung,
    );
    final _tenDangNhapController = TextEditingController(
      text: user?.tenDangNhap,
    );
    final _matKhauController = TextEditingController(
      text: user?.matKhau,
    ); // Hiển thị mật khẩu đã lưu
    final _emailController = TextEditingController(text: user?.email);
    final _maLienQuanController = TextEditingController(text: user?.maLienQuan);

    String? _selectedVaiTro = user?.maVaiTro; // Để chọn vai trò

    bool isEditing = user != null;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isEditing ? 'Sửa Người Dùng' : 'Thêm Người Dùng'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _maNguoiDungController,
                      decoration: const InputDecoration(
                        labelText: 'Mã Người Dùng',
                      ),
                      readOnly: isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã người dùng';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _tenDangNhapController,
                      decoration: const InputDecoration(
                        labelText: 'Tên Đăng Nhập',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên đăng nhập';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _matKhauController,
                      decoration: const InputDecoration(labelText: 'Mật Khẩu'),
                      obscureText:
                          !isEditing, // Ẩn mật khẩu khi thêm mới, hiển thị khi sửa
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Email không hợp lệ.';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedVaiTro,
                      decoration: const InputDecoration(
                        labelText: 'Mã Vai Trò',
                      ),
                      items:
                          _vaiTroOptions.map((vaiTro) {
                            return DropdownMenuItem<String>(
                              value: vaiTro,
                              child: Text(vaiTro),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          // Cần setState của StatefulBuilder của dialog
                          _selectedVaiTro = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn vai trò';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _maLienQuanController,
                      decoration: const InputDecoration(
                        labelText: 'Mã Liên Quan (KH/NV)',
                      ),
                      // Không bắt buộc, có thể null
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newUser = User(
                      maNguoiDung: _maNguoiDungController.text,
                      tenDangNhap: _tenDangNhapController.text,
                      matKhau: _matKhauController.text,
                      email: _emailController.text,
                      maVaiTro: _selectedVaiTro!,
                      maLienQuan:
                          _maLienQuanController.text.isNotEmpty
                              ? _maLienQuanController.text
                              : null,
                    );

                    if (isEditing) {
                      await QLQuanAnDatabaseHelper.instance.updateUser2(
                        newUser,
                      );
                    } else {
                      await QLQuanAnDatabaseHelper.instance.addUser(newUser);
                      // Khi thêm người dùng mới, kiểm tra và tạo KhachHang/NhanVien liên quan nếu chưa có
                      if (newUser.maVaiTro == 'KH' &&
                          newUser.maLienQuan != null) {
                        final existingKhachHang = await QLQuanAnDatabaseHelper
                            .instance
                            .getKhachHangByMa(newUser.maLienQuan!);
                        if (existingKhachHang == null) {
                          await QLQuanAnDatabaseHelper.instance.addKhachHang(
                            KhachHang(
                              maKhachHang: newUser.maLienQuan!,
                              tenKhachHang: newUser.tenDangNhap,
                            ),
                          );
                        }
                      } else if ((newUser.maVaiTro == 'NV' ||
                              newUser.maVaiTro == 'QL') &&
                          newUser.maLienQuan != null) {
                        final existingNhanVien = await QLQuanAnDatabaseHelper
                            .instance
                            .getNhanVienByMa(newUser.maLienQuan!);
                        if (existingNhanVien == null) {
                          await QLQuanAnDatabaseHelper.instance.addNhanVien(
                            NhanVien(
                              maNhanVien: newUser.maLienQuan!,
                              tenNhanVien: newUser.tenDangNhap,
                              chucVu:
                                  newUser.maVaiTro == 'QL'
                                      ? 'Quản lý'
                                      : 'Nhân viên',
                            ),
                          );
                        }
                      }
                    }
                    _loadUserList();
                    Navigator.of(ctx).pop();
                  }
                },
                child: Text(isEditing ? 'Lưu' : 'Thêm'),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteUser(String maNguoiDung) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa người dùng có mã $maNguoiDung không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await QLQuanAnDatabaseHelper.instance.deleteUser(maNguoiDung);
                  _loadUserList();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa người dùng $maNguoiDung'),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Người Dùng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showUserDialog(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => _loadUserList(),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<User>>(
        future: _userListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có người dùng nào.'));
          } else {
            final userList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
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
                          'Mã ND: ${user.maNguoiDung}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        Text(
                          'Tên ĐN: ${user.tenDangNhap}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Email: ${user.email}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Vai trò: ${user.maVaiTro}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Mã liên quan: ${user.maLienQuan ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showUserDialog(user: user),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _confirmDeleteUser(user.maNguoiDung),
                              ),
                            ],
                          ),
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
