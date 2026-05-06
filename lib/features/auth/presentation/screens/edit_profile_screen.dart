import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:ameko_app/core/base/base_screen.dart';
import 'package:ameko_app/core/widgets/app_button.dart';
import 'package:ameko_app/core/widgets/app_text_field.dart';
import 'package:ameko_app/core/widgets/app_spacing.dart';
import 'package:ameko_app/core/widgets/app_snack_bar.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const ProfileFetchRequested());
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      context.read<AuthBloc>().add(
            UpdateProfileRequested(
              firstName: values['firstName'] as String?,
              lastName: values['lastName'] as String?,
              phoneNumber: values['phoneNumber'] as String?,
              gender: values['gender'] as int?,
              dateOfBirth: values['dateOfBirth'] != null 
                  ? (values['dateOfBirth'] as DateTime).toIso8601String().split('T')[0]
                  : null,
              storeAddress: values['storeAddress'] as String?,
              storeDescription: values['storeDescription'] as String?,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          AppSnackBar.showSuccess(context, message: 'Cập nhật thông tin thành công!');
          Navigator.pop(context);
        } else if (state is AuthFailure) {
          AppSnackBar.showError(context, message: state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final user = (state is AuthSuccess) ? state.user : null;

        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return BaseScreen(
          showAppBar: true,
          title: 'Cài đặt tài khoản',
          body: SingleChildScrollView(
            child: FormBuilder(
              key: _formKey,
              initialValue: {
                'firstName': user.firstName,
                'lastName': user.lastName,
                'phoneNumber': user.phoneNumber,
                'gender': user.gender,
                'dateOfBirth': user.dateOfBirth != null ? DateTime.tryParse(user.dateOfBirth!) : null,
                'storeAddress': user.storeAddress,
                'storeDescription': user.storeDescription,
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin cá nhân', style: AppTextStyles.titleMedium),
                  AppSpacing.v16,
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          name: 'firstName',
                          hint: 'Họ',
                          validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ' : null,
                        ),
                      ),
                      AppSpacing.h12,
                      Expanded(
                        child: AppTextField(
                          name: 'lastName',
                          hint: 'Tên',
                          validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.v16,
                  AppTextField(
                    name: 'phoneNumber',
                    hint: 'Số điện thoại',
                    keyboardType: TextInputType.phone,
                  ),
                  AppSpacing.v16,
                  FormBuilderDropdown<int>(
                    name: 'gender',
                    decoration: InputDecoration(
                      labelText: 'Giới tính',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Nam')),
                      DropdownMenuItem(value: 1, child: Text('Nữ')),
                      DropdownMenuItem(value: 2, child: Text('Khác')),
                    ],
                  ),
                  AppSpacing.v16,
                  FormBuilderDateTimePicker(
                    name: 'dateOfBirth',
                    inputType: InputType.date,
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  if (user.role?.toLowerCase() == 'shop') ...[
                    AppSpacing.v32,
                    Text('Thông tin cửa hàng', style: AppTextStyles.titleMedium),
                    AppSpacing.v16,
                    AppTextField(
                      name: 'storeAddress',
                      hint: 'Địa chỉ cửa hàng',
                    ),
                    AppSpacing.v16,
                    AppTextField(
                      name: 'storeDescription',
                      hint: 'Mô tả cửa hàng',
                      maxLines: 3,
                    ),
                  ],
                  AppSpacing.v40,
                  AppButton(
                    text: 'Lưu thay đổi',
                    onPressed: () => _submit(context),
                    isLoading: isLoading,
                  ),
                  AppSpacing.v32,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
