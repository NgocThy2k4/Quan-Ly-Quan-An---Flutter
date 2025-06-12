import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../database/DatabaseHelper.dart';
import '../../models/KhachHang.dart';
import '../../models/User.dart'; // Import User model

class QuanLyKhachHangPage extends StatefulWidget {
  const QuanLyKhachHangPage({Key? key}) : super(key: key);

  @override
  _QuanLyKhachHangPageState createState() => _QuanLyKhachHangPageState();
}

class _QuanLyKhachHangPageState extends State<QuanLyKhachHangPage> {
  late Future<List<KhachHang>> _khachHangListFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKhachHangList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadKhachHangList() {
    setState(() {
      if (_searchController.text.isNotEmpty) {
        _khachHangListFuture = QLQuanAnDatabaseHelper.instance.searchKhachHang(
          _searchController.text,
        );
      } else {
        _khachHangListFuture =
            QLQuanAnDatabaseHelper.instance.getAllKhachHang();
      }
    });
  }

  Future<void> _addOrEditKhachHang({KhachHang? khachHang}) async {
    final TextEditingController tenKhachHangController = TextEditingController(
      text: khachHang?.tenKhachHang,
    );
    final TextEditingController diaChiController = TextEditingController(
      text: khachHang?.diaChi,
    );
    final TextEditingController dienThoaiController = TextEditingController(
      text: khachHang?.dienThoai,
    );
    final TextEditingController ghiChuController = TextEditingController(
      text: khachHang?.ghiChu,
    );

    // Để lưu đường dẫn ảnh tạm thời sau khi chọn
    String? _pickedImagePath = khachHang?.hinhAnh;
    // Khách hàng hiện tại có hình ảnh hay không
    bool hasExistingImage =
        khachHang?.hinhAnh != null && khachHang!.hinhAnh!.isNotEmpty;

    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                khachHang == null ? 'Thêm Khách Hàng Mới' : 'Sửa Khách Hàng',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: khachHang?.maKhachHang ?? 'Tự động tạo',
                        decoration: InputDecoration(labelText: 'Mã Khách Hàng'),
                        readOnly: true, // Không cho phép sửa mã
                      ),
                      TextFormField(
                        controller: tenKhachHangController,
                        decoration: InputDecoration(
                          labelText: 'Tên Khách Hàng',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Vui lòng nhập tên khách hàng.';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: diaChiController,
                        decoration: InputDecoration(labelText: 'Địa Chỉ'),
                      ),
                      TextFormField(
                        controller: dienThoaiController,
                        decoration: InputDecoration(labelText: 'Điện Thoại'),
                      ),
                      // Hiển thị hình ảnh hiện tại và nút chọn ảnh
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child:
                                _pickedImagePath != null &&
                                        _pickedImagePath!.isNotEmpty &&
                                        File(_pickedImagePath!)
                                            .existsSync() // Kiểm tra file tồn tại
                                    ? Image.file(
                                      File(_pickedImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                    : (hasExistingImage &&
                                            khachHang?.hinhAnh != null
                                        ? Image.asset(
                                          'assets/HinhAnh/KhachHang/${khachHang!.hinhAnh!}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Image.asset(
                                                'assets/HinhAnh/default_avatar.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                        )
                                        : const Icon(Icons.image, size: 50)),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final ImagePicker _picker = ImagePicker();
                                final XFile? image = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null) {
                                  setStateDialog(() {
                                    _pickedImagePath = image.path;
                                  });
                                }
                              },
                              icon: Icon(Icons.photo_library),
                              label: Text('Chọn ảnh từ Gallery'),
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: ghiChuController,
                        decoration: InputDecoration(labelText: 'Ghi Chú'),
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
                      String? finalImagePath =
                          _pickedImagePath != null &&
                                  File(_pickedImagePath!).existsSync()
                              ? _pickedImagePath!.split('/').last
                              : null;

                      if (khachHang == null) {
                        // Thêm mới
                        int nextIdNum =
                            await QLQuanAnDatabaseHelper.instance
                                .getNextMaKhachHang();
                        String newMaKhachHang =
                            'KH${nextIdNum.toString().padLeft(2, '0')}';

                        final newKhachHang = KhachHang(
                          maKhachHang: newMaKhachHang,
                          tenKhachHang: tenKhachHangController.text,
                          diaChi:
                              diaChiController.text.isEmpty
                                  ? null
                                  : diaChiController.text,
                          dienThoai:
                              diaChiController.text.isEmpty
                                  ? null
                                  : dienThoaiController.text,
                          hinhAnh: finalImagePath,
                          ghiChu:
                              ghiChuController.text.isEmpty
                                  ? null
                                  : ghiChuController.text,
                        );
                        await QLQuanAnDatabaseHelper.instance.addKhachHang(
                          newKhachHang,
                        );

                        // Thêm người dùng liên quan nếu chưa có
                        final existingUser = await QLQuanAnDatabaseHelper
                            .instance
                            .getUserByMaNguoiDung(newMaKhachHang);
                        if (existingUser == null) {
                          await QLQuanAnDatabaseHelper.instance.insertUser(
                            User(
                              maNguoiDung: newMaKhachHang,
                              tenDangNhap: tenKhachHangController.text,
                              matKhau: 'password123', // Mật khẩu mặc định
                              email:
                                  '${newMaKhachHang.toLowerCase()}@example.com', // Email mặc định
                              maVaiTro: 'KH',
                              maLienQuan: newMaKhachHang,
                            ).toMap(),
                          );
                        }
                      } else {
                        // Cập nhật
                        final updatedKhachHang = KhachHang(
                          maKhachHang: khachHang.maKhachHang,
                          tenKhachHang: tenKhachHangController.text,
                          diaChi:
                              diaChiController.text.isEmpty
                                  ? null
                                  : diaChiController.text,
                          dienThoai:
                              dienThoaiController.text.isEmpty
                                  ? null
                                  : dienThoaiController.text,
                          hinhAnh: finalImagePath ?? khachHang.hinhAnh,
                          ghiChu:
                              ghiChuController.text.isEmpty
                                  ? null
                                  : ghiChuController.text,
                        );
                        await QLQuanAnDatabaseHelper.instance.updateKhachHang2(
                          updatedKhachHang,
                        );

                        // Cập nhật tên người dùng liên quan nếu tên khách hàng thay đổi
                        final userMap = await QLQuanAnDatabaseHelper.instance
                            .getUserByMaNguoiDung(khachHang.maKhachHang);
                        if (userMap != null) {
                          final user = User.fromMap(userMap);
                          if (user.tenDangNhap !=
                              updatedKhachHang.tenKhachHang) {
                            await QLQuanAnDatabaseHelper.instance.updateUser2(
                              user.copyWith(
                                tenDangNhap: updatedKhachHang.tenKhachHang,
                              ),
                            );
                          }
                        }
                      }
                      _loadKhachHangList();
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(khachHang == null ? 'Thêm' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteKhachHang(String maKhachHang) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    try {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Text(
                'Bạn có chắc chắn muốn xóa khách hàng $maKhachHang không? Thao tác này cũng sẽ xóa người dùng liên quan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop(); // Đóng dialog xác nhận
                    await dbHelper.deleteKhachHangAndUser(maKhachHang);
                    _loadKhachHangList(); // Tải lại danh sách
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã xóa khách hàng $maKhachHang và người dùng liên quan.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Xóa'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa khách hàng: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Khách Hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _addOrEditKhachHang(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã hoặc tên khách hàng...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _loadKhachHangList,
                ),
              ),
              onSubmitted: (_) => _loadKhachHangList(),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body: FutureBuilder<List<KhachHang>>(
        future: _khachHangListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có khách hàng nào.'));
          } else {
            final khachHangList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: khachHangList.length,
              itemBuilder: (context, index) {
                final khachHang = khachHangList[index];
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
                          'Mã Khách Hàng: ${khachHang.maKhachHang}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        Text(
                          'Tên Khách Hàng: ${khachHang.tenKhachHang}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Địa Chỉ: ${khachHang.diaChi ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Điện Thoại: ${khachHang.dienThoai ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (khachHang.hinhAnh != null &&
                            khachHang.hinhAnh!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Image.file(
                              File(
                                khachHang.hinhAnh!,
                              ), // Giả sử hinhAnh là đường dẫn file cục bộ
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Image.asset(
                                    'assets/HinhAnh/default_avatar.jpg', // Ảnh mặc định nếu file không tồn tại
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                        Text(
                          'Ghi Chú: ${khachHang.ghiChu ?? 'N/A'}',
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
                                onPressed:
                                    () => _addOrEditKhachHang(
                                      khachHang: khachHang,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () =>
                                        _deleteKhachHang(khachHang.maKhachHang),
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
