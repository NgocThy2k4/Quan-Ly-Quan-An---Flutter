// views/GioHang.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/CartController.dart';
import '../controllers/AuthController.dart'; // Import AuthController
import '../models/CartItem.dart';
import 'ThanhToan.dart'; // Trang Thanh toán
import 'dart:developer'; // Import for log function

class GioHang extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
    );

    // Lắng nghe sự thay đổi của CartController
    return Consumer<CartController>(
      builder: (context, cart, child) {
        // Lấy thông tin người dùng hiện tại từ AuthController
        final authController = Provider.of<AuthController>(
          context,
          listen: false,
        );
        final currentUser = authController.currentUser;

        // Giỏ hàng chỉ hiển thị cho khách hàng hoặc hiển thị tất cả nếu là quản lý/nhân viên
        // Logic phức tạp hơn nếu bạn muốn giỏ hàng theo từng khách hàng cụ thể khi quản lý/nhân viên xem
        // Hiện tại, nếu là QL/NV thì sẽ thấy giỏ hàng của app chung, nếu là KH thì thấy giỏ hàng của session KH đó
        final bool isCustomer = currentUser?.maVaiTro == 'KH';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Giỏ Hàng (${cart.totalItems})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFFFB2D9),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (cart.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.white),
                  onPressed: () {
                    _showClearCartConfirmationDialog(context, cart);
                  },
                ),
            ],
          ),
          backgroundColor: const Color(0xFFFCE4EC),
          body:
          cart.items.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Giỏ hàng của bạn đang trống!',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          )
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/HinhAnh/MonAn/${item.monAn.hinh}',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                    Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Text('No Image'),
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.monAn.tenMon,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE91E63),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    currencyFormat.format(
                                      item.totalPrice,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          if (item.quantity > 1) {
                                            cart.decreaseQuantity(item);
                                          } else {
                                            _showRemoveItemConfirmationDialog(
                                              context,
                                              cart,
                                              item,
                                            );
                                          }
                                        },
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          cart.increaseQuantity(item);
                                        },
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          _showRemoveItemConfirmationDialog(
                                            context,
                                            cart,
                                            item,
                                          );
                                        },
                                      ),
                                    ],
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
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyFormat.format(cart.getTotalPrice()),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                        cart.items.isEmpty
                            ? null
                            : () {
                          _showTableNumberDialog(
                            context,
                            cart,
                          ); // Hiển thị dialog nhập số bàn
                        },
                        icon: const Icon(
                          Icons.payment,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Thanh Toán Ngay',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6790),
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm hiển thị dialog yêu cầu nhập số bàn
  void _showTableNumberDialog(BuildContext context, CartController cart) {
    final List<String> availableTables = [
      'Bàn 1',
      'Bàn 2',
      'Bàn 3',
      'Bàn 4',
      'Bàn 5',
      'Bàn 6',
      'Bàn 7',
      'Bàn 8',
      'Bàn 9',
      'Bàn 10',
      'Mang về',
    ];

    // Sử dụng StatefulBuilder để quản lý state cục bộ cho dialog
    String? _selectedTable;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder( // Thêm StatefulBuilder
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Chọn số bàn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63), // Màu hồng đậm
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0), // Padding cho content
              shape: RoundedRectangleBorder( // Bo tròn góc dialog
                borderRadius: BorderRadius.circular(20.0),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min, // Giữ min để Column co lại theo nội dung
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Chọn số bàn',
                      labelStyle: const TextStyle(color: Color(0xFFFF6790)), // Màu chữ label
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0), // Bo tròn góc input
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Color(0xFFFFB2D9)), // Màu viền khi không focus
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Color(0xFFFF6790), width: 2.0), // Màu viền khi focus
                      ),
                      filled: true,
                      fillColor: Colors.pink.shade50, // Màu nền nhẹ
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding nội dung
                    ),
                    value: _selectedTable,
                    hint: const Text('Chọn một bàn'),
                    items: availableTables.map((String table) {
                      return DropdownMenuItem<String>(
                        value: table,
                        child: Text(
                          table,
                          style: const TextStyle(color: Color(0xFFE91E63)), // Màu chữ của item
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTable = newValue;
                      });
                    },
                    dropdownColor: Colors.white, // Màu nền của dropdown menu
                    iconEnabledColor: const Color(0xFFFF6790), // Màu icon dropdown
                  ),
                  const SizedBox(height: 20), // Khoảng cách dưới dropdown
                ],
              ),
              actionsPadding: const EdgeInsets.all(16.0), // Padding cho phần actions
              actions: [
                TextButton(
                  onPressed: () {
                    if (Navigator.canPop(ctx)) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6790), // Màu chữ cho nút Hủy
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Color(0xFFFFB2D9)), // Viền cho nút Hủy
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedTable != null && _selectedTable!.isNotEmpty) {
                      if (Navigator.canPop(ctx)) {
                        Navigator.of(ctx).pop(); // Đóng dialog
                      }
                      log('DEBUG: Navigating to ThanhToan with soBan: $_selectedTable'); // Debug print
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ThanhToan(soBan: _selectedTable!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn số bàn.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6790), // Màu nền cho nút Tiếp tục
                    foregroundColor: Colors.white, // Màu chữ cho nút Tiếp tục
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRemoveItemConfirmationDialog(
      BuildContext context,
      CartController cart,
      CartItem item,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc muốn xóa "${item.monAn.tenMon}" khỏi giỏ hàng không?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () {
                cart.removeItem(item);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã xóa "${item.monAn.tenMon}" khỏi giỏ hàng.',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showClearCartConfirmationDialog(
      BuildContext context,
      CartController cart,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa tất cả'),
          content: const Text(
            'Bạn có chắc muốn xóa tất cả món ăn khỏi giỏ hàng không?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Xóa tất cả',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                cart.clearCart();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tất cả món ăn khỏi giỏ hàng.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
