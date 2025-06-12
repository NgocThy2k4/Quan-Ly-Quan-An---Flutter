import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'InsertData.dart'; // Đường dẫn đúng
import '../models/MonAn.dart';
import '../models/LoaiMonAn.dart';
import '../models/NhanVien.dart'; // Import model mới
import '../models/KhachHang.dart'; // Import model mới
import '../models/User.dart'; // Import User model
import 'package:intl/intl.dart';

class QLQuanAnDatabaseHelper {
  static final QLQuanAnDatabaseHelper instance =
      QLQuanAnDatabaseHelper._privateConstructor();
  static Database? _database;

  QLQuanAnDatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(
      await getDatabasesPath(),
      'ql_quan_an_final.db', // Đổi tên DB để đảm bảo tạo mới
    );
    // Tăng version để cơ sở dữ liệu được tạo lại HOẶC xóa ứng dụng thủ công
    return await openDatabase(
      path,
      version: 110, // Tăng version lên 102
      onCreate: _createDb,
      onUpgrade: _onUpgrade, // Thêm onUpgrade để xử lý nâng cấp DB
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Logic nâng cấp DB nếu cần thiết
    // Ví dụ: thêm cột mới vào bảng hiện có
    if (oldVersion < 102) {
      try {
        await db.execute('ALTER TABLE hoa_don ADD COLUMN so_ban TEXT;');
        print('Column so_ban added to hoa_don table.');
      } catch (e) {
        print('Error adding so_ban column: $e');
      }
      try {
        await db.execute('ALTER TABLE hoa_don ADD COLUMN trang_thai TEXT;');
        print('Column trang_thai added to hoa_don table.');
      } catch (e) {
        print('Error adding trang_thai column: $e');
      }
    }
    // Thêm các cột ghi_chu nếu chưa có (cho hoa_don)
    if (oldVersion < 107) {
      try {
        await db.execute('ALTER TABLE hoa_don ADD COLUMN ghi_chu TEXT;');
        print('Column ghi_chu added to hoa_don table.');
      } catch (e) {
        print('Error adding ghi_chu column to hoa_don: $e');
      }
      // Đảm bảo cột ma_lien_quan và email đã có trong nguoi_dung
      // Các cột này đã có trong _createDb, chỉ kiểm tra khi nâng cấp từ phiên bản rất cũ
      try {
        await db.execute(
          'ALTER TABLE nguoi_dung ADD COLUMN ma_lien_quan NVARCHAR(15);',
        );
        print('Column ma_lien_quan added to nguoi_dung table.');
      } catch (e) {
        print('Error adding ma_lien_quan column to nguoi_dung: $e');
      }
      try {
        await db.execute(
          'ALTER TABLE nguoi_dung ADD COLUMN email NVARCHAR(100) UNIQUE;',
        );
        print('Column email added to nguoi_dung table.');
      } catch (e) {
        print('Error adding email column to nguoi_dung: $e');
      }
    }
  }

  Future<void> _createDb(Database db, int version) async {
    // Bảng vai_tro
    await db.execute('''
      CREATE TABLE vai_tro (
        ma_vai_tro NVARCHAR(15) PRIMARY KEY,
        ten_vai_tro NVARCHAR(100) NOT NULL
      )
    ''');

    // Bảng vai_tro
    await db.execute('''
      CREATE TABLE vai_tro (
        ma_vai_tro NVARCHAR(15) PRIMARY KEY,
        ten_vai_tro NVARCHAR(100) NOT NULL
      )
    ''');

    // Bảng nguoi_dung (KHÔNG CÓ CỘT hinh_anh ở đây)
    await db.execute('''
      CREATE TABLE nguoi_dung (
        ma_nguoi_dung NVARCHAR(15) NOT NULL PRIMARY KEY,
        ten_dang_nhap NVARCHAR(50) NOT NULL UNIQUE,
        mat_khau NVARCHAR(255) NOT NULL,
        email NVARCHAR(100) UNIQUE NOT NULL,
        ma_vai_tro NVARCHAR(15) NOT NULL,
        ma_lien_quan NVARCHAR(15),
        FOREIGN KEY (ma_vai_tro) REFERENCES vai_tro(ma_vai_tro)
      )
    ''');

    // Bảng nhan_vien
    await db.execute('''
      CREATE TABLE nhan_vien (
        ma_nhan_vien NVARCHAR(15) NOT NULL PRIMARY KEY,
        ten_nhan_vien NVARCHAR(100),
        chuc_vu NVARCHAR(100),
        dia_chi NVARCHAR(100),
        dien_thoai NVARCHAR(100),
        hinh_anh NVARCHAR(100),
        ghi_chu NVARCHAR(500)
      )
    ''');

    // Bảng khach_hang
    await db.execute('''
      CREATE TABLE khach_hang (
        ma_khach_hang NVARCHAR(15) NOT NULL PRIMARY KEY,
        ten_khach_hang NVARCHAR(100),
        dia_chi NVARCHAR(100),
        dien_thoai NVARCHAR(100),
        hinh_anh NVARCHAR(100),
        ghi_chu NVARCHAR(500)
      )
    ''');

    // Bảng loai_mon_an
    await db.execute('''
      CREATE TABLE loai_mon_an (
        ma_loai NVARCHAR(15) NOT NULL PRIMARY KEY,
        ten_loai TEXT,
        mo_ta TEXT,
        hinh TEXT
      )
    ''');

    // Bảng mon_an
    await db.execute('''
      CREATE TABLE mon_an (
        ma_mon NVARCHAR(15) NOT NULL PRIMARY KEY,
        ma_loai NVARCHAR(15) NOT NULL,
        ten_mon TEXT,
        noi_dung_tom_tat TEXT,
        noi_dung_chi_tiet TEXT,
        don_gia REAL,
        don_gia_khuyen_mai REAL,
        khuyen_mai TEXT,
        hinh TEXT,
        ngay_cap_nhat TEXT,
        dvt TEXT,
        trong_ngay INTEGER,
        FOREIGN KEY (ma_loai) REFERENCES loai_mon_an (ma_loai)
      )
    ''');

    // Bảng hoa_don (Đã thêm so_ban và trang_thai)
    await db.execute('''
      CREATE TABLE hoa_don (
        ma_hoa_don NVARCHAR(15) NOT NULL PRIMARY KEY,
        ma_khach_hang NVARCHAR(15) NOT NULL,
        ma_nhan_vien NVARCHAR(15) NOT NULL,
        ngay_dat TEXT,
        tong_tien REAL,
        tien_dat_coc REAL,
        con_lai REAL,
        hinh_thuc_thanh_toan TEXT,
        ghi_chu TEXT,
        so_ban TEXT,       -- Cột mới
        trang_thai TEXT,   -- Cột mới
        FOREIGN KEY (ma_khach_hang) REFERENCES khach_hang (ma_khach_hang),
        FOREIGN KEY (ma_nhan_vien) REFERENCES nhan_vien (ma_nhan_vien)
      )
    ''');

    // Bảng chi_tiet_hoa_don
    await db.execute('''
      CREATE TABLE chi_tiet_hoa_don (
        ma_hoa_don NVARCHAR(15) NOT NULL,
        ma_mon NVARCHAR(15) NOT NULL,
        so_luong INTEGER,
        don_gia REAL,
        mon_thuc_don INTEGER NOT NULL,
        PRIMARY KEY (ma_hoa_don, ma_mon, mon_thuc_don),
        FOREIGN KEY (ma_hoa_don) REFERENCES hoa_don (ma_hoa_don),
        FOREIGN KEY (ma_mon) REFERENCES mon_an (ma_mon)
      )
    ''');

    // Chèn dữ liệu ban đầu sau khi tạo bảng
    await insertInitialData(db);
  }

  // Phương thức chung để chèn dữ liệu vào bất kỳ bảng nào
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Phương thức mới: Lấy tất cả các hóa đơn
  Future<List<Map<String, dynamic>>> getAllHoaDon() async {
    final db = await database;
    return await db.query(
      'hoa_don',
      orderBy: 'ngay_dat DESC',
    ); // Sắp xếp theo ngày đặt giảm dần
  }

  // Phương thức mới: Lấy chi tiết hóa đơn theo mã hóa đơn
  Future<List<Map<String, dynamic>>> getChiTietHoaDonByMaHoaDon(
    String maHoaDon,
  ) async {
    final db = await database;
    return await db.query(
      'chi_tiet_hoa_don',
      where: 'ma_hoa_don = ?',
      whereArgs: [maHoaDon],
    );
  }

  Future<int> addUser(User user) async {
    final db = await database;
    return await db.insert(
      'nguoi_dung',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  // --- CÁC PHƯƠNG THỨC CRUD CHO nguoi_dung ---

  // Hàm insertUser: Chèn hoặc cập nhật người dùng (đã sửa để không loại bỏ mật khẩu)
  Future<int> insertUser(Map<String, dynamic> userMap) async {
    final db = await database;
    print('DBG: insertUser received map: $userMap'); // Log để kiểm tra input

    // Kiểm tra xem người dùng đã tồn tại bằng ma_nguoi_dung chưa
    List<Map<String, dynamic>> existingUser = await db.query(
      'nguoi_dung',
      where: 'ma_nguoi_dung = ?',
      whereArgs: [userMap['ma_nguoi_dung']],
    );

    if (existingUser.isNotEmpty) {
      // Nếu tồn tại, cập nhật bản ghi hiện có
      // Cập nhật toàn bộ userMap, bao gồm 'mat_khau'.
      print(
        'DBG: Updating existing user with ma_nguoi_dung: ${userMap['ma_nguoi_dung']}',
      );
      return await db.update(
        'nguoi_dung',
        userMap,
        where: 'ma_nguoi_dung = ?',
        whereArgs: [userMap['ma_nguoi_dung']],
      );
    } else {
      // Nếu chưa tồn tại, chèn bản ghi mới
      print(
        'DBG: Inserting new user with ma_nguoi_dung: ${userMap['ma_nguoi_dung']}',
      );
      return await db.insert('nguoi_dung', userMap);
    }
  }

  // Hàm updateUser: Dùng để cập nhật người dùng.
  // Hàm này sẽ cập nhật tất cả các trường trong `userMap` bao gồm cả `mat_khau` nếu có.
  Future<int> updateUser(Map<String, dynamic> userMap) async {
    final db = await database;
    String maNguoiDung = userMap['ma_nguoi_dung'];
    print(
      'DBG: updateUser received map: $userMap for ma_nguoi_dung: $maNguoiDung',
    );
    return await db.update(
      'nguoi_dung',
      userMap, // Cập nhật toàn bộ map được truyền vào
      where: 'ma_nguoi_dung = ?',
      whereArgs: [maNguoiDung],
    );
  }

  Future<int> updateUser2(User user) async {
    final db = await database;
    return await db.update(
      'nguoi_dung',
      user.toMap(),
      where: 'ma_nguoi_dung = ?',
      whereArgs: [user.maNguoiDung],
    );
  }

  // Hàm updateNguoiDung: Đã điều chỉnh để không loại bỏ 'mat_khau'
  // Tuy nhiên, các trường 'ma_nguoi_dung', 'ma_vai_tro', 'ma_lien_quan' vẫn bị loại bỏ.
  // Vui lòng kiểm tra lại nếu bạn có ý định cập nhật các trường này thông qua hàm này.
  Future<int> updateNguoiDung(Map<String, dynamic> userMap) async {
    final db = await database;
    String maNguoiDung = userMap['ma_nguoi_dung'];

    Map<String, dynamic> updateValues = Map.from(userMap);

    // Dòng này đã được loại bỏ để cho phép cập nhật mật khẩu nếu được cung cấp
    // updateValues.remove('mat_khau');

    // Những dòng này cũng cần xem xét lại mục đích:
    updateValues.remove('ma_nguoi_dung'); // Không nên cập nhật khóa chính
    updateValues.remove('ma_vai_tro');
    updateValues.remove('ma_lien_quan');

    print(
      'DBG: updateNguoiDung update values: $updateValues for ma_nguoi_dung: $maNguoiDung',
    );
    return await db.update(
      'nguoi_dung',
      updateValues,
      where: 'ma_nguoi_dung = ?',
      whereArgs: [maNguoiDung],
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('nguoi_dung');
  }

  Future<List<User>> getAllUsers2() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('nguoi_dung');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'nguoi_dung',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String tenDangNhap) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'nguoi_dung',
      where: 'ten_dang_nhap = ?',
      whereArgs: [tenDangNhap],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getUserByMaNguoiDung(String maNguoiDung) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'nguoi_dung',
      where: 'ma_nguoi_dung = ?',
      whereArgs: [maNguoiDung],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Phương thức để chèn NhanVien (đã có sẵn)
  Future<void> insertNhanVien(Map<String, dynamic> nhanVien) async {
    final db = await database;
    await db.insert(
      'nhan_vien',
      nhanVien,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Phương thức để chèn KhachHang (đã có sẵn)
  Future<void> insertKhachHang(Map<String, dynamic> khachHang) async {
    final db = await database;
    await db.insert(
      'khach_hang',
      khachHang,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Phương thức để lấy NhanVien theo mã
  Future<Map<String, dynamic>?> getNhanVienByMa(String maNhanVien) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'nhan_vien',
      where: 'ma_nhan_vien = ?',
      whereArgs: [maNhanVien],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Phương thức để lấy KhachHang theo mã
  Future<Map<String, dynamic>?> getKhachHangByMa(String maKhachHang) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'khach_hang',
      where: 'ma_khach_hang = ?',
      whereArgs: [maKhachHang],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> getNextMaNguoiDung(String prefix) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'nguoi_dung',
      columns: ['ma_nguoi_dung'],
      where: 'ma_nguoi_dung LIKE ?',
      whereArgs: ['${prefix}%'],
      orderBy: 'ma_nguoi_dung DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final lastMaNguoiDung = result.first['ma_nguoi_dung'] as String;
      final lastNumberString = lastMaNguoiDung.replaceAll(prefix, '');
      final lastNumber = int.tryParse(lastNumberString);
      if (lastNumber != null) {
        return lastNumber + 1;
      }
    }
    return 1; // Bắt đầu từ 1 nếu không có
  }

  // Phương thức CẬP NHẬT thông tin KhachHang
  Future<void> updateKhachHang(Map<String, dynamic> khachHang) async {
    final db = await database;
    await db.update(
      'khach_hang',
      khachHang,
      where: 'ma_khach_hang = ?',
      whereArgs: [khachHang['ma_khach_hang']],
    );
  }

  Future<int> addKhachHang(KhachHang khachHang) async {
    final db = await database;
    return await db.insert(
      'khach_hang',
      khachHang.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateKhachHang2(KhachHang khachHang) async {
    final db = await database;
    return await db.update(
      'khach_hang',
      khachHang.toMap(),
      where: 'ma_khach_hang = ?',
      whereArgs: [khachHang.maKhachHang],
    );
  }

  Future<int> deleteKhachHang(String maKhachHang) async {
    final db = await database;
    print('DBG: Deleting KhachHang: $maKhachHang');
    return await db.delete(
      'khach_hang',
      where: 'ma_khach_hang = ?',
      whereArgs: [maKhachHang],
    );
  }

  Future<List<KhachHang>> getAllKhachHang() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('khach_hang');
    return List.generate(maps.length, (i) {
      return KhachHang.fromMap(maps[i]);
    });
  }

  // Phương thức CẬP NHẬT thông tin NhanVien
  Future<void> updateNhanVien(Map<String, dynamic> nhanVien) async {
    final db = await database;
    await db.update(
      'nhan_vien',
      nhanVien,
      where: 'ma_nhan_vien = ?',
      whereArgs: [nhanVien['ma_nhan_vien']],
    );
  }

  Future<int> deleteNhanVien(String maNhanVien) async {
    final db = await database;
    print('DBG: Deleting NhanVien: $maNhanVien');
    return await db.delete(
      'nhan_vien',
      where: 'ma_nhan_vien = ?',
      whereArgs: [maNhanVien],
    );
  }

  Future<List<NhanVien>> getAllNhanVien() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('nhan_vien');
    return List.generate(maps.length, (i) {
      return NhanVien.fromMap(maps[i]);
    });
  }

  Future<List<MonAn>> getAllMonAn() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('mon_an');

    return List.generate(maps.length, (i) {
      return MonAn.fromMap(maps[i]);
    });
  }

  Future<int> addMonAn(MonAn monAn) async {
    final db = await database;
    return await db.insert(
      'mon_an',
      monAn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MonAn>> getMonAnByLoai(String maLoai) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mon_an',
      where: 'ma_loai = ?',
      whereArgs: [maLoai],
    );
    return List.generate(maps.length, (i) {
      return MonAn.fromMap(maps[i]);
    });
  }

  Future<MonAn?> getMonAn(String maMon) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mon_an',
      where: 'ma_mon = ?',
      whereArgs: [maMon],
    );

    if (maps.isNotEmpty) {
      return MonAn.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteMonAn(String maMon) async {
    final db = await database;
    print('DBG: Deleting MonAn: $maMon');
    return await db.delete('mon_an', where: 'ma_mon = ?', whereArgs: [maMon]);
  }

  // Phương thức cập nhật trạng thái hóa đơn
  Future<void> updateHoaDonStatus(
    String maHoaDon,
    String newStatus, {
    String? ghiChu,
  }) async {
    final db = await database;
    Map<String, dynamic> values = {'trang_thai': newStatus};

    if (ghiChu != null) {
      values['ghi_chu'] = ghiChu;
    }

    await db.update(
      'hoa_don',
      values, // Sử dụng Map đã bao gồm ghi_chu (nếu có)
      where: 'ma_hoa_don = ?',
      whereArgs: [maHoaDon],
    );
    print(
      'Updated HoaDon $maHoaDon status to: $newStatus' +
          (ghiChu != null ? ' with reason: $ghiChu' : ''),
    );
  }

  // Lấy hóa đơn kèm trạng thái và số bàn
  Future<List<Map<String, dynamic>>> getAllHoaDonWithDetails() async {
    final db = await database;
    // Lấy TẤT CẢ các cột từ bảng hoa_don
    // Đảm bảo rằng ma_khach_hang và ma_nhan_vien là các cột trong bảng hoa_don
    final List<Map<String, dynamic>> maps = await db.query('hoa_don');

    return List.generate(maps.length, (i) {
      return {
        'ma_hoa_don': maps[i]['ma_hoa_don'],
        'ma_khach_hang':
            maps[i]['ma_khach_hang'], // Đảm bảo cột này tồn tại và được lấy
        'ma_nhan_vien':
            maps[i]['ma_nhan_vien'], // Đảm bảo cột này tồn tại và được lấy
        'ngay_dat': maps[i]['ngay_dat'],
        'tong_tien': maps[i]['tong_tien'],
        'tien_dat_coc': maps[i]['tien_dat_coc'],
        'con_lai': maps[i]['con_lai'],
        'hinh_thuc_thanh_toan': maps[i]['hinh_thuc_thanh_toan'],
        'ghi_chu': maps[i]['ghi_chu'],
        'so_ban': maps[i]['so_ban'],
        'trang_thai': maps[i]['trang_thai'],
        // Thêm bất kỳ trường nào khác bạn cần ở đây
      };
    });
  }

  // --- CRUD cho LoaiMonAn ---
  Future<void> insertLoaiMonAn(LoaiMonAn loaiMonAn) async {
    final db = await database;
    await db.insert(
      'loai_mon_an',
      loaiMonAn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLoaiMonAn(LoaiMonAn loaiMonAn) async {
    final db = await database;
    await db.update(
      'loai_mon_an',
      loaiMonAn.toMap(),
      where: 'ma_loai = ?',
      whereArgs: [loaiMonAn.maLoai],
    );
  }

  Future<int> deleteLoaiMonAn(String maLoai) async {
    final db = await database;
    // Xóa các món ăn thuộc loại món ăn này trước (do FOREIGN KEY ON DELETE CASCADE)
    // Hoặc bạn có thể thiết lập cascade delete trong câu lệnh CREATE TABLE
    return await db.delete(
      'loai_mon_an',
      where: 'ma_loai = ?',
      whereArgs: [maLoai],
    );
  }

  Future<List<LoaiMonAn>> getAllLoaiMonAn() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('loai_mon_an');
    return List.generate(maps.length, (i) {
      return LoaiMonAn.fromMap(maps[i]);
    });
  }

  Future<LoaiMonAn?> getLoaiMonAnByMa(String maLoai) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loai_mon_an',
      where: 'ma_loai = ?',
      whereArgs: [maLoai],
    );
    if (maps.isNotEmpty) {
      return LoaiMonAn.fromMap(maps.first);
    }
    return null;
  }

  Future<List<LoaiMonAn>> searchLoaiMonAn(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loai_mon_an',
      where: 'ma_loai LIKE ? OR ten_loai LIKE ?',
      whereArgs: ['%${query}%', '%${query}%'],
    );
    return List.generate(maps.length, (i) {
      return LoaiMonAn.fromMap(maps[i]);
    });
  }

  Future<int> getNextMaLoai() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(ma_loai, 3) AS INTEGER)) as max_id FROM loai_mon_an",
    );
    int maxId = result.first['max_id'] ?? 0;
    return maxId + 1;
  }

  // --- CRUD cho MonAn ---
  Future<void> insertMonAn(MonAn monAn) async {
    final db = await database;
    await db.insert(
      'mon_an',
      monAn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMonAn(MonAn monAn) async {
    final db = await database;
    await db.update(
      'mon_an',
      monAn.toMap(),
      where: 'ma_mon = ?',
      whereArgs: [monAn.maMon],
    );
  }

  Future<List<MonAn>> searchMonAn(String query, {String? maLoai}) async {
    final db = await database;
    String whereClause = 'ten_mon LIKE ? OR ma_mon LIKE ?';
    List<dynamic> whereArgs = ['%${query}%', '%${query}%'];

    if (maLoai != null && maLoai.isNotEmpty) {
      whereClause += ' AND ma_loai = ?';
      whereArgs.add(maLoai);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'mon_an',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) {
      return MonAn.fromMap(maps[i]);
    });
  }

  Future<int> getNextMaMon() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(ma_mon, 3) AS INTEGER)) as max_id FROM mon_an",
    );
    int maxId = result.first['max_id'] ?? 0;
    return maxId + 1;
  }

  Future<List<KhachHang>> searchKhachHang(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'khach_hang',
      where: 'ma_khach_hang LIKE ? OR ten_khach_hang LIKE ?',
      whereArgs: ['%${query}%', '%${query}%'],
    );
    return List.generate(maps.length, (i) {
      return KhachHang.fromMap(maps[i]);
    });
  }

  Future<int> getNextMaKhachHang() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(ma_khach_hang, 3) AS INTEGER)) as max_id FROM khach_hang",
    );
    int maxId = result.first['max_id'] ?? 0;
    return maxId + 1;
  }

  // --- CRUD cho NhanVien ---
  Future<int> addNhanVien(NhanVien nhanVien) async {
    final db = await database;
    return await db.insert(
      'nhan_vien',
      nhanVien.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateNhanVien2(NhanVien nhanVien) async {
    final db = await database;
    return await db.update(
      'nhan_vien',
      nhanVien.toMap(),
      where: 'ma_nhan_vien = ?',
      whereArgs: [nhanVien.maNhanVien],
    );
  }

  Future<List<NhanVien>> searchNhanVien(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'nhan_vien',
      where: 'ma_nhan_vien LIKE ? OR ten_nhan_vien LIKE ?',
      whereArgs: ['%${query}%', '%${query}%'],
    );
    return List.generate(maps.length, (i) {
      return NhanVien.fromMap(maps[i]);
    });
  }

  Future<int> getNextMaNhanVien() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(ma_nhan_vien, 3) AS INTEGER)) as max_id FROM nhan_vien",
    );
    int maxId = result.first['max_id'] ?? 0;
    return maxId + 1;
  }

  Future<int> deleteUser(String maNguoiDung) async {
    final db = await database;
    return await db.delete(
      'nguoi_dung',
      where: 'ma_nguoi_dung = ?',
      whereArgs: [maNguoiDung],
    );
  }

  Future<List<User>> searchUsers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'nguoi_dung',
      where: 'ma_nguoi_dung LIKE ? OR ten_dang_nhap LIKE ? OR email LIKE ?',
      whereArgs: ['%${query}%', '%${query}%', '%${query}%'],
    );
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // --- Các phương thức liên quan đến Hóa Đơn (đã có) ---

  Future<int> getNextHoaDonId() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(ma_hoa_don, 3) AS INTEGER)) as max_id FROM hoa_don",
    );
    int maxId = result.first['max_id'] ?? 0;
    return maxId + 1;
  }

  Future<List<Map<String, dynamic>>> getHoaDonByMaKhachHang(
    String maKhachHang,
  ) async {
    final db = await database;
    return await db.query(
      'hoa_don',
      where: 'ma_khach_hang = ?',
      whereArgs: [maKhachHang],
      orderBy: 'ngay_dat DESC',
    );
  }

  Future<void> updateHoaDonStatus2(
    String maHoaDon,
    String newStatus, {
    String? ghiChu,
  }) async {
    final db = await database;
    Map<String, dynamic> values = {'trang_thai': newStatus};

    if (ghiChu != null) {
      values['ghi_chu'] = ghiChu;
    }

    await db.update(
      'hoa_don',
      values,
      where: 'ma_hoa_don = ?',
      whereArgs: [maHoaDon],
    );
    print(
      'Updated HoaDon $maHoaDon status to: $newStatus' +
          (ghiChu != null ? ' with reason: $ghiChu' : ''),
    );
  }

  Future<List<Map<String, dynamic>>> getAllHoaDonWithDetails2() async {
    final db = await database;
    // Sử dụng JOIN để lấy tên khách hàng và nhân viên
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        hd.ma_hoa_don,
        hd.ma_khach_hang,
        kh.ten_khach_hang, -- Lấy tên khách hàng
        hd.ma_nhan_vien,
        nv.ten_nhan_vien,   -- Lấy tên nhân viên
        hd.ngay_dat,
        hd.tong_tien,
        hd.tien_dat_coc,
        hd.con_lai,
        hd.hinh_thuc_thanh_toan,
        hd.ghi_chu,
        hd.so_ban,
        hd.trang_thai
      FROM hoa_don AS hd
      LEFT JOIN khach_hang AS kh ON hd.ma_khach_hang = kh.ma_khach_hang
      LEFT JOIN nhan_vien AS nv ON hd.ma_nhan_vien = nv.ma_nhan_vien
    ''');

    return List.generate(maps.length, (i) {
      return {
        'ma_hoa_don': maps[i]['ma_hoa_don'],
        'ma_khach_hang': maps[i]['ma_khach_hang'],
        'ten_khach_hang': maps[i]['ten_khach_hang'], // Thêm tên khách hàng
        'ma_nhan_vien': maps[i]['ma_nhan_vien'],
        'ten_nhan_vien': maps[i]['ten_nhan_vien'], // Thêm tên nhân viên
        'ngay_dat': maps[i]['ngay_dat'],
        'tong_tien': maps[i]['tong_tien'],
        'tien_dat_coc': maps[i]['tien_dat_coc'],
        'con_lai': maps[i]['con_lai'],
        'hinh_thuc_thanh_toan': maps[i]['hinh_thuc_thanh_toan'],
        'ghi_chu': maps[i]['ghi_chu'],
        'so_ban': maps[i]['so_ban'],
        'trang_thai': maps[i]['trang_thai'],
      };
    });
  }

  // --- Phương thức cho Chi Phí (Mới) ---
  Future<void> insertChiPhi(Map<String, dynamic> chiPhi) async {
    final db = await database;
    await db.insert(
      'chi_phi',
      chiPhi,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateChiPhi(Map<String, dynamic> chiPhi) async {
    final db = await database;
    await db.update(
      'chi_phi',
      chiPhi,
      where: 'ma_chi_phi = ?',
      whereArgs: [chiPhi['ma_chi_phi']],
    );
  }

  Future<int> deleteChiPhi(String maChiPhi) async {
    final db = await database;
    return await db.delete(
      'chi_phi',
      where: 'ma_chi_phi = ?',
      whereArgs: [maChiPhi],
    );
  }

  Future<List<Map<String, dynamic>>> getAllChiPhi() async {
    final db = await database;
    return await db.query('chi_phi', orderBy: 'ngay_chi DESC');
  }

  Future<int> getNextMaChiPhi() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR(ma_chi_phi, 3) AS INTEGER)) as max_id FROM chi_phi",
    );
    int maxId = result.first['max_id'] ?? 0;
    return maxId + 1;
  }

  // --- Phương thức tính toán Doanh Thu & Lợi Nhuận ---
  // Phương thức mới: Lấy tổng doanh thu theo khoảng thời gian
  Future<double> getTotalRevenue({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = 'SELECT SUM(tong_tien) as total FROM hoa_don';
    List<dynamic> args = [];
    String whereClause = '';

    if (startDate != null && endDate != null) {
      whereClause = ' WHERE ngay_dat BETWEEN ? AND ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
      args.add(DateFormat('yyyy-MM-dd').format(endDate));
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      query + whereClause,
      args,
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Phương thức mới: Lấy tổng chi phí theo khoảng thời gian (MỚI)
  Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = 'SELECT SUM(so_tien) as total FROM chi_phi';
    List<dynamic> args = [];
    String whereClause = '';

    if (startDate != null && endDate != null) {
      whereClause = ' WHERE ngay_chi BETWEEN ? AND ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
      args.add(DateFormat('yyyy-MM-dd').format(endDate));
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      query + whereClause,
      args,
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Phương thức mới: Lấy doanh thu theo ngày (MỚI)
  Future<List<Map<String, dynamic>>> getRevenueByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query =
        'SELECT ngay_dat, SUM(tong_tien) as daily_revenue FROM hoa_don';
    List<dynamic> args = [];
    String whereClause = '';

    if (startDate != null && endDate != null) {
      whereClause = ' WHERE ngay_dat BETWEEN ? AND ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
      args.add(DateFormat('yyyy-MM-dd').format(endDate));
    }

    query += whereClause + ' GROUP BY ngay_dat ORDER BY ngay_dat ASC';
    final List<Map<String, dynamic>> result = await db.rawQuery(query, args);
    return result;
  }

  // Phương thức mới: Lấy doanh thu theo món ăn (MỚI)
  Future<List<Map<String, dynamic>>> getRevenueByMonAn({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = '''
      SELECT ma.ten_mon, SUM(cthd.so_luong * cthd.don_gia) as item_revenue
      FROM chi_tiet_hoa_don cthd
      JOIN mon_an ma ON cthd.ma_mon = ma.ma_mon
      JOIN hoa_don hd ON cthd.ma_hoa_don = hd.ma_hoa_don
    ''';
    List<dynamic> args = [];
    String whereClause = '';

    if (startDate != null && endDate != null) {
      whereClause = ' WHERE hd.ngay_dat BETWEEN ? AND ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
      args.add(DateFormat('yyyy-MM-dd').format(endDate));
    }

    query += whereClause + ' GROUP BY ma.ten_mon ORDER BY item_revenue DESC';
    final List<Map<String, dynamic>> result = await db.rawQuery(query, args);
    return result;
  }

  // Phương thức mới: Lấy chi phí theo danh mục (MỚI)
  Future<List<Map<String, dynamic>>> getExpenseByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query =
        'SELECT loai_chi_phi, SUM(so_tien) as total_expense FROM chi_phi';
    List<dynamic> args = [];
    String whereClause = '';

    if (startDate != null && endDate != null) {
      whereClause = ' WHERE ngay_chi BETWEEN ? AND ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
      args.add(DateFormat('yyyy-MM-dd').format(endDate));
    }

    query += whereClause + ' GROUP BY loai_chi_phi ORDER BY total_expense DESC';
    final List<Map<String, dynamic>> result = await db.rawQuery(query, args);
    return result;
  }

  // Phương thức mới: Lấy chi tiêu của khách hàng (MỚI)
  Future<List<Map<String, dynamic>>> getCustomerSpending() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT
        kh.ma_khach_hang,
        kh.ten_khach_hang,
        SUM(hd.tong_tien) AS total_spending,
        COUNT(hd.ma_hoa_don) AS total_orders
      FROM hoa_don hd
      JOIN khach_hang kh ON hd.ma_khach_hang = kh.ma_khach_hang
      GROUP BY kh.ma_khach_hang, kh.ten_khach_hang
      ORDER BY total_spending DESC
    ''');
    return result;
  }

  Future<List<Map<String, dynamic>>> getRevenueByMenuItem({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = '''
      SELECT
        ma.ten_mon,
        SUM(cthd.so_luong * cthd.don_gia) AS item_revenue
      FROM chi_tiet_hoa_don AS cthd
      JOIN mon_an AS ma ON cthd.ma_mon = ma.ma_mon
      JOIN hoa_don AS hd ON cthd.ma_hoa_don = hd.ma_hoa_don
      WHERE hd.trang_thai = "Đã phục vụ"
    ''';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      query += ' AND hd.ngay_dat BETWEEN ? AND ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
      args.add(DateFormat('yyyy-MM-dd').format(endDate));
    }
    query += ' GROUP BY ma.ten_mon ORDER BY item_revenue DESC';

    final List<Map<String, dynamic>> result = await db.rawQuery(query, args);
    return result;
  }

  // --- Utility methods ---
  Future<int> getNextId(String table, String idColumn, String prefix) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT MAX(CAST(SUBSTR($idColumn, ${prefix.length + 1}) AS INTEGER)) as max_id FROM $table WHERE $idColumn LIKE '${prefix}%'",
    );
    int maxId = result.first['max_id'] ?? 0;
    return maxId + 1;
  }
  // --- CÁC PHƯƠNG THỨC TRUY VẤN THỐNG KÊ MỚI (MỚI) ---

  // Lấy tổng số lượng hóa đơn
  Future<int> getTotalOrderCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(ma_hoa_don) as total_orders FROM hoa_don',
    );
    return (result.first['total_orders'] as int?) ?? 0;
  }

  // Lấy số lượng khách hàng duy nhất
  Future<int> getUniqueCustomerCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(DISTINCT ma_khach_hang) as unique_customers FROM hoa_don',
    );
    return (result.first['unique_customers'] as int?) ?? 0;
  }

  // Lấy giá trị trung bình của một đơn hàng
  Future<double> getAverageOrderValue() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT AVG(tong_tien) as avg_value FROM hoa_don WHERE tong_tien IS NOT NULL',
    );
    return (result.first['avg_value'] as double?) ?? 0.0;
  }

  // Lấy số lượng đơn hàng theo phương thức thanh toán
  Future<List<Map<String, dynamic>>> getOrdersByPaymentMethod() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT hinh_thuc_thanh_toan, COUNT(ma_hoa_don) as count FROM hoa_don GROUP BY hinh_thuc_thanh_toan',
    );
    return result;
  }

  // Lấy số lượng đơn hàng theo trạng thái
  Future<List<Map<String, dynamic>>> getOrderStatusBreakdown() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT trang_thai, COUNT(ma_hoa_don) as count FROM hoa_don GROUP BY trang_thai',
    );
    return result;
  }
}
