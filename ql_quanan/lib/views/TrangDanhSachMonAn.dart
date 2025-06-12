// views/DanhSachMonAn.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // Import để kiểm tra file tồn tại

import '../controllers/MonAnController.dart';
import '../controllers/CartController.dart';
import '../models/MonAn.dart';
import '../models/LoaiMonAn.dart'; // Import LoaiMonAn
import '../database/DatabaseHelper.dart'; // Import DatabaseHelper để lấy loại món ăn
import 'ChiTietMonAn.dart';
import 'GioHang.dart';

class TrangDanhSachMonAn extends StatefulWidget {
  final String? initialFilter; // Thêm tham số này để nhận bộ lọc từ Trang Chủ

  const TrangDanhSachMonAn({Key? key, this.initialFilter}) : super(key: key);

  @override
  _TrangDanhSachMonAnState createState() => _TrangDanhSachMonAnState();
}

class _TrangDanhSachMonAnState extends State<TrangDanhSachMonAn> {
  final MonAnController _monAnController = MonAnController();
  late Future<List<MonAn>> _monAnListFuture;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLoaiMonAn; // Biến để lưu loại món ăn được chọn
  List<LoaiMonAn> _loaiMonAnList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoaiMonAnAndInitialFilter(); // Tải loại món ăn và áp dụng bộ lọc ban đầu
    _searchController.addListener(
      _onSearchChanged,
    ); // Lắng nghe thay đổi của search bar
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Hàm tải loại món ăn và áp dụng bộ lọc ban đầu
  Future<void> _loadLoaiMonAnAndInitialFilter() async {
    setState(() {
      isLoading = true;
    });
    try {
      _loaiMonAnList = await QLQuanAnDatabaseHelper.instance.getAllLoaiMonAn();
      // Áp dụng bộ lọc ban đầu nếu có
      _applyFilter(widget.initialFilter);
    } catch (e) {
      print("Lỗi khi tải loại món ăn hoặc dữ liệu ban đầu: $e");
      _monAnListFuture = Future.value([]); // Trả về danh sách rỗng nếu lỗi
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Hàm áp dụng bộ lọc và tải lại danh sách món ăn
  void _applyFilter(String? filter) {
    setState(() {
      _selectedLoaiMonAn =
          null; // Reset bộ lọc loại khi có filter mới từ trang chủ
      if (filter == 'discounted') {
        _monAnListFuture = _monAnController.fetchDiscountedFoods();
      } else if (filter == 'promotion') {
        _monAnListFuture = _monAnController.fetchPromotionFoods();
      } else if (filter == 'most_ordered') {
        _monAnListFuture = _monAnController.fetchMostOrderedFoods();
      } else {
        _monAnListFuture = _monAnController.fetchAllMonAn();
      }
    });
  }

  // Hàm tải danh sách món ăn dựa trên tìm kiếm và lọc
  void _loadMonAnList() {
    setState(() {
      isLoading = true;
      if (_searchController.text.isNotEmpty) {
        // Tìm kiếm theo tên hoặc mã món ăn, có thể kết hợp với loại
        _monAnListFuture = _monAnController.searchMonAn(
          _searchController.text,
          maLoai: _selectedLoaiMonAn,
        );
      } else if (_selectedLoaiMonAn != null && _selectedLoaiMonAn!.isNotEmpty) {
        // Lọc theo loại món ăn nếu không có tìm kiếm
        _monAnListFuture = _monAnController.fetchMonAnByLoai(
          _selectedLoaiMonAn!,
        );
      } else {
        // Không tìm kiếm, không lọc theo loại -> tải tất cả món ăn
        _monAnListFuture = _monAnController.fetchAllMonAn();
      }
      _monAnListFuture.then((_) {
        setState(() {
          isLoading = false;
        });
      });
    });
  }

  void _onSearchChanged() {
    _loadMonAnList(); // Tải lại danh sách khi người dùng gõ vào ô tìm kiếm
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Provider.of<CartController>(context, listen: false);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực Đơn', style: TextStyle(color: Colors.white)),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0), // Tăng chiều cao AppBar
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm món ăn...',
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
                      value: null, // Giá trị null để hiển thị "Tất cả"
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
                      _loadMonAnList(); // Tải lại danh sách khi thay đổi loại
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFCE4EC),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB2D9)),
                ),
              )
              : FutureBuilder<List<MonAn>>(
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
                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: monAnList.length,
                      itemBuilder: (context, index) {
                        return MonAnCard(
                          monAn: monAnList[index],
                          currencyFormat:
                              currencyFormat, // Truyền currencyFormat
                          onAddToCart: (MonAn monAn) {
                            cartController.addItem(monAn);
                            _showSnackBar(
                              context,
                              'Đã thêm vào giỏ hàng thành công!',
                              const Color(0xFFFF4081),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
    );
  }
}

class MonAnCard extends StatelessWidget {
  final MonAn monAn;
  final Function(MonAn) onAddToCart;
  final NumberFormat currencyFormat; // Thêm currencyFormat

  const MonAnCard({
    Key? key,
    required this.monAn,
    required this.onAddToCart,
    required this.currencyFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double displayPrice =
        monAn.donGiaKhuyenMai != null && monAn.donGiaKhuyenMai! > 0
            ? monAn.donGiaKhuyenMai!
            : monAn.donGia ?? 0;
    double originalPrice = monAn.donGia ?? 0;

    return Card(
      elevation: 5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChiTietMonAn(maMon: monAn.maMon),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      monAn.hinh != null &&
                              File(
                                'assets/HinhAnh/MonAn/${monAn.hinh}',
                              ).existsSync()
                          ? Image.file(
                            File('assets/HinhAnh/MonAn/${monAn.hinh}'),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : Image.asset(
                            'assets/HinhAnh/default_food.jpg',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              BuildContext context,
                              Object exception,
                              StackTrace? stackTrace,
                            ) {
                              return const Center(
                                child: Text('Không có hình ảnh'),
                              );
                            },
                          ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                monAn.tenMon,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (monAn.donGiaKhuyenMai != null && monAn.donGiaKhuyenMai! > 0)
                Row(
                  children: [
                    Text(
                      currencyFormat.format(displayPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      currencyFormat.format(originalPrice),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  currencyFormat.format(displayPrice),
                  style: const TextStyle(fontSize: 14),
                ),
              Align(
                alignment: Alignment.bottomRight,
                child: InkWell(
                  onTap: () {
                    onAddToCart(monAn);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB2D9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
