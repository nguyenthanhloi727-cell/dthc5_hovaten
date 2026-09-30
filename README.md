# Bài tập Flutter nhóm DTHC5

App Android làm bằng Flutter gồm: thông tin cá nhân (gọi điện, mở YouTube), đặt báo thức bằng giọng nói nhiều ngôn ngữ, dịch bằng Google ML Kit (nhập chữ, giọng nói, ảnh chụp, camera realtime) và tab giới thiệu nhóm. Toàn bộ thông tin cá nhân nằm trong **`members.json`**. Mỗi thành viên chạy **1 tool** là app đổi thành của mình (tên app, applicationId, tab Cá nhân, số gọi điện…), không phải sửa code.

📖 **[Hướng dẫn sử dụng chi tiết (có ảnh)](docs/HUONG_DAN_SU_DUNG.md)**: cách dùng từng tab, cách đổi sang thông tin của mình, kịch bản demo cho thầy.

## Checklist yêu cầu đề bài

| # | Yêu cầu | Tab | File chính | Cách demo cho thầy |
|---|---|---|---|---|
| 1 | Chuyển giao diện bằng BottomNavigationBar | (thanh dưới) | `lib/features/home/home_screen.dart` | Bấm qua 6 tab. Lướt tab Nhóm sang trang 2 → sang tab khác → quay lại vẫn ở trang 2 (IndexedStack giữ state). |
| 2 | Tab Cá nhân: gọi điện (url_launcher) + mở YouTube | Cá nhân | `lib/features/profile/profile_screen.dart` | Bấm **Gọi điện** → mở màn quay số với SĐT lấy từ `members.json`. Bấm **Mở YouTube** → mở app YouTube (không có app thì mở trình duyệt). |
| 3 | Báo thức bằng giọng nói, nhiều ngôn ngữ, đồng hồ thật | Báo thức | `lib/features/alarm/` (`parsers/` có parser riêng vi/en/fr) | Chọn Tiếng Việt → bấm mic → nói "7 giờ 30 sáng" → hiện **07:30** → **Xác nhận** → app Đồng hồ mở sẵn 07:30. Đổi English → nói "half past seven pm". |
| 4a | Dịch text | Dịch → Văn bản | `lib/features/translate/text_translate_tab.dart` | Gõ câu tiếng Anh → **Dịch**. Gõ tiếng Việt khi nguồn là Anh → app cảnh báo sai ngôn ngữ. |
| 4b | Dịch giọng nói | Dịch → Giọng nói | `lib/features/translate/voice_translate_tab.dart` | Bấm mic (có sóng âm theo giọng) → nói câu tiếng Anh → tự dịch khi ngừng nói. |
| 4c | Dịch ảnh chụp (image_picker + ML Kit) | Dịch → Ảnh | `lib/features/translate/image_translate_tab.dart` | **Chụp ảnh** trang sách tiếng Anh → thẻ *Kiểm định ảnh* (độ nét, sáng, độ tin cậy) → sửa chữ nếu cần → **Dịch**. |
| 5 | (Điểm cộng) Camera dịch realtime | Dịch → nút camera góc phải | `lib/features/translate/realtime_translate_screen.dart` | Giữ máy yên trước trang chữ in → bản dịch màu vàng hiện đè lên chữ, cập nhật ~1 lần/giây. |
| 6 | Tab nhóm: lướt xem từng thành viên (ảnh + info) | Nhóm | `lib/features/team/team_screen.dart` | Lướt ngang từng thành viên, có chấm chỉ trang. Thiếu ảnh thì hiện chữ cái đầu. |

Hai tab cũ của bài trước (**Nhiệt độ**, **Đơn vị**) vẫn giữ nguyên.

> Ghi chú về `mlkit_scanner` trong slide: package này trên pub.dev **chỉ quét mã vạch** (`RecognitionType.barcodeRecognition`), không đọc được chữ từ ảnh. Vì vậy nhóm dùng `google_mlkit_text_recognition`, cũng là ML Kit của Google.

## Môi trường

| | Phiên bản (lấy từ `flutter --version`) |
|---|---|
| Flutter | 3.47.5 (stable) |
| Dart | 3.13.4 |
| Android minSdk | 24 (Android 7.0) — theo mặc định `flutter.minSdkVersion` |
| Android compile/targetSdk | 36 |
| Java | 17 |

Cần máy Android thật (khuyên dùng) hoặc emulator có Google Play. Lần đầu mở tab Dịch **cần mạng** để tải model (~30MB/ngôn ngữ), sau đó dịch offline.

## Cài đặt & chạy

```bash
git clone https://github.com/nguyenthanhloi727-cell/dthc5_hovaten.git
cd dthc5_hovaten
flutter pub get
flutter run
```

Chạy test: `flutter test` · Kiểm tra code: `flutter analyze`

## ⭐ Hướng dẫn đổi thành viên (đọc kỹ)

Mỗi người nộp bài riêng nên phải đổi app thành tên mình. **Không sửa tay trong code.**

**a. Chuẩn bị thông tin:** họ tên có dấu, MSSV, SĐT, email, lớp, 1 ảnh chân dung (.jpg/.png, dưới 5MB).

**b. Chạy tool** — bấm đúp `doi_thong_tin.bat` ở thư mục gốc, hoặc:

```bash
dart run tool/doi_thong_tin.dart
```

Tool hỏi lần lượt từng trường (Enter = giữ giá trị cũ), trong đó có **đường dẫn file ảnh** (tool tự copy vào `assets/members/<mssv>.jpg`). Nhập sai định dạng tool sẽ báo và hỏi lại. Cuối cùng xác nhận `y` → tool đổi tên app, applicationId, MainActivity, sinh `lib/config/*.dart`, chạy `flutter clean`, quét chỗ còn sót thông tin người khác và chạy `flutter analyze`.

Nếu cửa sổ lệnh **không gõ được tiếng Việt**, điền file rồi chạy:

```bash
copy tool\thong_tin_mau.json thong_tin.json
dart run tool/doi_thong_tin.dart --file thong_tin.json
```

Mẫu 1 entry trong `members.json` (tool tự ghi, không cần sửa tay):

```json
{
  "ho_ten": "Nguyễn Văn A",
  "mssv": "2200000009",
  "sdt": "0900000009",
  "email": "nguyenvana@example.com",
  "lop": "DTHC5",
  "anh": "assets/members/2200000009.jpg"
}
```

**c. Kiểm tra:**

```bash
flutter run
```

- Tên app trên màn hình điện thoại là `ho_va_ten` của bạn (vd `nguyen_van_a`).
- Tab **Cá nhân** hiện đúng tên, MSSV; bấm **Gọi điện** ra đúng số của bạn.
- Tab **Nhóm** có ảnh của bạn.
- Điện thoại Xiaomi/Oppo… có thể hỏi xác nhận cài app mới (vì applicationId đổi) → bấm **Cài đặt**.

**d. NỘP BÀI RIÊNG bằng tài khoản GitHub của mình:**

```bash
xcopy /E /I /H <thu-muc-repo> D:\bai-nop-cua-toi
cd /d D:\bai-nop-cua-toi
rmdir /S /Q .git
git init
git add -A
git commit -m "feat: bai tap Flutter"
gh repo create <ten-repo-cua-ban> --private --source=. --push
```

**Vì sao phải xoá `.git`?** Lịch sử git lưu tên + email của **người commit ban đầu** trong từng commit. Nếu chỉ đổi code rồi push, thầy mở tab *Commits* trên GitHub vẫn thấy tên người khác. `git init` lại + commit bằng tài khoản của mình thì lịch sử chỉ có tên bạn. (Kiểm tra: `git config user.name` phải là tên bạn trước khi commit.)

## Package sử dụng

<!-- PACKAGES:START -->
<!-- Sinh tự động bởi `dart run tool/list_packages.dart`, đừng sửa tay. -->
| Package | Version (pubspec.lock) | Dùng cho | Loại |
|---|---|---|---|
| `flutter` | SDK | Framework | dependency |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | 1.0.9 | Icon kiểu iOS (mặc định của Flutter) | dependency |
| [`speech_to_text`](https://pub.dev/packages/speech_to_text) | 7.5.0 | 3. Báo thức bằng giọng nói · 4b. Dịch giọng nói | dependency |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | 6.3.2 | 2. Gọi điện (`tel:`), mở YouTube, gửi email | dependency |
| [`google_mlkit_translation`](https://pub.dev/packages/google_mlkit_translation) | 0.15.1 | 4. Dịch offline (tải model lần đầu) | dependency |
| [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition) | 0.17.1 | 4c. Lấy chữ từ ảnh · 5. Dịch realtime | dependency |
| [`image_picker`](https://pub.dev/packages/image_picker) | 1.2.3 | 4c. Chụp ảnh / chọn ảnh từ thư viện | dependency |
| [`camera`](https://pub.dev/packages/camera) | 0.12.1 | 5. Dịch realtime (image stream) | dependency |
| `flutter_test` | SDK | Unit test + widget test | dev_dependency |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) | 6.0.0 | Bộ luật `flutter analyze` | dev_dependency |
<!-- PACKAGES:END -->

Cập nhật bảng: `dart run tool/list_packages.dart`

## Quyền Android đã khai báo (`android/app/src/main/AndroidManifest.xml`)

| Quyền / khai báo | Lý do |
|---|---|
| `INTERNET` | Tải model dịch ML Kit lần đầu |
| `RECORD_AUDIO` | Nhận dạng giọng nói (Báo thức, Dịch giọng nói) |
| `CAMERA` | Chụp ảnh để dịch (image_picker) và dịch realtime (camera) |
| `com.android.alarm.permission.SET_ALARM` | Đặt báo thức vào app Đồng hồ qua intent `SET_ALARM` |
| `uses-feature camera/microphone required=false` | Máy không có camera/mic vẫn cài được |
| `<queries>` `tel`, `https`, `mailto`, YouTube, `RecognitionService`, `IMAGE_CAPTURE`, `SET_ALARM` | Android 11+ bắt buộc khai báo app nào mình cần tìm/mở, thiếu thì gọi điện/mic/đồng hồ báo lỗi |

## Xử lý lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| Tab Dịch báo "Chưa tải được model" | Bật mạng (Wi-Fi hoặc 4G) rồi bấm **Tải model**. Lần đầu mỗi ngôn ngữ ~30MB, chờ thanh tiến trình chạy xong. |
| Bản dịch sai lung tung | Kiểm tra ô **Từ** đúng ngôn ngữ của câu gốc (app có cảnh báo màu vàng). Tiếng Việt phải có dấu. Model offline kém Google Translate online là bình thường. |
| Dịch ảnh ra chữ vỡ | Xem thẻ *Kiểm định ảnh*: ảnh mờ → chạm màn hình camera để lấy nét, giữ yên; quá tối → bật đèn. Chữ in rõ tốt hơn chữ viết tay. |
| Lỡ bấm **Từ chối** quyền mic/camera | Bấm nút **Cài đặt** trên thông báo lỗi → Quyền → bật Micro/Camera. |
| Emulator không nghe được giọng nói | Emulator: *Extended controls → Microphone → Virtual microphone uses host audio input*; cần có app Google. Nên test trên máy thật. |
| Bấm Xác nhận báo thức báo "không có app Đồng hồ" | Emulator thiếu app Clock → cài app Clock của Google hoặc test trên máy thật. |
| Lỗi `package:<tên cũ>` / `Target of URI doesn't exist` sau khi đổi thành viên | Chạy lại `dart run tool/switch_member.dart <mssv>` (tự `flutter clean` + `pub get`). Đang mở Android Studio thì *File → Invalidate Caches*. |
| `INSTALL_FAILED_USER_RESTRICTED` khi cài | Xiaomi/Oppo: bấm **Cài đặt** trên điện thoại, hoặc bật *Cài đặt qua USB* trong Tuỳ chọn nhà phát triển. |
| Lỗi build Gradle | `flutter clean` → `flutter pub get` → `flutter run`. Vẫn lỗi: `flutter doctor -v`, đảm bảo Java 17 và Android SDK 36 đã cài. |

## Cấu trúc thư mục

```
lib/
├── main.dart                     # MaterialApp
├── config/
│   ├── member.dart               # model Member
│   ├── app_config.dart           # link YouTube...
│   ├── current_member.dart       # GENERATED – người nộp bài (tab Cá nhân)
│   └── team_members.dart         # GENERATED – cả nhóm (tab Nhóm)
├── features/
│   ├── home/home_screen.dart     # 1. BottomNavigationBar + IndexedStack
│   ├── profile/                  # 2. Cá nhân: gọi điện, YouTube
│   ├── alarm/                    # 3. Báo thức giọng nói + parsers vi/en/fr
│   ├── translate/                # 4a/4b/4c dịch, 5. realtime, kiểm định ảnh
│   ├── team/team_screen.dart     # 6. PageView thành viên
│   └── common/                   # mic, speech, avatar, kênh native, SnackBar
├── TemperatureConverterScreen.dart   # tab cũ
└── UnitConverterScreen.dart          # tab cũ
android/app/src/main/java/.../MainActivity.java   # intent SET_ALARM, mở Cài đặt
tool/
├── doi_thong_tin.dart            # ⭐ đổi người nộp bài (hỏi từng trường)
├── switch_member.dart            # đổi sang 1 MSSV có sẵn trong members.json
├── list_packages.dart            # sinh bảng package trong README
└── src/member_utils.dart         # bỏ dấu, tên app, kiểm tra dữ liệu
test/                             # parser giờ, xử lý văn bản, ảnh, tool, widget
members.json                      # nguồn dữ liệu thành viên DUY NHẤT
```
