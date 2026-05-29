# Last Active Store Restore + Account Header Entry

## Mục tiêu
Hiện tại StoreUser mỗi lần mở app lại phải vào trang tài khoản, mở danh sách cửa hàng rồi bấm truy cập cửa hàng. Flow này gây chậm thao tác hằng ngày.

Mục tiêu:
- Ghi nhớ cửa hàng gần nhất mà StoreUser đã truy cập.
- Khi mở lại app, nếu session còn hợp lệ và có cửa hàng gần nhất, điều hướng thẳng vào trang tổng quan cửa hàng đó.
- Khi user đổi cửa hàng, cập nhật cửa hàng gần nhất.
- Trong header workspace cửa hàng, icon cài đặt đổi thành icon tài khoản để user quay về trang tài khoản.

## Hành vi mong muốn
### Mở app / restore session
- Nếu chưa đăng nhập: vào `/auth`.
- Nếu là SystemAdmin: vào `/system-admin-home`, không dùng last active store.
- Nếu là StoreUser:
  - Nếu có `last_active_store_id`: vào `/stores/:storeId`.
  - Nếu chưa có `last_active_store_id`: vào `/store-home`.
- Trong lúc app đang đọc last active store, giữ splash/loading để tránh nháy UI sai route.

### Khi chọn cửa hàng
- Từ trang danh sách cửa hàng, khi bấm `Truy cập`, lưu `storeId` vừa chọn.
- Sau đó điều hướng vào `/stores/:storeId`.

### Khi chuyển cửa hàng trong workspace
- Khi user chọn cửa hàng khác trong `StoreSwitcherBottomSheet`, lưu `storeId` mới.
- Sau đó điều hướng sang `/stores/:storeId`.
- Nếu user chọn lại cửa hàng hiện tại, chỉ đóng bottom sheet và không reload route.

### Khi vào store bằng deep link
- Nếu user vào thẳng `/stores/:storeId` và load access thành công, lưu `storeId` đó làm cửa hàng gần nhất.
- Nếu store bị từ chối quyền hoặc load lỗi, clear last active store để lần mở app sau không tự vào store lỗi.

### Header workspace cửa hàng
- Icon cài đặt trên `StoreWorkspaceHeader` đổi thành icon user/account.
- Tooltip: `Tài khoản`.
- Khi bấm icon này, điều hướng về `/store-home`.
- Quyền `STORE.UPDATE` không còn ảnh hưởng tới icon tài khoản.

## Phạm vi kỹ thuật
- Dùng `SharedPreferences` vì `storeId` gần nhất không phải dữ liệu nhạy cảm.
- Key lưu trữ: `last_active_store_id`.
- Tạo storage/use case/notifier trong luồng `workspace_context`.
- Router guard chỉ đọc state đã bootstrap, không gọi async trực tiếp trong `redirect`.
- Backend permissions vẫn là source of truth; last active store chỉ là UX shortcut.

## Acceptance Criteria
- StoreUser có last active store mở app vào thẳng `/stores/:storeId`.
- StoreUser không có last active store vẫn vào `/store-home`.
- SystemAdmin luôn bỏ qua last active store.
- Bấm `Truy cập` trong danh sách cửa hàng lưu đúng `storeId`.
- Chuyển cửa hàng trong workspace lưu đúng `storeId` mới.
- Vào deep link store hợp lệ cũng cập nhật last active store.
- Store forbidden/error clear last active store.
- Header workspace hiển thị icon tài khoản và bấm vào quay về trang tài khoản.

## Test Plan
- Unit/provider test cho last active store notifier:
  - Load stored id.
  - Save id.
  - Clear id.
- Router/widget test:
  - StoreUser + stored id vào `/stores/:id`.
  - StoreUser + không stored id vào `/store-home`.
  - SystemAdmin bỏ qua stored id.
- Flow test:
  - My Stores `Truy cập` lưu id và mở store.
  - Store switcher lưu id khi chọn store khác.
  - Store header account icon quay về account hub.
  - Store access forbidden/error clear id.

```bash
flutter test test/features/workspace_context/presentation/controllers/last_active_store_notifier_test.dart
flutter test test/features/workspace_context/presentation/controllers/store_access_notifier_test.dart
flutter test test/features/workspace_context/presentation/pages/my_stores_page_test.dart
flutter test test/features/store_operations/presentation/pages/store_overview_page_test.dart
flutter test test/features/subscription/presentation/pages/store_subscription_navigation_test.dart
```
