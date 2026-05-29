# Reuse Area Management Bottom Sheet In Table Settings

## Mục tiêu
Trong trang `Cài đặt bàn`, nút icon quản lý khu vực ở đầu hàng filter khu vực đang hiển thị thông báo `Khu vực sẽ được triển khai sau`.

Yêu cầu mới:
- Khi bấm nút icon này trong trang `Cài đặt bàn`, mở lại cùng bottom sheet quản lý khu vực như trang `Quản lý bàn`.
- Reuse `AreaManagementBottomSheet` hiện có.
- Giữ nguyên icon sửa từng khu vực trong danh sách settings vì nút đó đã mở form sửa trực tiếp một khu vực.

## Hành vi mong muốn
### Trang Cài đặt bàn
- `manage_areas_button` trong `AreaFilterChips` mở `AreaManagementBottomSheet`.
- Bottom sheet hiển thị header `Khu vực`, search field, nút thêm khu vực, danh sách khu vực và chế độ chỉnh sửa giống trang quản lý bàn.
- Quyền vẫn dùng `TableManagementAccess` hiện tại:
  - Có `AREA.CREATE` thì bật nút thêm khu vực.
  - Có `AREA.UPDATE` hoặc `AREA.DELETE` thì bật chế độ chỉnh sửa danh sách.
  - Chỉ có `AREA.VIEW` thì vẫn xem được bottom sheet nhưng các action thêm/sửa/xóa bị disabled.

### Không thay đổi
- Không đổi API/backend contract.
- Không đổi repository, use case, provider hoặc entity.
- Không tạo bottom sheet mới.
- Không đổi flow sửa bàn/thêm bàn hiện tại.
- Không đổi nút `settings_edit_area_*`; nút này vẫn mở `AreaFormBottomSheet` để sửa trực tiếp area tương ứng.

## Phạm vi kỹ thuật
- Import `AreaManagementBottomSheet` vào `table_settings_page.dart`.
- Đổi `AreaFilterChips.onManageAreasTap` từ `_showComingSoon(context, 'Khu vực')` sang `_showAreaManagement(context, access)`.
- Thêm helper private `_showAreaManagement(BuildContext context, TableManagementAccess access)`.
- Dùng cùng modal config với trang quản lý bàn:

```dart
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (context) {
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: AreaManagementBottomSheet(access: access),
    );
  },
);
```

## Acceptance Criteria
- Trong `Cài đặt bàn`, bấm `manage_areas_button` mở `area_management_sheet`.
- Không còn hiển thị snackbar/text `Khu vực sẽ được triển khai sau`.
- Bottom sheet dùng đúng data và permission state của trang settings.
- Với user chỉ có `AREA.VIEW`, bottom sheet vẫn mở được nhưng `add_area_button` và `edit_areas_button` disabled.
- Các test hiện có của trang quản lý bàn vẫn pass.

## Test Plan
```bash
flutter test test/features/store_operations/table_management/presentation/pages/table_management_page_test.dart
flutter analyze
```
