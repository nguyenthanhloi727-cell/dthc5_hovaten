/// Thông tin 1 thành viên. Dữ liệu thật nằm trong `members.json` ở root
/// và được sinh ra `current_member.dart` / `team_members.dart` bởi
/// `dart run tool/switch_member.dart <mssv>`.
class Member {
  final String hoTen;
  final String mssv;
  final String sdt;
  final String email;
  final String lop;
  final String vaiTro;

  /// Đường dẫn asset ảnh, null nếu file ảnh chưa có trong assets/members/.
  final String? anh;

  const Member({
    required this.hoTen,
    required this.mssv,
    required this.sdt,
    required this.email,
    required this.lop,
    required this.vaiTro,
    this.anh,
  });

  /// Chữ cái đầu của tên (từ cuối trong họ tên) để làm avatar dự phòng.
  String get initials {
    final parts = hoTen.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
