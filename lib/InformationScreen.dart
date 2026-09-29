// tạo giao diện thông tin cá nhân + đăng xuất (phiên bản thuần)
import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
const InformationScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.blueGrey[50],
appBar: AppBar(
title: const Text('Thông Tin Cá Nhân'),
backgroundColor: Colors.teal,
elevation: 2,
// Thêm một chút bóng đổ cho AppBar
shadowColor: Colors.black.withOpacity(0.5),
),
body: SafeArea(
child: Center(
child: SingleChildScrollView( // Cho phép cuộn nếu nội dung quá dài
padding: const EdgeInsets.symmetric(vertical: 20.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: <Widget>[
// Hình đại diện
const CircleAvatar(
radius: 70.0,
backgroundImage: NetworkImage(
'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS8H_p02k_i3Fk2i52o-ADBb2P5-L390hxX-A&s'), // Bạn có thể thay đổi URL ảnh
backgroundColor: Colors.white,
),
const SizedBox(height: 15.0),

// Họ tên
const Text(
'Nguyễn Mạnh Hùng',
style: TextStyle(
fontSize: 28.0,
color: Colors.black87,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5.0),

// Khoa
Text(
'Khoa: Công Nghệ Thông Tin',
style: TextStyle(
color: Colors.teal.shade700,
fontSize: 18.0,
fontWeight: FontWeight.w500,
),
),
SizedBox(
height: 20.0,
width: 250.0,
child: Divider(
color: Colors.teal.shade200, // Làm cho đường kẻ rõ hơn một chút
thickness: 1,
),
),

// Card thông tin liên lạc
InfoCard(
text: '0356 781 111',
icon: Icons.phone,
onPressed: () {
// Chức năng gọi điện bị vô hiệu hóa vì không dùng thư viện ngoài
print('Chức năng gọi điện cần thư viện url_launcher.');
},
),
InfoCard(
text: 'nm.hung@hutech.edu.vn',
icon: Icons.email,
onPressed: () {
// Chức năng gửi email bị vô hiệu hóa vì không dùng thư viện ngoài
  print('Chức năng gửi email cần thư viện url_launcher.');
},
),
  const SizedBox(height: 20.0),

  // Nút đăng xuất
  ElevatedButton.icon(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất')),
      );
    },
    icon: const Icon(Icons.logout),
    label: const Text('Đăng xuất'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      foregroundColor: Colors.white,
    ),
  ),
],
),
),
),
),
);
}
}

// Card hiển thị 1 dòng thông tin liên lạc
class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const InfoCard({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 25.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(
          text,
          style: TextStyle(color: Colors.teal.shade900, fontSize: 18.0),
        ),
        onTap: onPressed,
      ),
    );
  }
}