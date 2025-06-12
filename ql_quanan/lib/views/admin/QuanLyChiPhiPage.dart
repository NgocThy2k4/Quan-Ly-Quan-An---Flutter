import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/DatabaseHelper.dart';

class QuanLyChiPhiPage extends StatefulWidget {
  const QuanLyChiPhiPage({Key? key}) : super(key: key);

  @override
  _QuanLyChiPhiPageState createState() => _QuanLyChiPhiPageState();
}

class _QuanLyChiPhiPageState extends State<QuanLyChiPhiPage> {
  late Future<List<Map<String, dynamic>>> _chiPhiListFuture;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _loaiChiPhiOptions = ['nguyen_lieu', 'hoat_dong', 'khac'];

  @override
  void initState() {
    super.initState();
    _loadChiPhiList();
  }

  void _loadChiPhiList() {
    setState(() {
      // Hiện tại không có tìm kiếm theo tên/mã cho chi phí, chỉ lấy tất cả
      _chiPhiListFuture = QLQuanAnDatabaseHelper.instance.getAllChiPhi();
    });
  }

  void _showChiPhiDialog({Map<String, dynamic>? chiPhi}) {
    final _formKey = GlobalKey<FormState>();
    final _maChiPhiController = TextEditingController(
      text: chiPhi?['ma_chi_phi'],
    );
    final _tenChiPhiController = TextEditingController(
      text: chiPhi?['ten_chi_phi'],
    );
    final _soTienController = TextEditingController(
      text: chiPhi?['so_tien']?.toString(),
    );
    final _ghiChuController = TextEditingController(text: chiPhi?['ghi_chu']);
    DateTime? _ngayChi =
        chiPhi != null ? DateTime.tryParse(chiPhi['ngay_chi']) : DateTime.now();
    String? _selectedLoaiChiPhi = chiPhi?['loai_chi_phi'];

    bool isEditing = chiPhi != null;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isEditing ? 'Sửa Chi Phí' : 'Thêm Chi Phí'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _maChiPhiController,
                      decoration: const InputDecoration(
                        labelText: 'Mã Chi Phí',
                      ),
                      readOnly: isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã chi phí';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _tenChiPhiController,
                      decoration: const InputDecoration(
                        labelText: 'Tên Chi Phí',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên chi phí';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedLoaiChiPhi,
                      decoration: const InputDecoration(
                        labelText: 'Loại Chi Phí',
                      ),
                      items:
                          _loaiChiPhiOptions.map((loai) {
                            return DropdownMenuItem<String>(
                              value: loai,
                              child: Text(loai),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          // Cần setState của StatefulBuilder của dialog
                          _selectedLoaiChiPhi = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn loại chi phí';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _soTienController,
                      decoration: const InputDecoration(labelText: 'Số Tiền'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Số tiền phải là số';
                        }
                        return null;
                      },
                    ),
                    ListTile(
                      title: Text(
                        'Ngày Chi: ${DateFormat('dd/MM/yyyy').format(_ngayChi!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _ngayChi ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            // Cần setState của StatefulBuilder của dialog
                            _ngayChi = pickedDate;
                          });
                        }
                      },
                    ),
                    TextFormField(
                      controller: _ghiChuController,
                      decoration: const InputDecoration(labelText: 'Ghi Chú'),
                      maxLines: 3,
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
                    final Map<String, dynamic> newChiPhi = {
                      'ma_chi_phi': _maChiPhiController.text,
                      'ten_chi_phi': _tenChiPhiController.text,
                      'loai_chi_phi': _selectedLoaiChiPhi!,
                      'so_tien': double.parse(_soTienController.text),
                      'ngay_chi': DateFormat('yyyy-MM-dd').format(_ngayChi!),
                      'ghi_chu':
                          _ghiChuController.text.isNotEmpty
                              ? _ghiChuController.text
                              : null,
                    };

                    if (isEditing) {
                      await QLQuanAnDatabaseHelper.instance.updateChiPhi(
                        newChiPhi,
                      );
                    } else {
                      await QLQuanAnDatabaseHelper.instance.insertChiPhi(
                        newChiPhi,
                      );
                    }
                    _loadChiPhiList();
                    Navigator.of(ctx).pop();
                  }
                },
                child: Text(isEditing ? 'Lưu' : 'Thêm'),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteChiPhi(String maChiPhi) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa chi phí có mã $maChiPhi không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await QLQuanAnDatabaseHelper.instance.deleteChiPhi(maChiPhi);
                  _loadChiPhiList();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa chi phí $maChiPhi'),
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
          'Quản Lý Chi Phí',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB2D9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showChiPhiDialog(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm chi phí...',
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
              onChanged: (value) {
                // Hiện tại không có tìm kiếm cho chi phí, có thể thêm sau
                // _loadChiPhiList();
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chiPhiListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có chi phí nào.'));
          } else {
            final chiPhiList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: chiPhiList.length,
              itemBuilder: (context, index) {
                final chiPhi = chiPhiList[index];
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
                          'Mã CP: ${chiPhi['ma_chi_phi']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                        Text(
                          'Tên CP: ${chiPhi['ten_chi_phi']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Loại: ${chiPhi['loai_chi_phi']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Số tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(chiPhi['so_tien'])}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Ngày chi: ${chiPhi['ngay_chi']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Ghi chú: ${chiPhi['ghi_chu'] ?? 'Không có'}',
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
                                    () => _showChiPhiDialog(chiPhi: chiPhi),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _confirmDeleteChiPhi(
                                      chiPhi['ma_chi_phi'],
                                    ),
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
