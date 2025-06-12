import 'package:flutter/material.dart';
import '../../database/DatabaseHelper.dart';
import '../../models/KhachHang.dart';

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
    final TextEditingController maKhachHangController = TextEditingController(
      text: khachHang?.maKhachHang,
    );
    final TextEditingController tenKhachHangController = TextEditingController(
      text: khachHang?.tenKhachHang,
    );
    final TextEditingController diaChiController = TextEditingController(
      text: khachHang?.diaChi,
    );
    final TextEditingController dienThoaiController = TextEditingController(
      text: khachHang?.dienThoai,
    );
    final TextEditingController hinhAnhController = TextEditingController(
      text: khachHang?.hinhAnh,
    );
    final TextEditingController ghiChuController = TextEditingController(
      text: khachHang?.ghiChu,
    );

    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
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
                    controller: maKhachHangController,
                    decoration: InputDecoration(
                      labelText: 'Mã Khách Hàng (KHxx)',
                    ),
                    enabled:
                        khachHang ==
                        null, // Không cho phép sửa mã khi chỉnh sửa
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Vui lòng nhập mã khách hàng.';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: tenKhachHangController,
                    decoration: InputDecoration(labelText: 'Tên Khách Hàng'),
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
                  final newKhachHang = KhachHang(
                    maKhachHang: maKhachHangController.text,
                    tenKhachHang: tenKhachHangController.text,
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
                  if (khachHang == null) {
                    // Thêm mới
                    await dbHelper.addKhachHang(newKhachHang);
                  } else {
                    // Cập nhật
                    await dbHelper.updateKhachHang2(newKhachHang);
                  }
                  _loadKhachHangList(); // Tải lại danh sách
                  Navigator.of(ctx).pop();
                }
              },
              child: Text(khachHang == null ? 'Thêm' : 'Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteKhachHang(String maKhachHang) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    try {
      await dbHelper.deleteKhachHang(maKhachHang);
      _loadKhachHangList(); // Tải lại danh sách
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xóa khách hàng $maKhachHang')));
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
