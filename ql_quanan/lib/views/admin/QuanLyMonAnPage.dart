import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/DatabaseHelper.dart';
import '../../models/MonAn.dart';
import '../../models/LoaiMonAn.dart';

class QuanLyMonAnPage extends StatefulWidget {
  const QuanLyMonAnPage({Key? key}) : super(key: key);

  @override
  _QuanLyMonAnPageState createState() => _QuanLyMonAnPageState();
}

class _QuanLyMonAnPageState extends State<QuanLyMonAnPage> {
  late Future<List<MonAn>> _monAnListFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
  );
  TextEditingController _searchController = TextEditingController();
  String? _selectedLoaiMonAn;
  List<LoaiMonAn> _loaiMonAnList = [];

  @override
  void initState() {
    super.initState();
    _loadLoaiMonAn();
    _loadMonAnList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLoaiMonAn() async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    _loaiMonAnList = await dbHelper.getAllLoaiMonAn();
    setState(() {});
  }

  void _loadMonAnList() {
    setState(() {
      if (_searchController.text.isNotEmpty) {
        _monAnListFuture = QLQuanAnDatabaseHelper.instance.searchMonAn(
          _searchController.text,
        );
      } else if (_selectedLoaiMonAn != null && _selectedLoaiMonAn != 'Tất cả') {
        _monAnListFuture = QLQuanAnDatabaseHelper.instance.getMonAnByLoai(
          _selectedLoaiMonAn!,
        );
      } else {
        _monAnListFuture = QLQuanAnDatabaseHelper.instance.getAllMonAn();
      }
    });
  }

  Future<void> _addOrEditMonAn({MonAn? monAn}) async {
    final TextEditingController maMonController = TextEditingController(
      text: monAn?.maMon,
    );
    final TextEditingController tenMonController = TextEditingController(
      text: monAn?.tenMon,
    );
    final TextEditingController noiDungTomTatController = TextEditingController(
      text: monAn?.noiDungTomTat,
    );
    final TextEditingController noiDungChiTietController =
        TextEditingController(text: monAn?.noiDungChiTiet);
    final TextEditingController donGiaController = TextEditingController(
      text: monAn?.donGia?.toString(),
    );
    final TextEditingController donGiaKhuyenMaiController =
        TextEditingController(text: monAn?.donGiaKhuyenMai?.toString());
    final TextEditingController khuyenMaiController = TextEditingController(
      text: monAn?.khuyenMai,
    );
    final TextEditingController hinhController = TextEditingController(
      text: monAn?.hinh,
    );
    final TextEditingController dvtController = TextEditingController(
      text: monAn?.dvt,
    );
    final TextEditingController trongNgayController = TextEditingController(
      text: monAn?.trongNgay?.toString(),
    );

    String? selectedLoaiMonAn = monAn?.maLoai;

    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(monAn == null ? 'Thêm Món Ăn Mới' : 'Sửa Món Ăn'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: maMonController,
                        decoration: InputDecoration(labelText: 'Mã Món (MAxx)'),
                        enabled:
                            monAn ==
                            null, // Không cho phép sửa mã khi chỉnh sửa
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Vui lòng nhập mã món.';
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedLoaiMonAn,
                        decoration: InputDecoration(labelText: 'Loại Món Ăn'),
                        items:
                            _loaiMonAnList.map((loai) {
                              return DropdownMenuItem(
                                value: loai.maLoai,
                                child: Text(loai.tenLoai ?? ''),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            selectedLoaiMonAn = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Vui lòng chọn loại món ăn.';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: tenMonController,
                        decoration: InputDecoration(labelText: 'Tên Món'),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Vui lòng nhập tên món.';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: noiDungTomTatController,
                        decoration: InputDecoration(
                          labelText: 'Nội Dung Tóm Tắt',
                        ),
                      ),
                      TextFormField(
                        controller: noiDungChiTietController,
                        decoration: InputDecoration(
                          labelText: 'Nội Dung Chi Tiết',
                        ),
                      ),
                      TextFormField(
                        controller: donGiaController,
                        decoration: InputDecoration(labelText: 'Đơn Giá'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Vui lòng nhập đơn giá.';
                          if (double.tryParse(value) == null)
                            return 'Đơn giá phải là số.';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: donGiaKhuyenMaiController,
                        decoration: InputDecoration(
                          labelText: 'Đơn Giá Khuyến Mãi (Tùy chọn)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: khuyenMaiController,
                        decoration: InputDecoration(labelText: 'Khuyến Mãi'),
                      ),
                      TextFormField(
                        controller: hinhController,
                        decoration: InputDecoration(
                          labelText: 'Tên file Hình ảnh (ví dụ: image.jpg)',
                        ),
                      ),
                      TextFormField(
                        controller: dvtController,
                        decoration: InputDecoration(
                          labelText: 'Đơn Vị Tính (ví dụ: Đĩa, Bát)',
                        ),
                      ),
                      TextFormField(
                        controller: trongNgayController,
                        decoration: InputDecoration(
                          labelText: 'Trong Ngày (0 hoặc 1)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (int.tryParse(value) == null ||
                                (int.parse(value) != 0 &&
                                    int.parse(value) != 1)) {
                              return 'Giá trị phải là 0 hoặc 1.';
                            }
                          }
                          return null;
                        },
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
                      final newMonAn = MonAn(
                        maMon: maMonController.text,
                        maLoai: selectedLoaiMonAn!,
                        tenMon: tenMonController.text,
                        noiDungTomTat:
                            noiDungTomTatController.text.isEmpty
                                ? null
                                : noiDungTomTatController.text,
                        noiDungChiTiet:
                            noiDungChiTietController.text.isEmpty
                                ? null
                                : noiDungChiTietController.text,
                        donGia: double.tryParse(donGiaController.text),
                        donGiaKhuyenMai: double.tryParse(
                          donGiaKhuyenMaiController.text.isEmpty
                              ? '0'
                              : donGiaKhuyenMaiController.text,
                        ),
                        khuyenMai:
                            khuyenMaiController.text.isEmpty
                                ? null
                                : khuyenMaiController.text,
                        hinh:
                            hinhController.text.isEmpty
                                ? null
                                : hinhController.text,
                        ngayCapNhat: DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.now()),
                        dvt:
                            dvtController.text.isEmpty
                                ? null
                                : dvtController.text,
                        trongNgay: int.tryParse(
                          trongNgayController.text.isEmpty
                              ? '0'
                              : trongNgayController.text,
                        ),
                      );

                      final dbHelper = QLQuanAnDatabaseHelper.instance;
                      if (monAn == null) {
                        // Thêm mới
                        await dbHelper.addMonAn(newMonAn);
                      } else {
                        // Cập nhật
                        await dbHelper.updateMonAn(newMonAn);
                      }
                      _loadMonAnList(); // Tải lại danh sách
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(monAn == null ? 'Thêm' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMonAn(String maMon) async {
    final dbHelper = QLQuanAnDatabaseHelper.instance;
    try {
      await dbHelper.deleteMonAn(maMon);
      _loadMonAnList(); // Tải lại danh sách
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xóa món ăn $maMon')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa món ăn: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Món Ăn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            onPressed: () => _addOrEditMonAn(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo mã hoặc tên món ăn...',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _loadMonAnList,
                    ),
                  ),
                  onSubmitted: (_) => _loadMonAnList(),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLoaiMonAn,
                  hint: const Text('Lọc theo loại món ăn'),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'Tất cả',
                      child: Text('Tất cả'),
                    ),
                    ..._loaiMonAnList.map((loai) {
                      return DropdownMenuItem(
                        value: loai.maLoai,
                        child: Text(loai.tenLoai ?? 'N/A'),
                      );
                    }).toList(),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedLoaiMonAn = newValue;
                      _loadMonAnList();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body: FutureBuilder<List<MonAn>>(
        future: _monAnListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có món ăn nào.'));
          } else {
            final monAnList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: monAnList.length,
              itemBuilder: (context, index) {
                final monAn = monAnList[index];
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
                          'Mã Món: ${monAn.maMon}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        Text(
                          'Tên Món: ${monAn.tenMon}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Loại: ${monAn.maLoai}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Đơn Giá: ${_currencyFormat.format(monAn.donGia)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (monAn.donGiaKhuyenMai != null &&
                            monAn.donGiaKhuyenMai! > 0)
                          Text(
                            'Giá KM: ${_currencyFormat.format(monAn.donGiaKhuyenMai)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        Text(
                          'Mô tả: ${monAn.noiDungTomTat ?? 'N/A'}',
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
                                onPressed: () => _addOrEditMonAn(monAn: monAn),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteMonAn(monAn.maMon),
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
