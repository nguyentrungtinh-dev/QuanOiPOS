# Store Permission Access

## Mục tiêu
Tài liệu này mô tả contract frontend khi StoreUser truy cập một cửa hàng và app áp dụng permission-based access control (PBAC) theo store.

PBAC là rule bắt buộc cho mọi store workspace/module/action/menu/route có liên quan đến cửa hàng. Nếu permission, role behavior hoặc API contract chưa rõ, phải hỏi lại trước khi implement.

## API Contract
Khi user bấm `Truy cập` ở danh sách cửa hàng, app điều hướng theo `storeId` và load:
- `GET /stores/{id}` để lấy thông tin cửa hàng.
- `GET /permissions/store/{id}/me` để lấy permission của tài khoản hiện tại trong cửa hàng.

Nếu permission API trả `succeeded: false`, app xem đây là trạng thái không có quyền truy cập store và không render module vận hành.

## Permission Source Of Truth
Permission code là application contract, không phải environment config.

Quy ước:
- Không đặt permission code trong `.env`.
- Tập trung permission code ở `lib/core/constants/app_permission_codes.dart`.
- Không hardcode permission string trong page/widget/notifier nếu đã có hoặc nên thêm vào `AppPermissionCodes`.
- UI chỉ đọc permission qua `StoreAccessState.can(...)` hoặc `StoreAccessContext.can(...)`.
- Widget không tự parse response permission và không tự build set/list permission riêng.

## Required Store Access Flow
Mọi route/page trong store workspace phải resolve access context trước khi render nội dung nghiệp vụ:
1. Watch/load `storeAccessNotifierProvider(storeId)` hoặc provider tương đương đã được feature chuẩn hóa.
2. Xử lý rõ các state `initial/loading`, `forbidden`, `error`, `ready`.
3. Chỉ khi `ready` mới render module content và khởi tạo provider nghiệp vụ cần `storeId`.
4. Nếu `forbidden`, không gọi API nghiệp vụ của module và hiển thị blocked/denied state phù hợp.
5. Nếu `error`, cho phép retry load access thay vì render module với context rỗng.

## UI Behavior
- User thiếu quyền có thể thấy một số menu/item ở trạng thái disabled nếu điều đó giúp hiểu feature tồn tại.
- Hành động thiếu quyền không được trigger API, mutation, navigation tới flow restricted, hoặc side effect nghiệp vụ.
- Backend vẫn là authority cuối cùng; frontend chỉ chặn sớm để UX rõ ràng hơn.
- Nếu action bị disabled do thiếu quyền, label/tooltip/message phải rõ lý do khi UI pattern hiện tại hỗ trợ.
- Không ẩn toàn bộ workspace nếu user chỉ thiếu một permission con; chỉ block đúng module/action bị ảnh hưởng.

## Layering
- `workspace_context`: load store detail, permission list và expose store access context.
- `store_operations`: render store shell/overview/module theo context đã resolve.
- Sub-feature store, ví dụ `store_operations/table_management`, nhận `storeId` và permission decision từ access context/provider.
- Widget không gọi Dio trực tiếp và không chứa business logic phân quyền.
- Repository/data layer xử lý API response/model/mapper; presentation không parse response envelope.

## Adding New Permissions
Khi backend thêm permission mới:
1. Thêm code vào `AppPermissionCodes`.
2. Dùng code đó qua `StoreAccessState.can(...)` hoặc `StoreAccessContext.can(...)`.
3. Cập nhật UI/menu/action visibility hoặc disabled state liên quan.
4. Đảm bảo mutation/action restricted không chạy khi `can(...) == false`.
5. Nếu permission code/API behavior chưa chắc, hỏi lại để confirm trước khi implement.

## Review Checklist
- Store route/page đã load access context trước module data.
- Có state `loading`, `forbidden`, `error`, `ready`.
- Permission string không bị hardcode ngoài `AppPermissionCodes`.
- UI không tự parse permission response.
- Disabled/hidden action không trigger API.
- Backend error/forbidden được hiển thị thành state rõ ràng.
