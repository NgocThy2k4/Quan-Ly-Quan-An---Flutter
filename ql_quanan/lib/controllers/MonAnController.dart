// controllers/MonAnController.dart

import '../database/DatabaseHelper.dart';
import '../models/MonAn.dart';

class MonAnController {
  final QLQuanAnDatabaseHelper _dbHelper = QLQuanAnDatabaseHelper.instance;

  Future<List<MonAn>> fetchAllMonAn() async {
    return await _dbHelper.getAllMonAn();
  }

  Future<MonAn?> fetchMonAnDetail(String maMon) async {
    return await _dbHelper.getMonAn(maMon);
  }

  Future<List<MonAn>> fetchMonAnCungLoai(
    String maLoai,
    String currentMaMon,
  ) async {
    final List<MonAn> allMonAn = await _dbHelper.getAllMonAn();
    return allMonAn
        .where((mon) => mon.maLoai == maLoai && mon.maMon != currentMaMon)
        .toList();
  }
  // controllers/MonAnController.dart

  Future<List<MonAn>> fetchDiscountedFoods() async {
    return await _dbHelper.getDiscountedFoods();
  }

  Future<List<MonAn>> fetchPromotionFoods() async {
    return await _dbHelper.getPromotionFoods();
  }

  Future<List<MonAn>> fetchMostOrderedFoods() async {
    return await _dbHelper.getMostOrderedFoods();
  }

  Future<List<MonAn>> searchMonAnByName(String query) async {
    final List<MonAn> allMonAn = await _dbHelper.getAllMonAn();
    return allMonAn
        .where((mon) => mon.tenMon.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Phương thức mới: Tìm kiếm món ăn theo tên hoặc mã, có thể lọc theo loại
  Future<List<MonAn>> searchMonAn(String query, {String? maLoai}) async {
    return await _dbHelper.searchMonAn(query, maLoai: maLoai);
  }

  // Phương thức mới: Lấy món ăn theo mã loại
  Future<List<MonAn>> fetchMonAnByLoai(String maLoai) async {
    return await _dbHelper.getMonAnByLoai(maLoai);
  }

  // Thêm các phương thức khác liên quan đến quản lý món ăn (ví dụ: thêm, sửa, xóa)
}
