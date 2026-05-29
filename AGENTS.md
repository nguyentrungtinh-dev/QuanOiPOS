# QuanOi POS Agent Rules

## Mục tiêu
Khi làm việc trong QuanOi POS, Codex phải bám cấu trúc có sẵn của dự án, tái sử dụng code hiện có, giữ thay đổi gọn theo đúng source of truth và không tự ý đổi kiến trúc chỉ để làm nhanh.

## Source Of Truth
Luôn ưu tiên các file config, theme, network, storage, constants và DI đã có sẵn trong `lib/core` trước khi tạo logic mới.

Tài liệu cần đọc theo ngữ cảnh:
- Bắt đầu feature mới hoặc sửa nghiệp vụ: đọc [docs/spec.md](docs/spec.md).
- Tạo/sửa feature, state management, repository, use case, datasource, mapper hoặc DI: đọc [docs/clean-architecture-riverpod.md](docs/clean-architecture-riverpod.md).
- Cần rule chung về folder, naming, coding style và reuse: đọc [docs/coding-standards.md](docs/coding-standards.md).
- Làm store module, permission-based access control, menu/action visibility hoặc route guard theo store: đọc [docs/store-permission-access.md](docs/store-permission-access.md).
- Dựng/chỉnh UI Flutter: đọc [docs/ui-build-rules.md](docs/ui-build-rules.md).
- Dựng/chỉnh UI store workspace hoặc store switching: đọc thêm [docs/store-ui-patterns.md](docs/store-ui-patterns.md).

## Bắt Buộc
- Tìm xem code hiện có đã giải quyết được bài toán chưa trước khi tạo mới.
- Ưu tiên sửa và tái sử dụng service, helper, interceptor, mapper, repository, provider, notifier và widget sẵn có thay vì copy logic.
- Giữ naming và cấu trúc theo convention đang có trong dự án.
- Mọi feature/store UI phải tuân theo PBAC nếu có liên quan store workspace, module store, permission, menu/action visibility hoặc route guard.
- Nếu thiếu API contract, permission code, role/access behavior, folder placement, reuse decision hoặc business rule quan trọng thì phải hỏi lại để confirm trước khi implement.
- Nếu thêm file mới, đặt đúng layer và mục đích; file mới phải có nơi dùng rõ ràng.

## Không Được
- Không tạo logic trùng lặp ở nhiều layer khi có thể gom về một abstraction hợp lý.
- Không thay đổi kiến trúc nếu không có lợi ích rõ ràng cho feature hiện tại.
- Không trộn business logic, API parsing, permission policy hoặc network call trực tiếp vào widget/UI.
- Không hardcode permission code, color, spacing, typography, API base behavior nếu source of truth đã tồn tại.
- Không tạo shared/common widget khi mới chỉ dùng một lần hoặc chưa có khả năng reuse thật.

## Before Implementing A Feature
1. Đọc [docs/spec.md](docs/spec.md) để bám đúng scope nghiệp vụ và role/access model.
2. Đọc [docs/clean-architecture-riverpod.md](docs/clean-architecture-riverpod.md) để đặt đúng layer theo Clean Architecture và Riverpod convention.
3. Đọc [docs/coding-standards.md](docs/coding-standards.md) để áp dụng đúng folder, naming, coding style và reuse rule.
4. Khi làm store module hoặc permission-based access control, đọc [docs/store-permission-access.md](docs/store-permission-access.md).
5. Khi dựng/chỉnh UI Flutter, đọc [docs/ui-build-rules.md](docs/ui-build-rules.md); nếu là store workspace, đọc thêm [docs/store-ui-patterns.md](docs/store-ui-patterns.md).
6. Xác định feature thuộc layer nào: UI, domain, data, network, storage hay DI.
7. Tìm implementation sẵn có trước khi thêm mới.
8. Chỉ tách abstraction khi pattern lặp hoặc có khả năng tái sử dụng thật.
9. Giữ thay đổi nhỏ, đúng scope và dễ review.
