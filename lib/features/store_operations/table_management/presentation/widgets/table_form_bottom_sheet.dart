import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/area.dart';
import '../../domain/entities/dining_table.dart';

class TableFormBottomSheet extends StatefulWidget {
  final List<Area> areas;
  final Area? initialArea;
  final DiningTable? table;
  final bool allowAreaSelection;
  final bool showDeleteAction;
  final VoidCallback? onDeleteTap;
  final Future<void> Function(Area area, String name, int capacity) onSubmit;

  const TableFormBottomSheet({
    super.key,
    required this.areas,
    this.initialArea,
    this.table,
    this.allowAreaSelection = false,
    this.showDeleteAction = false,
    this.onDeleteTap,
    required this.onSubmit,
  });

  @override
  State<TableFormBottomSheet> createState() => _TableFormBottomSheetState();
}

class _TableFormBottomSheetState extends State<TableFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late int? _selectedAreaId;
  bool _isSubmitting = false;

  bool get _isEditing => widget.table != null;

  Area? get _selectedArea {
    final selectedAreaId = _selectedAreaId;
    if (selectedAreaId == null) {
      return null;
    }

    for (final area in widget.areas) {
      if (area.id == selectedAreaId) {
        return area;
      }
    }

    return widget.initialArea;
  }

  @override
  void initState() {
    super.initState();
    final table = widget.table;
    _selectedAreaId = widget.initialArea?.id ?? table?.areaId;
    _nameController = TextEditingController(text: table?.name ?? '');
    _capacityController = TextEditingController(
      text: table == null ? '' : table.capacity.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingLg,
              AppConstants.spacingMd,
              AppConstants.spacingLg,
              AppConstants.spacingLg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title,
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _AreaField(
                    areas: widget.areas,
                    selectedAreaId: _selectedAreaId,
                    allowSelection: widget.allowAreaSelection,
                    onChanged: (areaId) =>
                        setState(() => _selectedAreaId = areaId),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  TextFormField(
                    key: const Key('table_form_name_field'),
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tên bàn',
                      hintText: 'Ví dụ: Bàn 3',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên bàn';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  TextFormField(
                    key: const Key('table_form_capacity_field'),
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Số chỗ',
                      hintText: 'Ví dụ: 4',
                    ),
                    validator: (value) {
                      final capacity = int.tryParse(value?.trim() ?? '');
                      if (capacity == null) {
                        return 'Vui lòng nhập số chỗ';
                      }

                      if (capacity < 1) {
                        return 'Số chỗ phải lớn hơn 0';
                      }

                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  if (widget.showDeleteAction)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('table_form_delete_button'),
                            onPressed: _isSubmitting
                                ? null
                                : widget.onDeleteTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Xoá bàn'),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: _SubmitButton(
                            isSubmitting: _isSubmitting,
                            label: _submitLabel,
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    )
                  else
                    _SubmitButton(
                      isSubmitting: _isSubmitting,
                      label: _submitLabel,
                      onPressed: _submit,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    if (!_isEditing) {
      return 'Thêm bàn mới';
    }

    final areaName = _selectedArea?.name ?? 'khu vực';
    return 'Bàn tại "$areaName"';
  }

  String get _submitLabel => _isEditing ? 'Cập nhật' : 'Tạo bàn';

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final selectedArea = _selectedArea;
    if (selectedArea == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        selectedArea,
        _nameController.text.trim(),
        int.parse(_capacityController.text.trim()),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _AreaField extends StatelessWidget {
  final List<Area> areas;
  final int? selectedAreaId;
  final bool allowSelection;
  final ValueChanged<int?> onChanged;

  const _AreaField({
    required this.areas,
    required this.selectedAreaId,
    required this.allowSelection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!allowSelection) {
      return TextFormField(
        key: const Key('table_form_area_field'),
        initialValue: _areaName,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Khu vực',
          prefixIcon: Icon(Icons.layers_outlined),
        ),
        validator: (value) {
          if (selectedAreaId == null) {
            return 'Vui lòng chọn khu vực';
          }

          return null;
        },
      );
    }

    return DropdownButtonFormField<int>(
      key: const Key('table_form_area_select_field'),
      initialValue: selectedAreaId,
      decoration: const InputDecoration(
        labelText: 'Khu vực',
        prefixIcon: Icon(Icons.layers_outlined),
      ),
      items: [
        for (final area in areas)
          DropdownMenuItem<int>(value: area.id, child: Text(area.name)),
      ],
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Vui lòng chọn khu vực';
        }

        return null;
      },
    );
  }

  String get _areaName {
    for (final area in areas) {
      if (area.id == selectedAreaId) {
        return area.name;
      }
    }

    return '';
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final String label;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSubmitting,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: const Key('table_form_submit_button'),
      onPressed: isSubmitting ? null : onPressed,
      child: isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
