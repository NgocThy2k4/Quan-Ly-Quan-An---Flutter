import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../database/DatabaseHelper.dart';
import '../../models/NhanVien.dart';
import '../../models/User.dart'; // Import User model

class QuanLyNhanVienPage extends StatefulWidget {
  const QuanLyNhanVienPage({Key? key}) : super(key: key);

  @override
  _QuanLyNhanVienPageState createState() => _QuanLyNhanVienPageState();
}

class _QuanLyNhanVienPageState extends State<QuanLyNhanVienPage> {
  late Future<List<NhanVien>> _nhanVienListFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNhanVienList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNhanVienList() {
    setState(() {
      if (_searchController.text.isNotEmpty) {
        _nhanVienListFuture = QLQuanAnDatabaseHelper.instance.searchNhanVien(
          _searchController.text,
        );
      } else {
        _nhanVienListFuture = QLQuanAnDatabaseHelper.instance.getAllNhanVien();
      }
    });
  }

  Future<void> _addOrEditNhanVien({NhanVien? nhanVien}) async {
    final TextEditingController tenNhanVienController = TextEditingController(
      text: nhanVien?.tenNhanVien,
    );
    final TextEditingController chucVuController = TextEditingController(
      text: nhanVien?.chucVu,
    );
    final TextEditingController diaChiController = TextEditingController(
      text: nhanVien?.diaChi,
    );
    final TextEditingController dienThoaiController = TextEditingController(
      text: nhanVien?.dienThoai,
    );
    String? _pickedImagePath = nhanVien?.hinhAnh;
    bool hasExistingImage =
        nhanVien?.hinhAnh != null && nhanVien!.hinhAnh!.isNotEmpty;

    final TextEditingController ghiChuController = TextEditingController(
      text: nhanVien?.ghiChu,
    );

    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                nhanVien == null ? 'Thêm Nhân Viên Mới' : 'Sửa Nhân Viên',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: nhanVien?.maNhanVien ?? 'Tự động tạo',
                        decoration: InputDecoration(labelText: 'Mã Nhân Viên'),
                        readOnly: true, // Không cho phép sửa mã
                      ),
                      TextFormField(
                        controller: tenNhanVienController,
                        decoration: InputDecoration(labelText: 'Tên Nhân Viên'),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Vui lòng nhập tên nhân viên.';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: chucVuController,
                        decoration: InputDecoration(labelText: 'Chức Vụ'),
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
                                        _pickedImagePath!.isNotEmpty
                                    ? Image.file(
                                      File(_pickedImagePath!),
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
                                    : (hasExistingImage &&
                                            nhanVien?.hinhAnh != null
                                        ? Image.asset(
                                          'assets/HinhAnh/NhanVien/${nhanVien!.hinhAnh!}',
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
                          _pickedImagePath != null
                              ? _pickedImagePath!.split('/').last
                              : null;

                      if (nhanVien == null) {
                        // Thêm mới
                        int nextIdNum =
                            await QLQuanAnDatabaseHelper.instance
                                .getNextMaNhanVien();
                        String newMaNhanVien =
                            'NV${nextIdNum.toString().padLeft(2, '0')}';

                        final newNhanVien = NhanVien(
                          maNhanVien: newMaNhanVien,
                          tenNhanVien: tenNhanVienController.text,
                          chucVu:
                              chucVuController.text.isEmpty
                                  ? null
                                  : chucVuController.text,
                          diaChi:
                              diaChiController.text.isEmpty
                                  ? null
                                  : diaChiController.text,
                          dienThoai:
                              dienThoaiController.text.isEmpty
                                  ? null
                                  : dienThoaiController.text,
                          hinhAnh: finalImagePath,
                          ghiChu:
                              ghiChuController.text.isEmpty
                                  ? null
                                  : ghiChuController.text,
                        );
                        await QLQuanAnDatabaseHelper.instance.addNhanVien(
                          newNhanVien,
                        );

                        // Thêm người dùng liên quan nếu chưa có
                        final existingUser = await QLQuanAnDatabaseHelper
                            .instance
                            .getUserByMaNguoiDung(newMaNhanVien);
                        if (existingUser == null) {
                          await QLQuanAnDatabaseHelper.instance.addUser(
                            User(
                              maNguoiDung: newMaNhanVien,
                              tenDangNhap: tenNhanVienController.text,
                              matKhau: 'password123', // Mật khẩu mặc định
                              email:
                                  '${newMaNhanVien.toLowerCase()}@example.com', // Email mặc định
                              maVaiTro:
                                  'NV', // Mặc định là nhân viên, admin tự chỉnh sau
                              maLienQuan: newMaNhanVien,
                            ),
                          );
                        }
                      } else {
                        // Cập nhật
                        final updatedNhanVien = NhanVien(
                          maNhanVien: nhanVien.maNhanVien,
                          tenNhanVien: tenNhanVienController.text,
                          chucVu:
                              chucVuController.text.isEmpty
                                  ? null
                                  : chucVuController.text,
                          diaChi:
                              diaChiController.text.isEmpty
                                  ? null
                                  : diaChiController.text,
                          dienThoai:
                              dienThoaiController.text.isEmpty
                                  ? null
                                  : dienThoaiController.text,
                          hinhAnh:
                              finalImagePath ??
                              nhanVien
                                  .hinhAnh, // Giữ ảnh cũ nếu không chọn ảnh mới
                          ghiChu:
                              ghiChuController.text.isEmpty
                                  ? null
                                  : ghiChuController.text,
                        );
                        await QLQuanAnDatabaseHelper.instance.updateNhanVien2(
                          updatedNhanVien,
                        );

                        // Cập nhật tên người dùng liên quan nếu tên nhân viên thay đổi
                        final userMap = await QLQuanAnDatabaseHelper.instance
                            .getUserByMaNguoiDung(nhanVien.maNhanVien);
                        if (userMap != null) {
                          final user = User.fromMap(userMap);
                          if (user.tenDangNhap != updatedNhanVien.tenNhanVien) {
                            await QLQuanAnDatabaseHelper.instance.updateUser2(
                              user.copyWith(
                                tenDangNhap: updatedNhanVien.tenNhanVien,
                              ),
                            );
                          }
                        }
                      }
                      _loadNhanVienList();
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(nhanVien == null ? 'Thêm' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNhanVien(String maNhanVien) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    try {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Text(
                'Bạn có chắc chắn muốn xóa nhân viên $maNhanVien không? Thao tác này cũng sẽ xóa người dùng liên quan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop(); // Đóng dialog xác nhận
                    await dbHelper.deleteNhanVienAndUser(maNhanVien);
                    _loadNhanVienList(); // Tải lại danh sách
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã xóa nhân viên $maNhanVien và người dùng liên quan.',
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
        SnackBar(content: Text('Lỗi khi xóa nhân viên: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Nhân Viên',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            onPressed: () => _addOrEditNhanVien(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã hoặc tên nhân viên...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _loadNhanVienList,
                ),
              ),
              onSubmitted: (_) => _loadNhanVienList(),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body: FutureBuilder<List<NhanVien>>(
        future: _nhanVienListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có nhân viên nào.'));
          } else {
            final nhanVienList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: nhanVienList.length,
              itemBuilder: (context, index) {
                final nhanVien = nhanVienList[index];
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
                          'Mã Nhân Viên: ${nhanVien.maNhanVien}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        Text(
                          'Tên Nhân Viên: ${nhanVien.tenNhanVien}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Chức Vụ: ${nhanVien.chucVu ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Địa Chỉ: ${nhanVien.diaChi ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Điện Thoại: ${nhanVien.dienThoai ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (nhanVien.hinhAnh != null &&
                            nhanVien.hinhAnh!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Image.file(
                              File(
                                nhanVien.hinhAnh!,
                              ), // Giả sử hinhAnh là đường dẫn file cục bộ
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Image.asset(
                                    'assets/HinhAnh/default_avatar.jpg',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                        Text(
                          'Ghi Chú: ${nhanVien.ghiChu ?? 'N/A'}',
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
                                    () =>
                                        _addOrEditNhanVien(nhanVien: nhanVien),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _deleteNhanVien(nhanVien.maNhanVien),
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
