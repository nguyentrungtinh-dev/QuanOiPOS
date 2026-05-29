# QuanOi POS Coding Standards

Tài liệu này gom các quy tắc chung về folder, naming, style code và reuse khi làm việc trong QuanOi POS. Khi có xung đột, ưu tiên source of truth trong `lib/core`, `docs/spec.md`, và rule chuyên biệt của feature đang làm.

## Folder Structure
Dự án áp dụng `feature-first + clean layers`:
- `lib/core`: constants, DI, env, network, storage, session, theme và các thành phần dùng chung toàn app.
- `lib/features/<feature>`: feature độc lập, tách theo `presentation`, `domain`, `data`.
- `lib/features/store_operations/<sub_feature>`: sub-feature trong store workspace, vẫn phải giữ 3 layer nếu có business/data riêng.

Layer chuẩn:
```text
lib/features/<feature>/
  presentation/
    pages/
    widgets/
    providers/
    controllers/
  domain/
    entities/
    repositories/
    usecases/
  data/
    datasources/
    models/
    mappers/
    repositories/
```

Quy tắc đặt file:
- Page/screen chỉ đặt trong `presentation/pages`.
- Widget của feature đặt trong `presentation/widgets`.
- Provider/notifier/state đặt trong `presentation/providers` và `presentation/controllers`.
- Entity, repository contract và use case đặt trong `domain`.
- Datasource, request/response model, mapper và repository implementation đặt trong `data`.
- Shared/core chỉ dùng cho code thật sự dùng lại giữa nhiều feature; không đưa code vào shared chỉ vì "có thể sau này cần".

## Naming Convention
- Entity: tên nghiệp vụ ngắn gọn, ví dụ `Store`, `DiningTable`, `ServicePackage`.
- Model/DTO: thêm hậu tố `Model` hoặc `RequestModel`, ví dụ `StoreModel`, `LoginRequestModel`.
- Mapper: ưu tiên extension hoặc mapper gần data model, ví dụ `StoreModel.toEntity()`.
- Datasource: `<Feature>RemoteDataSource`, `<Feature>LocalDataSource`.
- Repository contract: `<Feature>Repository`; implementation: `<Feature>RepositoryImpl`.
- Use case: `VerbNounUseCase`, ví dụ `LoadStoreAccessContextUseCase`.
- Notifier/controller: `<Feature><Purpose>Notifier`.
- State: `<Feature><Purpose>State` kèm enum status nếu cần.
- Provider: `<feature><purpose>Provider`.
- Widget: tên theo UI purpose, không đặt tên chung chung như `CommonCard` nếu scope thực tế chỉ thuộc một feature.

## Dart And Flutter Style
- Chạy theo `flutter_lints` hiện có và giữ code format bằng Dart formatter.
- Dùng `const` khi có thể.
- Giữ function/widget nhỏ, dễ đọc, có tham số rõ ràng.
- Tránh đặt business rule, permission policy, API parsing hoặc data mapping trong widget.
- Tránh nested widget quá dài trong `build()`; tách private widget nếu nó giúp đọc code rõ hơn.
- Comment ngắn gọn chỉ khi logic không tự giải thích được.
- Không thêm dependency mới nếu chưa kiểm tra package hiện có có giải quyết được chưa.

## Source Of Truth Reuse
Trước khi tạo mới, phải tìm trong các khu vực sau:
- Theme/token: `lib/core/theme`, `lib/core/constants/app_constants.dart`.
- Permission code: `lib/core/constants/app_permission_codes.dart`.
- Network: `lib/core/network`.
- Storage/session: `lib/core/storage`, `lib/core/session`.
- DI/composition root: `lib/core/di`.
- Feature provider/notifier/repository/use case đã có trong feature liên quan.

Nếu phải mở rộng source of truth:
- Mở rộng ở một nơi duy nhất.
- Giữ API nhỏ và đúng mục đích.
- Cập nhật các call site liên quan thay vì copy logic.

## Mock UI First
Khi feature cần dựng UI trước rồi nối API sau, đọc [docs/mock-ui-first-rules.md](mock-ui-first-rules.md).

Quy tắc nhanh:
- Mock data phải nằm gần feature UI, ví dụ `presentation/mock/`, `presentation/fixtures/`, hoặc private const trong page/widget nếu rất nhỏ.
- Không đặt mock data trong `lib/core`, datasource thật, repository thật, network client hoặc storage/session thật.
- Không tạo abstraction production chỉ để phục vụ dữ liệu demo.
- Page/widget nên nhận data qua state/provider để sau này thay mock bằng API mà không viết lại layout.
- Mock provider/data phải đặt tên rõ và có TODO ngắn để thay bằng API thật khi contract sẵn sàng.

## PBAC And Store Features
Mọi feature liên quan store workspace/module/action/menu phải tuân theo [docs/store-permission-access.md](store-permission-access.md):
- Page store phải resolve `StoreAccessState` trước khi render nội dung nghiệp vụ.
- UI chỉ check permission qua `StoreAccessState.can(...)` hoặc `StoreAccessContext.can(...)`.
- Mutation/action thiếu quyền không được trigger API.
- Permission code phải lấy từ `AppPermissionCodes`, không hardcode string trong page/widget.

## Widget Reuse Decision
Trước khi tạo widget mới:
1. Tìm widget/pattern tương tự trong feature hiện tại.
2. Nếu chỉ dùng trong một page và chỉ để giảm độ dài `build()`, tạo private widget trong cùng file.
3. Nếu dùng lại trong cùng feature/sub-feature, đặt trong `presentation/widgets`.
4. Nếu dùng lại giữa nhiều feature, mới cần đưa vào shared/core phù hợp.
5. Nếu chưa rõ widget có nên shared hay không, giữ gần nơi sử dụng trước và hỏi lại khi quyết định ảnh hưởng nhiều màn hình.

Không tách widget chỉ vì nó có thể dùng lại trong tương lai. Tách khi có lặp lại thực tế, làm giảm phức tạp rõ ràng, hoặc đã là pattern UI của sản phẩm.

## Definition Of Done
Một thay đổi code được xem là đúng chuẩn khi:
- Đặt đúng folder/layer.
- Reuse source of truth trước khi tạo mới.
- Không có business logic trong UI.
- PBAC được áp dụng cho store feature nếu liên quan.
- Mock UI có ranh giới rõ và không trộn vào network/repository/use case production.
- Widget mới có scope đúng: private, feature-level hoặc shared/core.
- Naming khớp convention hiện có.
- Có test phù hợp với rủi ro thay đổi, hoặc nếu không test thì nêu rõ lý do.
