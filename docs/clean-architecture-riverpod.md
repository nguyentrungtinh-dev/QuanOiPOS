# QuanOi POS Code Organization

## 1. Mục tiêu
Tài liệu này quy định cách tổ chức code theo Clean Architecture và Riverpod cho dự án QuanOi POS.

Nguồn nghiệp vụ gốc:
- `docs/spec.md`

Rule coding/folder/naming chung:
- `docs/coding-standards.md`

Mục tiêu chính:
- Tách bạch `presentation`, `domain`, `data`
- Reuse tối đa các thành phần trong `lib/core`
- Dễ mở rộng theo từng feature
- Giữ rõ context: `accountType`, `activeStore`, `role` theo store

## 2. Kiến trúc tổng thể
Áp dụng `feature-first + clean layers`:
- `lib/core`: thành phần dùng chung toàn app
- `lib/features/<feature_name>`: mỗi feature tách thành 3 layer
  - `presentation`: UI + state orchestration (Riverpod)
  - `domain`: entity, value object, use case, repository contract
  - `data`: datasource, dto/model, mapper, repository implementation
- `lib/features/store_operations/<sub_feature>`: sub-feature trong store workspace, vẫn áp dụng clean layers khi có business/data riêng.

Nguyên tắc phụ thuộc:
- `presentation` phụ thuộc `domain`
- `data` phụ thuộc `domain`
- `domain` không phụ thuộc `presentation/data/framework`
- `lib/core` không phụ thuộc feature cụ thể

## 3. Cấu trúc thư mục đề xuất
Cần ưu tiên cấu trúc thực tế hiện tại của repo:

```text
lib/
  main.dart
  app.dart

  config/

  core/
    constants/
    di/
    env/
    network/
      dio/
      interceptors/
      responses/
    session/
    storage/
    theme/

  features/
    auth/
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

    workspace_context/
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

    subscription/
      presentation/
      domain/
      data/

    system_admin/
      presentation/

    store_operations/
      presentation/
        pages/
        widgets/
      table_management/
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
          repositories/
```

Ghi chú:
- `system_admin` và `store_operations` có thể tách tiếp thành sub-feature theo module nghiệp vụ khi module có domain/data riêng.
- Store sub-feature đặt dưới `store_operations/<module_name>` và giữ 3 layer như `table_management`.
- Nếu feature nhỏ, có thể bắt đầu với ít thư mục hơn, nhưng vẫn giữ 3 layer chính.
- Không tạo `lib/shared` nếu chưa có nhu cầu reuse thật giữa nhiều feature; xem thêm `docs/coding-standards.md`.

## 4. Quy tắc theo layer
### 4.1 Presentation
Chứa:
- Page/Screen, Widget
- Riverpod provider cho state, action, side effects
- Controller/Notifier gọi use case

Không chứa:
- Logic parse JSON
- Logic gọi Dio trực tiếp
- Business rules lõi nằm ngoài use case
- Permission policy phức tạp hoặc response parsing của PBAC

### 4.2 Domain
Chứa:
- Entity nghiệp vụ
- Repository contract (abstract class)
- Use case xử lý nghiệp vụ

Không chứa:
- Dio, SharedPreferences, Flutter widget
- DTO/JSON annotation framework-specific

### 4.3 Data
Chứa:
- Remote/local datasource
- DTO/model và mapper model <-> entity
- Repository implementation
- Xử lý API response envelope và chuyển đổi về domain entity/state lỗi phù hợp

Không chứa:
- Điều hướng UI
- Business rules thuộc domain policy

## 5. Riverpod Convention
### 5.1 Loại provider
- Read-only async data: `FutureProvider` hoặc `StreamProvider`
- State + business action: `NotifierProvider`/`AsyncNotifierProvider`
- Object stateless dùng chung: `Provider`

### 5.2 Quy ước đặt tên
- Provider: `<feature><purpose>Provider`
- Notifier: `<Feature><Purpose>Notifier`
- State: `<Feature><Purpose>State`
- Use case: `VerbNounUseCase` (vd: `ResolveAccountTypeUseCase`)

### 5.3 Vị trí provider
- Provider của feature đặt trong feature đó, dưới `presentation/providers`
- Chỉ provider global/composition root mới đặt ở `lib/core/di` hoặc khu vực global đã có convention rõ ràng.
- Provider sub-feature store đặt trong sub-feature, ví dụ `store_operations/table_management/presentation/providers`.

### 5.4 Flow chuẩn
Luồng phụ thuộc chuẩn:
- `Page/Widget -> Notifier/Provider -> UseCase -> Repository contract -> Repository impl -> Datasource`

Nguyên tắc:
- Page/widget chỉ điều phối UI state, user intent và navigation cần thiết.
- Notifier/provider gọi use case, không gọi Dio trực tiếp.
- Use case làm việc qua repository contract.
- Repository implementation gọi datasource và mapper.
- Datasource xử lý endpoint/network detail qua `lib/core/network`.

## 6. Workspace Context Module (Required for StoreUser)
Theo `docs/spec.md`, `StoreUser` sau login phải resolve workspace context trước khi vào module vận hành.

### 6.1 Domain contracts đề xuất
- `LoadStoreMembershipsUseCase`: lấy danh sách membership theo account.
- `SelectActiveStoreUseCase`: set/cập nhật active store.
- `ResolveActiveRoleUseCase`: resolve role của user theo active store.

### 6.2 State contract đề xuất
`WorkspaceContextState` gồm các trạng thái chính:
- `bootstrapping`: đang load membership/context sau login.
- `selectingStore`: cần user chọn store (trường hợp nhiều store).
- `ready`: đã có `activeStore` + `activeRole`.
- `error`: lỗi load/resolve context.

Thông tin đi kèm state:
- `accountType`
- `memberships`
- `activeStoreId`
- `activeRole`
- `errorMessage` (nếu có)

### 6.3 Data responsibility
- Datasource gọi API memberships và role/context endpoint (nếu có).
- Repository map response -> domain entity (`StoreMembership`, `WorkspaceContext`).
- Không cho presentation parse response envelope trực tiếp.

## 7. Mapping từ spec sang feature modules
Theo `docs/spec.md`:

- FR-01, FR-02: `features/auth` + route-level `account-type guard`
  - Resolve account type
  - Route theo `SystemAdmin/StoreUser`

- FR-03, FR-04, FR-05, FR-06, FR-11, FR-12, FR-13, FR-14: `features/workspace_context`
  - Load memberships
  - Resolve role theo active store
  - Store selection/switching
  - Workspace context + permission context

- FR-07, FR-08, FR-09, FR-10: `features/system_admin`
  - `store_management`
  - `user_management`
  - `package_management`
  - `revenue`

## 8. Shared Domain Model bắt buộc
Entity cốt lõi nên thống nhất tại domain layer của feature phù hợp:
- `Account`
- `AccountType`
- `Store`
- `StoreMembership`
- `StoreRole` (`Owner/Manager/Staff/Kitchen`)
- `WorkspaceContext`
- `ServicePackage`
- `RevenueRecord`

Tránh:
- Định nghĩa trùng cùng một entity ở nhiều feature.

## 9. DI và Composition Root
- Khai báo dependency ở `lib/core/di`
- Provider wiring theo từng feature, inject repository contract vào use case
- Repository implementation bind với datasource trong composition root

Luồng chuẩn:
- `UI/Notifier -> UseCase -> Repository contract -> Repository impl -> Datasource`

## 10. Network và Response Handling
Dựa trên hiện trạng network layer:
- Tái sử dụng `lib/core/network` hiện có
- Repository/data mapper xử lý chuyển đổi response -> domain entity
- Không để presentation xử lý response envelope
- Không gọi Dio trực tiếp từ widget, page, notifier nếu đã có datasource/repository phù hợp.
- Khi endpoint trả envelope/list phức tạp, parse trong data model/mapper và expose entity sạch cho domain/presentation.

## 11. Navigation và Access Guard
### 11.1 Account-type guard
Kiểm tra `accountType` để chặn route chéo giữa `SystemAdmin` và `StoreUser`.

### 11.2 Workspace-role guard
Chỉ áp dụng cho `StoreUser`:
- Nếu chưa có `activeStoreId` -> bắt buộc điều hướng về `store picker`.
- Nếu có `activeStoreId` nhưng chưa resolve role -> giữ ở state loading/error phù hợp.
- Nếu có đủ context -> cho vào role-home/module tương ứng.

Nguyên tắc:
- Guard logic phải tách khỏi widget build để dễ test.

## 12. Testing Strategy
### 12.1 Domain tests
- Unit test cho use case và business rule.
- Bắt buộc có test cho branch: 0 store, 1 store, nhiều store.

### 12.2 Data tests
- Mapper test.
- Repository test với fake datasource/mock API.

### 12.3 Presentation tests
- Provider/Notifier state transition test cho `WorkspaceContextState`.
- Widget test cho màn `store picker` và `role-home entry`.

### 12.4 Router guard tests
- `StoreUser` chưa có activeStore -> redirect đúng.
- `StoreUser` đổi store -> route refresh theo context mới.

## 13. Quy tắc thêm feature mới
1. Đọc `docs/spec.md` để xác định đúng scope nghiệp vụ.
2. Đọc tài liệu này để đặt đúng cấu trúc layer.
3. Đọc `docs/coding-standards.md` để áp dụng đúng folder, naming và reuse rule.
4. Nếu feature liên quan store workspace/module/permission, đọc `docs/store-permission-access.md`.
5. Tái sử dụng `lib/core` trước khi tạo mới.
6. Chỉ tạo abstraction khi có nhu cầu tái sử dụng thật.
7. Giữ mỗi PR tập trung 1 feature hoặc 1 luồng nghiệp vụ rõ ràng.

## 14. Definition of Done (Architecture)
Một task được xem là hoàn thành về mặt kiến trúc khi:
- Đặt đúng layer theo clean architecture
- Provider đặt đúng scope feature/global
- Không trùng lặp entity/repository logic
- Không trộn business logic vào UI
- Guard tách account-type và workspace-role rõ ràng
- Pass test tối thiểu cho use case hoặc provider quan trọng

## 15. Change Log
- 2026-05-19: Initial guideline based on spec and project constraints.
- 2026-05-19: Added StoreUser workspace-context module contracts and dual-guard navigation rules.
- 2026-05-29: Synced folder guidance with current repo, added coding standards reference, store sub-feature convention, and standard dependency flow.
