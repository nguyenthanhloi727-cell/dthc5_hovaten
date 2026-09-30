# Hướng dẫn đổi thông tin người nộp bài (tool `doi_thong_tin`)

Mỗi người nộp bài riêng, nên app phải mang **tên, MSSV, SĐT, ảnh của người nộp**: tên app ngoài màn hình chính, applicationId, tab Cá nhân, số gọi điện. Tool `doi_thong_tin` làm hết việc này, **không cần sửa code bằng tay**.

Mục lục: [Chuẩn bị](#bước-1--chuẩn-bị) · [Chạy tool](#bước-2--chạy-tool) · [Tool làm gì](#bước-3--tool-tự-làm-những-gì) · [Kiểm tra](#bước-4--kiểm-tra-trên-điện-thoại) · [Không gõ được tiếng Việt](#không-gõ-được-tiếng-việt-trong-cửa-sổ-lệnh) · [Sửa danh sách nhóm](#sửa-thông-tin-thành-viên-khác-trong-nhóm) · [Hoàn tác](#hoàn-tác) · [Nộp bài](#bước-5--nộp-bài-bằng-github-của-mình)

---

## Bước 1 — Chuẩn bị

- Họ tên **có dấu**, MSSV, SĐT, email, lớp.
- 1 ảnh chân dung `.jpg` hoặc `.png`, dưới 5MB. Nên dùng ảnh vuông.
- Đã chạy `flutter pub get` ít nhất 1 lần.

## Bước 2 — Chạy tool

**Cách dễ nhất:** mở thư mục project, **bấm đúp `doi_thong_tin.bat`**.

Hoặc mở terminal tại thư mục project:

```bash
dart run tool/doi_thong_tin.dart
```

Tool hỏi lần lượt như sau. Giá trị trong `[ ]` là giá trị hiện tại, **bấm Enter để giữ**:

```
MSSV [2380601289]: 2280600123
  → MSSV mới, sẽ thêm vào danh sách nhóm.
Họ và tên (có dấu): Nguyễn Văn A
Số điện thoại: 0912 345 678
Email: nguyenvana@gmail.com
Lớp: 23DTHC5
Chưa có ảnh (tab Nhóm sẽ hiện chữ cái đầu).
Đường dẫn file ảnh .jpg/.png (Enter = bỏ qua): D:\anh\chan_dung.jpg
Đặt tên/email git cho repo này (commit sẽ mang tên bạn)? [Y/n]: y
  Tên git (tên tài khoản GitHub của bạn) [NguyenVanA]:
  Email git (email GitHub) [nguyenvana@gmail.com]:
Sửa danh sách thành viên khác trong nhóm? [y/N]:
```

- **Kéo thả file ảnh** vào cửa sổ lệnh là tự có đường dẫn.
- Nhập sai (tên có số, SĐT thiếu số, email sai…) thì tool báo `✗ …` và **hỏi lại đúng trường đó**.
- Nếu MSSV **đã có** trong nhóm, tool điền sẵn thông tin cũ để bạn chỉ cần sửa chỗ khác.

Cuối cùng tool hiện bảng **KIỂM TRA LẠI** (họ tên, MSSV, SĐT, tên app `nguyen_van_a`, applicationId `com.nguyen_van_a.app`…). Gõ `y` để áp dụng, gõ gì khác là huỷ và không đổi gì cả.

> **Ảnh nhập trong tool** là ảnh của tab **Nhóm**, đồng thời là ảnh mặc định của tab **Cá nhân**. Trong app, ở tab Cá nhân bạn vẫn có thể chạm vào ảnh để tự chụp hoặc chọn ảnh khác; ảnh đó chỉ lưu trong điện thoại.

## Bước 3 — Tool tự làm những gì

| Việc | Ở đâu |
|---|---|
| Sao lưu `members.json` → `members.json.bak` | thư mục gốc |
| Copy ảnh thành `assets/members/<mssv>.jpg` | `assets/members/` |
| Ghi thông tin vào `members.json`, đặt bạn làm người nộp | `members.json` |
| Đổi tên app theo họ tên không dấu (`nguyen_van_a`) | `pubspec.yaml`, `android:label`, mọi `import 'package:…'` |
| Đổi `applicationId` + `namespace` = `com.nguyen_van_a.app` | `android/app/build.gradle.kts` |
| Chuyển `MainActivity.java` sang thư mục package mới | `android/app/src/main/java/com/nguyen_van_a/app/` |
| Sinh thông tin cho tab Cá nhân / Nhóm | `lib/config/current_member.dart`, `team_members.dart` |
| `flutter clean` + `flutter pub get` | |
| Quét toàn project, báo nếu còn sót tên/MSSV/SĐT người khác | |
| Chạy `flutter analyze`, báo lỗi nếu có | |
| (nếu chọn) `git config user.name/email` **chỉ cho repo này**, không đụng cấu hình máy | `.git/config` |

Kết thúc thành công sẽ thấy:

```
✓ Không còn dấu vết thành viên khác trong project.
✓ flutter analyze: không có lỗi
App giờ mang tên "nguyen_van_a" (com.nguyen_van_a.app) của Nguyễn Văn A.
```

Tool ghi `members.json` theo mẫu dưới đây, **không cần sửa tay**:

```json
{
  "ho_ten": "Nguyễn Văn A",
  "mssv": "2280600123",
  "sdt": "0912345678",
  "email": "nguyenvana@gmail.com",
  "lop": "23DTHC5",
  "anh": "assets/members/2280600123.jpg"
}
```

## Bước 4 — Kiểm tra trên điện thoại

```bash
flutter run
```

- [ ] Tên app ngoài màn hình chính là `nguyen_van_a`.
- [ ] Tab **Cá nhân** đúng tên, MSSV, lớp.
- [ ] Bấm **Gọi điện** ra đúng số của bạn.
- [ ] Tab **Nhóm** có ảnh của bạn.

Vì applicationId đổi nên điện thoại coi đây là **app mới**. Máy Xiaomi/Oppo sẽ hỏi xác nhận cài, bấm **Cài đặt**. App cũ có thể gỡ đi.

## Không gõ được tiếng Việt trong cửa sổ lệnh?

Nếu họ tên hiện thành `Nguy?n` thì tool sẽ báo *"Tên bị lỗi font"*. Khi đó dùng file:

```bash
copy tool\thong_tin_mau.json thong_tin.json
```

Mở `thong_tin.json` bằng Notepad / VS Code, điền thông tin (lưu dạng **UTF-8**):

```json
{
  "nguoi_nop": {
    "ho_ten": "Nguyễn Văn A",
    "mssv": "2280600123",
    "sdt": "0912345678",
    "email": "nguyenvana@gmail.com",
    "lop": "23DTHC5",
    "anh_file": "D:/anh/chan_dung.jpg"
  },
  "git": { "name": "NguyenVanA", "email": "nguyenvana@gmail.com" },
  "xoa_file_ide": false
}
```

Rồi chạy:

```bash
dart run tool/doi_thong_tin.dart --file thong_tin.json
```

- Để `"git"` trống (`""`) nếu không muốn đổi tên git.
- Để `"anh_file": ""` nếu chưa có ảnh.

## Sửa thông tin thành viên khác trong nhóm

Ở câu hỏi *"Sửa danh sách thành viên khác trong nhóm?"*, trả lời `y`. Tool in danh sách đánh số, rồi nhận các lệnh:

| Lệnh | Tác dụng |
|---|---|
| `t` | Thêm thành viên mới (hỏi đủ các trường + ảnh) |
| `s 2` | Sửa thành viên số 2 (Enter để giữ trường cũ; có thể gắn ảnh) |
| `x 3` | Xoá thành viên số 3 (xoá luôn ảnh của người đó) |
| Enter | Xong |

Người nộp bài (đánh dấu `← người nộp`) được sửa ở các câu hỏi phía trên, không sửa ở đây.

## Hoàn tác

```bash
copy members.json.bak members.json
dart run tool/switch_member.dart <MSSV-người-cũ>
```

`switch_member.dart` cũng dùng được riêng để đổi nhanh sang một người **đã có sẵn** trong `members.json` mà không cần hỏi lại gì:

```bash
dart run tool/switch_member.dart 2380601699
```

## Bước 5 — Nộp bài bằng GitHub của mình ( à nếu không cần thì khỏi cũng được, chạy được trên máy của bây là ok )

Lịch sử git lưu **tên người commit** trong từng commit. Nếu chỉ sửa code rồi push, tab *Commits* trên GitHub vẫn hiện tên người khác. Vì vậy phải tạo lịch sử mới:

```bash
xcopy /E /I /H dthc5_hovaten D:\bai-nop-cua-toi
cd /d D:\bai-nop-cua-toi
rmdir /S /Q .git
git init
git config user.name "TenGitHubCuaBan"
git config user.email "email-github@cua-ban.com"
git add -A
git commit -m "feat: bai tap Flutter"
gh repo create <ten-repo> --private --source=. --push
```

- Kiểm tra `git config user.name` ra tên bạn **trước khi** commit.
- Để repo **private**, vì `members.json` chứa SĐT của cả nhóm.

---

Chi tiết kỹ thuật của các tool: [`tool/README.md`](tool/README.md) · Cách dùng app: [`docs/HUONG_DAN_SU_DUNG.md`](docs/HUONG_DAN_SU_DUNG.md)
