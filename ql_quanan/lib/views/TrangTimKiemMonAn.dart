// views/TrangTimKiemMonAn.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/MonAnController.dart';
import '../controllers/CartController.dart';
import '../models/MonAn.dart';
import 'ChiTietMonAn.dart'; // Import trang chi tiết món ăn
import 'GioHang.dart'; // Import trang giỏ hàng

class TrangTimKiemMonAn extends StatefulWidget {
  final String searchQuery;

  const TrangTimKiemMonAn({Key? key, required this.searchQuery})
    : super(key: key);

  @override
  _TrangTimKiemMonAnState createState() => _TrangTimKiemMonAnState();
}

class _TrangTimKiemMonAnState extends State<TrangTimKiemMonAn> {
  final MonAnController _monAnController = MonAnController();
  List<MonAn> _searchResults = [];
  bool _isLoading = true;
  late TextEditingController _searchController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _performSearch(widget.searchQuery);
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      _searchResults = await _monAnController.searchMonAnByName(query);
    } catch (e) {
      print("Error during search: $e");
      _searchResults = []; // Clear results on error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm món ăn...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch(''); // Xóa tìm kiếm và hiển thị tất cả
                      },
                    )
                    : null,
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (query) {
            _performSearch(query);
          },
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
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB2D9)),
                ),
              )
              : _searchResults.isEmpty
              ? Center(
                child: Text(
                  'Không tìm thấy món ăn nào phù hợp với "${widget.searchQuery}".',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final monAn = _searchResults[index];
                  double displayPrice =
                      monAn.donGiaKhuyenMai != null &&
                              monAn.donGiaKhuyenMai! > 0
                          ? monAn.donGiaKhuyenMai!
                          : monAn.donGia ?? 0;
                  double originalPrice = monAn.donGia ?? 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChiTietMonAn(maMon: monAn.maMon),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: Image.asset(
                                'assets/HinhAnh/MonAn/${monAn.hinh}',
                                fit: BoxFit.cover,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  monAn.tenMon,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _currencyFormat.format(displayPrice),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (monAn.donGiaKhuyenMai != null &&
                                        monAn.donGiaKhuyenMai! > 0 &&
                                        monAn.donGiaKhuyenMai! < originalPrice)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Text(
                                          _currencyFormat.format(originalPrice),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (monAn.khuyenMai != null &&
                                    monAn.khuyenMai!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '🎁 ${monAn.khuyenMai}',
                                      style: TextStyle(
                                        color: Colors.pink[800],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
              ),
    );
  }
}
