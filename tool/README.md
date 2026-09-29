# tool/

1. Sửa/thêm thông tin của bạn trong `members.json` (ảnh đặt ở `assets/members/<mssv>.jpg`).
2. Chạy `dart run tool/switch_member.dart <mssv>` — đổi tên app, applicationId, MainActivity, sinh `lib/config/*.dart`, chạy `flutter clean` + `pub get`, rồi báo chỗ còn sót thông tin người khác.
3. `dart run tool/list_packages.dart` cập nhật bảng package trong README.md.
