# tool/

## Đổi thông tin người nộp bài (dùng cái này)

**Cách 1 – bấm đúp `doi_thong_tin.bat`** ở thư mục gốc (hoặc chạy `dart run tool/doi_thong_tin.dart`).
Tool hỏi lần lượt: MSSV, họ tên, SĐT, email, lớp, vai trò, file ảnh, tên/email git.
Enter = giữ giá trị trong `[ ]`. Nhập sai sẽ bị báo lỗi và hỏi lại.

**Cách 2 – điền file rồi chạy** (khi terminal không gõ được tiếng Việt):

```
copy tool\thong_tin_mau.json thong_tin.json      (rồi sửa thong_tin.json)
dart run tool/doi_thong_tin.dart --file thong_tin.json
```

Tool sẽ tự động:
- ghi `members.json` (sao lưu bản cũ ra `members.json.bak`), copy ảnh vào `assets/members/<mssv>.jpg|png`;
- đổi tên app `ho_va_ten`, `applicationId`/`namespace` `com.ho_va_ten.app`, chuyển `MainActivity.java`, sửa import `package:`;
- sinh `lib/config/current_member.dart` + `team_members.dart`, chạy `flutter clean` + `pub get`;
- quét toàn project báo chỗ còn sót thông tin người khác;
- chạy `flutter analyze` để chắc chắn không lỗi;
- (nếu chọn) đặt `git config user.name/email` **chỉ cho repo này**, không đụng cấu hình global.

Hoàn tác: `copy members.json.bak members.json` rồi `dart run tool/switch_member.dart <mssv cũ>`.

## Tool phụ

- `dart run tool/switch_member.dart <mssv>` — chỉ đổi sang 1 người đã có sẵn trong `members.json`.
- `tool/src/member_utils.dart` — hàm bỏ dấu, sinh tên app, kiểm tra dữ liệu (có unit test).
