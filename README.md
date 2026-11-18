# Restaurant POS

> Ứng dụng Flutter mobile-first hỗ trợ nhân viên nhà hàng quản lý bàn, gọi món, cập nhật order và thanh toán tại bàn.

Tài liệu này mô tả phiên bản hiện tại của dự án, giúp đội phát triển và đội viết báo cáo hiểu được công nghệ, kiến trúc, luồng nghiệp vụ, mô hình dữ liệu và cách chạy ứng dụng.

## 1. Tổng quan hệ thống

Restaurant POS là ứng dụng dành cho nhân viên phục vụ. Quy trình chính:

1. Nhân viên đăng nhập bằng mã nhân viên và mật khẩu.
2. Ứng dụng hiển thị sơ đồ bàn, khu vực và trạng thái bàn.
3. Nhân viên chọn bàn trống để tạo order mới hoặc chọn bàn đang phục vụ để xem order hiện tại.
4. Nhân viên chọn món, số lượng và ghi chú món.
5. Order được lưu lên Cloud Firestore; trạng thái bàn chuyển sang `occupied`.
6. Nhân viên có thể xem, tăng/giảm/xóa món trong order.
7. Khi khách thanh toán, nhân viên chọn tiền mặt hoặc chuyển khoản.
8. Hệ thống tạo hóa đơn, đánh dấu order là `paid` và giải phóng bàn về trạng thái `available`.

Ứng dụng có cơ chế fallback cho mục đích demo: tài khoản `NV001 / 123456` vẫn có thể đăng nhập khi Firebase chưa được cấu hình; danh sách bàn và thao tác order có thể chạy cục bộ trong một số trường hợp Firebase không khả dụng. Dữ liệu cục bộ này không thay thế cho dữ liệu lưu trữ lâu dài trên Firestore.

## 2. Công nghệ đang sử dụng

| Thành phần | Công nghệ/thư viện | Vai trò |
|---|---|---|
| Nền tảng giao diện | Flutter | Xây dựng ứng dụng đa nền tảng từ một codebase Dart |
| Ngôn ngữ | Dart `^3.13.5` | Ngôn ngữ lập trình chính |
| Quản lý trạng thái | `provider ^6.1.2` | Quản lý trạng thái đăng nhập, bàn và order |
| Backend | Firebase | Cung cấp xác thực và cơ sở dữ liệu đám mây |
| Xác thực | `firebase_auth ^5.3.1` | Đăng nhập bằng email/password sau khi tra cứu mã nhân viên |
| Cơ sở dữ liệu | `cloud_firestore ^5.4.4` | Lưu nhân viên, bàn, món ăn, order và hóa đơn |
| Khởi tạo Firebase | `firebase_core ^3.6.0` | Khởi tạo kết nối Firebase khi ứng dụng mở |
| Giao diện | Material 3, `google_fonts ^6.2.1` | Theme, component và font Poppins |
| Tiện ích | `flutter_svg`, `badges`, `shimmer` | SVG, badge và hiệu ứng loading |
| Định dạng | `intl ^0.19.0` | Hiển thị tiền Việt và định dạng dữ liệu |
| Kiểm thử | `flutter_test`, `flutter_lints` | Widget test và lint Dart |

Dependency được khai báo trong [pubspec.yaml](pubspec.yaml). Logo nằm trong [assets/](assets/).

## 3. Kiến trúc và cấu trúc thư mục

Dự án dùng kiến trúc phân lớp đơn giản, tách UI, state management, model và service:

```text
thao_cute/
├── lib/
│   ├── main.dart                         # Điểm vào, theme và Provider
│   ├── core/
│   │   ├── constants/app_colors.dart     # Bảng màu dùng chung
│   │   └── utils/currency_formatter.dart  # Định dạng tiền tệ vi_VN
│   ├── models/                            # Lớp dữ liệu và enum nghiệp vụ
│   │   ├── employee_model.dart
│   │   ├── food_model.dart
│   │   ├── invoice_model.dart
│   │   ├── order_model.dart
│   │   └── table_model.dart
│   ├── providers/                         # State và điều phối thao tác UI
│   │   ├── auth_provider.dart
│   │   ├── order_provider.dart
│   │   └── table_provider.dart
│   ├── screens/                           # Các màn hình chính
│   │   ├── login_screen.dart
│   │   ├── table_map_screen.dart
│   │   ├── menu_screen.dart
│   │   ├── order_detail_screen.dart
│   │   └── payment_screen.dart
│   └── services/                          # Truy cập Firebase và seed dữ liệu
│       ├── firebase_service.dart
│       └── seeder_service.dart
├── test/widget_test.dart                  # Widget test cơ bản
├── assets/                                # Logo và tài nguyên giao diện
├── android/, ios/, web/, windows/...      # Tích hợp theo nền tảng
├── firebase.json                          # Cấu hình Firebase CLI
├── firestore.rules                         # Quyền truy cập Firestore
└── pubspec.yaml                            # Metadata và dependency
```

### Vai trò của từng lớp

- **Models**: biểu diễn dữ liệu nghiệp vụ và chuyển đổi object Dart ↔ `Map` Firestore. Ví dụ `Order` chứa nhiều `OrderLine`, còn `RestaurantTable` chứa trạng thái bàn và `currentOrderId`.
- **Providers**: giữ state trong phiên chạy và gọi service. UI dùng `context.watch` để rebuild, `context.read` để thực hiện hành động.
- **Services**: lớp thực hiện truy cập Firebase. [FirebaseService](lib/services/firebase_service.dart) xử lý truy vấn, transaction và ghi dữ liệu; [SeederService](lib/services/seeder_service.dart) tạo dữ liệu mẫu.
- **Screens**: hiển thị giao diện và điều hướng theo luồng đăng nhập → sơ đồ bàn → menu/order → thanh toán.
- **Core**: cấu hình dùng chung, hiện gồm màu giao diện và formatter tiền tệ.

## 4. Điểm khởi động và khởi tạo ứng dụng

Trong [main.dart](lib/main.dart):

1. `main()` gọi `WidgetsFlutterBinding.ensureInitialized()`.
2. Ứng dụng thử gọi `Firebase.initializeApp()`. Nếu Firebase chưa cấu hình, lỗi được bỏ qua để chạy demo.
3. `RestaurantApp` tạo một `FirebaseService` dùng chung.
4. `MultiProvider` đăng ký `AuthProvider`, `TableProvider` và `OrderProvider`.
5. `TableProvider.load()` được gọi ngay khi khởi tạo để tải danh sách bàn.
6. `MaterialApp` cấu hình Material 3, màu chủ đạo cam, font Poppins và mở [LoginScreen](lib/screens/login_screen.dart).

## 5. Luồng vận hành

### 5.1. Đăng nhập

[LoginScreen](lib/screens/login_screen.dart) nhận mã nhân viên và mật khẩu, sau đó gọi `AuthProvider.login()`.

- Provider gọi `FirebaseService.findEmployee()` để tìm document trong collection `employees` theo `employeeCode`.
- Nếu tìm thấy, provider gọi Firebase Authentication bằng email của nhân viên và mật khẩu.
- Nếu Firebase lỗi/chưa cấu hình, cặp demo `NV001 / 123456` được chấp nhận ở local.
- Thành công chuyển tới [TableMapScreen](lib/screens/table_map_screen.dart).
- Nút đám mây gọi `SeederService.seed()` để tạo dữ liệu mẫu trên Firebase.

### 5.2. Sơ đồ bàn

[TableMapScreen](lib/screens/table_map_screen.dart) lấy danh sách từ `TableProvider` và hiển thị số bàn trống, bộ lọc khu vực, trạng thái màu và nút refresh.

Khi chọn bàn, ứng dụng kiểm tra `currentOrderId`: bàn trống mở [MenuScreen](lib/screens/menu_screen.dart), bàn đang phục vụ tải order và mở [OrderDetailScreen](lib/screens/order_detail_screen.dart).

### 5.3. Tạo và cập nhật order

Tại [MenuScreen](lib/screens/menu_screen.dart), nhân viên có thể lọc món, thêm món, tăng/giảm số lượng và nhập ghi chú.

Khi tạo order mới, `FirebaseService.createOrderForTable()` dùng Firestore transaction để đọc lại trạng thái bàn, từ chối nếu bàn vừa bị nhân viên khác nhận, tạo document trong `orders`, rồi cập nhật bàn thành `occupied` và gán `currentOrderId`.

Khi thêm món vào order, `appendLinesToOrder()` đọc order mới nhất trong transaction, cộng số lượng món trùng `foodId` hoặc thêm dòng mới.

### 5.4. Thanh toán

[PaymentScreen](lib/screens/payment_screen.dart) cho phép chọn `cash` hoặc `bankTransfer`.

`FirebaseService.saveInvoiceAndReleaseTable()` dùng transaction để kiểm tra order chưa thanh toán và bàn vẫn liên kết với order, sau đó tạo invoice, cập nhật order thành `paid`, cập nhật bàn thành `available` và xóa `currentOrderId`. Sau đó ứng dụng quay về sơ đồ bàn.

## 6. Mô hình dữ liệu Firestore

### `employees`

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `employeeCode` | string | Mã đăng nhập, ví dụ `NV001` |
| `email` | string | Email liên kết Firebase Auth |
| `name` | string | Tên hiển thị |
| `role` | string | Vai trò, mặc định `staff` |
| `active` | boolean | Nhân viên còn hoạt động |
| `authUid` | string | UID Firebase Auth, thêm khi seed |

### `tables`

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `name` | string | Tên/số bàn |
| `area` | string | Khu vực |
| `status` | string | `available` hoặc `occupied` |
| `currentOrderId` | string/null | Order đang gắn với bàn |

### `foods`

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `name` | string | Tên món |
| `category` | string | Danh mục |
| `price` | number | Đơn giá, lưu bằng đồng |
| `description` | string | Mô tả món |
| `imageUrl` | string | URL hình ảnh, có thể trống |
| `available` | boolean | Có hiển thị để gọi món hay không |

### `orders`

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `tableId` | string | Bàn của order |
| `lines` | array | Các dòng món: `foodId`, `name`, `unitPrice`, `quantity`, `note` |
| `status` | string | `serving`, `paid` hoặc `cancelled` |
| `employeeId` | string | Nhân viên tạo order |
| `createdAt` | timestamp | Thời điểm tạo |
| `updatedAt` | timestamp | Thời điểm cập nhật |

### `invoices`

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `orderId` | string | Order đã thanh toán |
| `tableId` | string | Bàn của khách |
| `total` | number | Tổng tiền |
| `paymentMethod` | string | `cash` hoặc `bankTransfer` |
| `employeeId` | string | Nhân viên thanh toán |
| `paidAt` | timestamp | Thời điểm thanh toán |

## 7. Cấu hình Firebase

### Chạy demo không cần Firebase

Có thể chạy bằng:

```text
Mã nhân viên: NV001
Mật khẩu:    123456
```

Đăng nhập demo không có nghĩa dữ liệu đã được lưu trên cloud. Muốn đồng bộ nhiều thiết bị, cần cấu hình Firebase.

### Cấu hình đầy đủ

1. Tạo Firebase project.
2. Bật **Authentication → Sign-in method → Email/Password**.
3. Tạo Firestore Database.
4. Thêm `google-services.json` vào `android/app/` nếu chạy Android.
5. Thêm `GoogleService-Info.plist` vào target Runner nếu chạy iOS.
6. Kiểm tra [firebase.json](firebase.json) trỏ tới [firestore.rules](firestore.rules).
7. Deploy rules nếu cần:

```powershell
firebase login
firebase use <firebase-project-id>
firebase deploy --only firestore:rules
```

8. Chạy app và bấm nút seed trên màn hình đăng nhập. Seeder tạo 8 bàn, 6 món, một nhân viên và tài khoản Auth demo.

> Rules hiện cho phép đọc `employees` công khai để tra cứu mã trước khi đăng nhập; các collection còn lại yêu cầu đã đăng nhập. Khi triển khai thật, cần đánh giá lại rules và không lưu mật khẩu trong Firestore.

## 8. Cài đặt và chạy code

### Yêu cầu

- Flutter SDK tương thích Dart `^3.13.5`.
- Android Studio/Android SDK nếu chạy Android.
- Xcode nếu chạy iOS trên macOS.
- Firebase CLI khi cấu hình hoặc deploy rules.

Kiểm tra môi trường:

```powershell
flutter doctor
flutter --version
```

### Cài dependency và chạy

Mở terminal tại thư mục `thao_cute`:

```powershell
flutter pub get
flutter devices
flutter run
```

Chạy trên thiết bị cụ thể:

```powershell
flutter run -d <device-id>
flutter run -d chrome
```

### Kiểm tra và test

```powershell
dart format lib test
flutter analyze
flutter test
```

Widget test nằm trong [test/widget_test.dart](test/widget_test.dart), kiểm tra app render được màn hình đăng nhập.

### Build Android

```powershell
flutter build apk --debug
flutter build apk --release
```

APK nằm tại:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

## 9. File tham khảo khi viết báo cáo

| Nội dung | File |
|---|---|
| Khởi động app, theme, Provider | [lib/main.dart](lib/main.dart) |
| Đăng nhập và seed | [lib/screens/login_screen.dart](lib/screens/login_screen.dart), [lib/providers/auth_provider.dart](lib/providers/auth_provider.dart), [lib/services/seeder_service.dart](lib/services/seeder_service.dart) |
| Sơ đồ bàn | [lib/screens/table_map_screen.dart](lib/screens/table_map_screen.dart), [lib/providers/table_provider.dart](lib/providers/table_provider.dart) |
| Chọn món và tạo order | [lib/screens/menu_screen.dart](lib/screens/menu_screen.dart), [lib/providers/order_provider.dart](lib/providers/order_provider.dart) |
| Chỉnh sửa order | [lib/screens/order_detail_screen.dart](lib/screens/order_detail_screen.dart) |
| Thanh toán/hóa đơn | [lib/screens/payment_screen.dart](lib/screens/payment_screen.dart), [lib/models/invoice_model.dart](lib/models/invoice_model.dart) |
| Firebase/Auth/transaction | [lib/services/firebase_service.dart](lib/services/firebase_service.dart) |
| Cấu trúc dữ liệu | [lib/models/](lib/models/) |
| Quyền database | [firestore.rules](firestore.rules) |

## 10. Hạn chế và hướng phát triển

- Chưa có màn hình quản trị CRUD nhân viên, bàn, món và báo cáo doanh thu.
- Chưa có phân quyền giao diện theo `role`; role mới được lưu trong model.
- Chưa có khôi phục session tự động sau khi đóng/mở app.
- Fallback local phù hợp cho demo, chưa phải offline-first hoàn chỉnh.
- Nên bổ sung test cho provider, transaction và các trường hợp thanh toán lỗi.
- Nên siết Firestore Security Rules trước khi đưa lên production.

