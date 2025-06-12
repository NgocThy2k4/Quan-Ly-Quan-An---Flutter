import 'package:flutter/material.dart';
import '../../database/DatabaseHelper.dart';
import '../../models/NhanVien.dart';

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
    final TextEditingController maNhanVienController = TextEditingController(
      text: nhanVien?.maNhanVien,
    );
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
    final TextEditingController hinhAnhController = TextEditingController(
      text: nhanVien?.hinhAnh,
    );
    final TextEditingController ghiChuController = TextEditingController(
      text: nhanVien?.ghiChu,
    );

    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
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
                    controller: maNhanVienController,
                    decoration: InputDecoration(
                      labelText: 'Mã Nhân Viên (NVxx)',
                    ),
                    enabled:
                        nhanVien == null, // Không cho phép sửa mã khi chỉnh sửa
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Vui lòng nhập mã nhân viên.';
                      return null;
                    },
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
                  TextFormField(
                    controller: hinhAnhController,
                    decoration: InputDecoration(
                      labelText: 'Tên file Hình ảnh (ví dụ: image.jpg)',
                    ),
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
                  final newNhanVien = NhanVien(
                    maNhanVien: maNhanVienController.text,
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
                        hinhAnhController.text.isEmpty
                            ? null
                            : hinhAnhController.text,
                    ghiChu:
                        ghiChuController.text.isEmpty
                            ? null
                            : ghiChuController.text,
                  );

                  final dbHelper = QLQuanAnDatabaseHelper.instance;
                  if (nhanVien == null) {
                    // Thêm mới
                    await dbHelper.addNhanVien(newNhanVien);
                  } else {
                    // Cập nhật
                    await dbHelper.updateNhanVien2(newNhanVien);
                  }
                  _loadNhanVienList(); // Tải lại danh sách
                  Navigator.of(ctx).pop();
                }
              },
              child: Text(nhanVien == null ? 'Thêm' : 'Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNhanVien(String maNhanVien) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    try {
      await dbHelper.deleteNhanVien(maNhanVien);
      _loadNhanVienList(); // Tải lại danh sách
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xóa nhân viên $maNhanVien')));
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
