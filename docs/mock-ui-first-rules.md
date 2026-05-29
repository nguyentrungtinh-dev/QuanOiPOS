# Mock UI First Rules

Tài liệu này dùng khi một feature cần dựng mock UI trước, sau này mới nối API thật. Mục tiêu là cho phép lên giao diện nhanh nhưng không làm bẩn production architecture, không tạo logic giả nằm lẫn với flow thật, và không phá cấu trúc Clean Architecture + Riverpod.

## Khi Nào Áp Dụng
Áp dụng khi task có các dấu hiệu:
- User yêu cầu mock UI, prototype, demo screen, static UI, placeholder flow, hoặc "lên UI trước, API nối sau".
- Backend/API contract chưa sẵn sàng nhưng cần nhìn layout và user flow.
- Feature cần demo navigation, state empty/loading/error, hoặc PBAC visibility trước khi có datasource thật.

Nếu không rõ feature chỉ mock UI hay phải nối API thật, phải hỏi lại để confirm trước khi implement.

## Nguyên Tắc Chính
- Mock UI vẫn phải đặt đúng feature/layer, không tạo file "tạm" ngoài cấu trúc dự án.
- UI mock phải dùng `AppColors`, `AppTextStyles`, `AppConstants`, theme hiện có và widget pattern sẵn có.
- Không gọi Dio, không tạo endpoint giả trong network layer, không sửa API client chỉ để phục vụ mock.
- Không hardcode dữ liệu demo rải rác trong nhiều widget/page.
- Không để mock data trộn với repository/use case thật nếu API chưa có contract rõ.
- Mọi mock phải có ranh giới rõ: tên file, tên provider, hoặc comment ngắn cho biết đây là mock/demo data.
- Nếu mock UI thuộc store workspace/module, vẫn phải tuân theo PBAC trong [docs/store-permission-access.md](store-permission-access.md).

## Cách Đặt Mock Data
Ưu tiên theo thứ tự:
1. Nếu chỉ cần vài value để render một private widget, đặt const private trong cùng file page/widget.
2. Nếu mock data dùng cho nhiều widget trong cùng feature, đặt trong `presentation/mock/` hoặc `presentation/fixtures/` của feature.
3. Nếu cần mô phỏng state, tạo mock provider/notifier trong `presentation/providers` hoặc `presentation/controllers` với tên rõ như `<feature>Mock...Provider`.
4. Chỉ tạo entity/domain tối thiểu nếu UI cần type rõ ràng và type đó chắc chắn là nghiệp vụ thật theo `docs/spec.md`.

Không được:
- Đặt mock data trong `lib/core`.
- Đặt mock data trong datasource/repository thật.
- Tạo fake API response model phức tạp khi backend contract chưa xác nhận.
- Tạo global mock helper dùng chung khi mới có một feature cần.

## Mock State Và Interaction
Mock UI nên mô phỏng đủ trạng thái quan trọng để sau này nối API không phải viết lại layout:
- `loading`: skeleton/spinner hoặc loading state theo UI rule.
- `empty`: trạng thái không có dữ liệu.
- `error`: trạng thái lỗi có retry callback giả nếu cần demo.
- `ready`: dữ liệu mẫu đủ đại diện cho layout.
- `forbidden/disabled`: nếu là store feature có permission/PBAC.

Interaction được phép:
- Navigation nội bộ tới màn mock khác nếu route đã đúng scope.
- Button mở dialog/bottom sheet mock.
- Filter/tab/search local trên danh sách mock nếu giúp kiểm tra layout.

Interaction không được:
- Trigger API thật khi chưa có quyền/contract.
- Lưu storage/session thật chỉ để demo.
- Mutation dữ liệu giả theo kiểu phức tạp làm như business logic thật.
- Thêm workaround vào router/guard production chỉ để mock screen chạy.

## Chuẩn Bị Cho Việc Nối API Sau
Khi dựng mock UI, phải để đường nối API sau này rõ ràng:
- Page/widget nhận data qua state/provider thay vì đọc trực tiếp list mock trong nhiều chỗ.
- Tách widget presentational khỏi provider/state orchestration.
- Đặt TODO ngắn tại mock provider/data source giả, ví dụ `// TODO: Replace mock data when <API name> is available.`
- Nếu API contract đã biết, đặt type/state gần với contract dự kiến nhưng không invent field chưa có cơ sở.
- Nếu API contract chưa biết, giữ model nội bộ tối thiểu cho UI và ghi rõ assumption trong comment hoặc final response.

## PBAC Cho Mock Store UI
Store mock UI vẫn phải đi qua access context hoặc mock access state rõ ràng:
- Menu/action restricted phải đọc permission qua `can(...)` hoặc mock equivalent cùng shape.
- Không hardcode permission string ngoài `AppPermissionCodes`.
- Demo thiếu quyền bằng disabled/forbidden state thay vì bỏ qua PBAC.
- Không render module store khi mock access đang `loading`, `error`, hoặc `forbidden`.

## Review Checklist
- Mock file nằm đúng feature/layer.
- Mock data không nằm trong `lib/core`, datasource thật, repository thật hoặc network client.
- Page/widget không hardcode nhiều list demo rải rác.
- Có state `loading`, `empty`, `error`, `ready` nếu màn hình có dữ liệu.
- Store mock UI có PBAC/permission behavior nếu liên quan.
- Có ranh giới/TODO rõ để nối API sau.
- Không thêm dependency, route hack, storage write hoặc network fake không cần thiết.
