# QuanOi POS UI Build Rules

File này chỉ dùng khi agent đang xây hoặc chỉnh UI Flutter.

Nếu task yêu cầu mock UI, prototype, static screen hoặc dựng UI trước khi nối API, bắt buộc đọc thêm [docs/mock-ui-first-rules.md](mock-ui-first-rules.md).

## Single Source of Truth
Luôn đọc và dùng các file sau trước khi viết UI:
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/index.dart`
- `lib/core/constants/app_constants.dart`

### Bắt buộc
- Dùng `AppTheme.light` hoặc `Theme.of(context)` thay vì `ThemeData.fromSeed` hay hardcode theme riêng.
- Dùng màu từ `AppColors`, typography từ `AppTextStyles`, spacing từ `AppConstants`.
- Dùng theme component sẵn có của Material 3 khi có thể: `AppBarTheme`, `CardTheme`, `ElevatedButtonTheme`, `OutlinedButtonTheme`, `TextButtonTheme`, `InputDecorationTheme`, `SnackBarTheme`.
- Nếu một giá trị thiết kế chưa tồn tại trong token, ưu tiên mở rộng token ở `lib/core/theme` thay vì hardcode trong từng widget.

### Không được
- Không hardcode màu, font size, radius, spacing, animation duration, shadow, border trong page-level widget nếu giá trị đó có thể đưa vào theme/token.
- Không dùng font hoặc bảng màu khác với config dự án.
- Không tự tạo lại `Scaffold`, `AppBar`, `Card`, `TextField`, `Button`, `SnackBar` theo kiểu riêng biệt ở từng page nếu cùng pattern có thể tái sử dụng.

## Reuse Before Rebuild
Nếu một UI pattern xuất hiện từ 2 lần trở lên, hãy cân nhắc tách widget dùng chung trước khi tiếp tục copy/paste.

### Decision checklist khi tạo/sửa widget
1. Tìm widget/pattern tương tự trong feature đang làm trước.
2. Nếu widget chỉ giúp giảm độ dài một page, tách private widget trong cùng file.
3. Nếu widget được dùng lại trong cùng feature/sub-feature, đặt trong `presentation/widgets`.
4. Nếu widget được dùng lại giữa nhiều feature, mới đưa vào shared/core phù hợp.
5. Nếu chưa rõ nên đặt widget ở đâu, hỏi lại trước khi tạo shared/common widget.

Nguyên tắc:
- Không tạo `common`/`shared` widget chỉ vì dự đoán sau này có thể cần.
- Widget feature-level không được gọi network trực tiếp; chỉ nhận data, state và callback từ page/provider.
- Widget shared/core phải không phụ thuộc business context của một feature cụ thể.

### Widget nên tách ra tái sử dụng
- `AppScaffold` hoặc `PageScaffold`: khung trang chuẩn có background, padding, app bar, action area, and content slot.
- `PageHeader` hoặc `SectionHeader`: tiêu đề trang, subtitle, action nút bên phải.
- `SectionCard`: khối nội dung dùng chung cho form, summary, list, stats.
- `AppTextField`, `AppDropdown`, `AppSearchField`: field chuẩn hoá theo `InputDecorationTheme`.
- `PrimaryButton`, `SecondaryButton`, `TextButtonLink`: wrapper theo button theme và trạng thái loading/disabled.
- `StatusChip`, `TagChip`, `Badge`: nhãn trạng thái, nhãn số lượng, nhãn semantic.
- `EmptyState`, `ErrorState`, `LoadingState`: trạng thái không có dữ liệu, lỗi, skeleton/loading.
- `ConfirmDialog`, `InfoDialog`, `BottomSheetPanel`: popup và modal dùng chung style.
- `ListTileRow`, `KeyValueRow`, `SummaryRow`: dòng thông tin lặp lại trong danh sách, chi tiết đơn hàng, hóa đơn, tồn kho.
- `AvatarLabel`, `UserAvatar`, `ProductThumb`: avatar và thumbnail có kích thước chuẩn.
- `MetricCard`, `StatTile`: thẻ thống kê dashboard.
- `DividerSection`, `DashedDivider`: đường phân cách theo style dự án.

### Dấu hiệu nên tách widget
- Cùng một nhóm `Padding`, `Container`, `Card`, `Column`, `Row` xuất hiện lặp lại với thay đổi rất nhỏ.
- Cùng một cấu trúc `label + value + helper text` lặp ở nhiều màn hình form.
- Cùng một kiểu header, card, button group, empty state, row item được copy qua nhiều page.
- Cùng một bộ `BoxDecoration`, `TextStyle`, `EdgeInsets`, `BorderRadius` được dựng lại thủ công.

## UI Build Rules for Flutter
### Mock UI First
- Mock UI vẫn phải dùng theme/token/widget pattern hiện có như UI thật.
- Không rải mock data trong nhiều widget/page; mock data phải có ranh giới rõ theo [docs/mock-ui-first-rules.md](mock-ui-first-rules.md).
- Không tạo fake network/repository/use case production chỉ để render UI mock.
- Nếu mock UI thuộc store workspace/module, vẫn phải áp dụng PBAC và trạng thái permission phù hợp.

### Layout
- Ưu tiên layout rõ ràng, ít nesting không cần thiết.
- Dùng `const` khi có thể.
- Dùng `Expanded`, `Flexible`, `Wrap`, `SingleChildScrollView` đúng ngữ cảnh để tránh overflow.
- Giữ khoảng cách nhất quán theo `AppConstants.spacingXs/Sm/Md/Lg/Xl/Xxl`.
- Với trang dài, tách thành section rõ ràng thay vì nhồi hết vào một `Column` lớn.

### Typography
- Dùng `AppTextStyles` cho heading, body, label, caption.
- Không tự chọn font size/weight/line-height mới nếu đã có style tương ứng trong theme.
- Nếu cần biến thể mới, ưu tiên thêm biến thể vào `AppTextStyles`.

### Color and Semantics
- Dùng semantic colors đúng mục đích: success, warning, info, error.
- Không dùng màu chỉ vì trông đẹp nếu nó phá vỡ ý nghĩa trạng thái.
- Background, surface, border, muted, accent phải đi theo palette hiện có.

### Buttons and Inputs
- Button phải theo theme chuẩn, nhất là radius, height, padding, text style.
- Field nhập liệu phải đi theo `InputDecorationTheme`, không tự khai báo border/padding mỗi chỗ.
- Với hành động chính/phụ, giữ thứ bậc rõ ràng: primary, secondary, destructive.

### State and Feedback
- Mỗi màn hình nên có trạng thái `loading`, `empty`, `error` rõ ràng.
- Dùng snack bar theo `SnackBarTheme` và không tự dựng kiểu toast riêng nếu không cần.
- Dialog và bottom sheet phải nhất quán về padding, radius, title/action layout.

### Responsiveness
- Thiết kế phải hoạt động trên desktop và mobile.
- Khi màn hình hẹp, chuyển từ grid sang list hoặc wrap thay vì ép giữ layout desktop.
- Tránh kích thước cố định quá nhiều, ưu tiên cấu trúc co giãn.

### Performance and Maintainability
- Đừng đặt logic dựng UI phức tạp trong `build()` của page nếu có thể tách ra widget nhỏ hơn.
- Nếu widget chỉ dùng chung trong cùng một page nhưng có pattern lặp, vẫn nên tách thành private widget nhỏ.
- Nếu widget dùng lại trong cùng feature, đặt vào `feature/.../presentation/widgets`.
- Nếu widget dùng lại giữa nhiều feature, chỉ khi đó mới đặt vào shared/core phù hợp.
- Trước khi tách widget shared/core, kiểm tra widget không phụ thuộc permission, route, provider hoặc business context của một feature cụ thể.

## Workspace/Store Switching UI Guidelines
Áp dụng cho các màn: account hub, store picker, role home, switch store.

### Bắt buộc
- Màn `store picker` phải có đủ 3 state: `loading`, `empty`, `error`.
- App shell của StoreUser phải hiển thị rõ:
  - `activeStore`
  - `activeRole`
- Hành động đổi store phải có vị trí ổn định và nhất quán giữa các role-home.
- Pattern chọn store nên thống nhất theo một kiểu trong app: `modal` hoặc `bottom sheet` hoặc `full-page list`.
- UI store workspace/module phải đi qua PBAC trong [docs/store-permission-access.md](store-permission-access.md).
- Menu, tab, button và action liên quan store permission phải đọc permission qua `StoreAccessState.can(...)` hoặc `StoreAccessContext.can(...)`.

### Không được
- Không render module làm việc khi chưa resolve xong `activeStore`.
- Không nhúng business logic phân quyền role trực tiếp trong widget thuần.
- Không tự parse permission response hoặc hardcode permission string trong widget.
- Không trigger API/action khi user thiếu permission.
- Không để mỗi role-home tự định nghĩa layout chuyển store khác nhau nếu có thể tái sử dụng.

## Checklist cho Role-based Home
- UI chỉ đọc context từ provider/notifier đã resolve (`activeStore`, `activeRole`).
- Route entry phải qua guard/context check trước khi vào màn.
- Header hoặc vùng context phải luôn hiển thị store/role hiện hành.
- Tương tác đổi store phải trigger refresh context và feedback trạng thái rõ ràng.

## What to do before generating a new screen
1. Xác định token có sẵn trong theme thay vì viết style mới.
2. Tìm xem pattern tương tự đã tồn tại chưa.
3. Nếu là mock UI/prototype, đọc [docs/mock-ui-first-rules.md](mock-ui-first-rules.md) và xác định nơi đặt mock data trước khi viết layout.
4. Nếu có pattern lặp, tái sử dụng widget hoặc tách widget mới trước khi render màn hình.
5. Kiểm tra trạng thái `empty/loading/error` và responsive breakpoints.
6. Nếu là store UI, xác định permission/menu/action visibility theo PBAC trước khi render.
7. Chỉ viết layout mới khi thật sự chưa có widget phù hợp.

## Recommended Practice For This Project
- Ưu tiên chuẩn hoá theme trước, rồi mới mở rộng shared widgets.
- Giữ design system nhỏ, nhất quán, và POS-friendly.
- Mọi UI mới nên nhìn như một phần của cùng một sản phẩm, không như các screen riêng lẻ.
