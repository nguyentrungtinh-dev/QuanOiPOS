import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/area.dart';

class AreaFormBottomSheet extends StatefulWidget {
  final Area? area;
  final Future<void> Function(String name, String description) onSubmit;

  const AreaFormBottomSheet({super.key, this.area, required this.onSubmit});

  @override
  State<AreaFormBottomSheet> createState() => _AreaFormBottomSheetState();
}

class _AreaFormBottomSheetState extends State<AreaFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;

  bool get _isEditing => widget.area != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.area?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.area?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
                          _isEditing ? 'Chỉnh sửa khu vực' : 'Thêm khu vực',
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  TextFormField(
                    key: const Key('area_form_name_field'),
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tên khu vực',
                      hintText: 'Ví dụ: Phòng VIP',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên khu vực';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  TextFormField(
                    key: const Key('area_form_description_field'),
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      hintText: 'Mô tả ngắn về khu vực',
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  ElevatedButton(
                    key: const Key('area_form_submit_button'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Cập nhật' : 'Tạo khu vực'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
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
