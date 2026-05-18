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
import 'package:ameko_app/core/utils/validators.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _submit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      context.read<AuthBloc>().add(
            ChangePasswordRequested(
              oldPassword: values['oldPassword'] as String,
              newPassword: values['newPassword'] as String,
              confirmNewPassword: values['confirmNewPassword'] as String,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionSuccess && state.message.contains('Đổi mật khẩu thành công')) {
          AppSnackBar.showSuccess(context, message: state.message);
          Navigator.pop(context);
        } else if (state is AuthFailure) {
          AppSnackBar.showError(context, message: state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return BaseScreen(
            showAppBar: true,
            title: 'Đổi mật khẩu',
            body: SingleChildScrollView(
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bảo mật tài khoản', style: AppTextStyles.titleMedium),
                    AppSpacing.v8,
                    Text(
                      'Mật khẩu mới phải có ít nhất 6 ký tự.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    AppSpacing.v32,
                    AppTextField(
                      name: 'oldPassword',
                      hint: 'Mật khẩu hiện tại',
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                    ),
                    AppSpacing.v16,
                    AppTextField(
                      name: 'newPassword',
                      hint: 'Mật khẩu mới',
                      isPassword: true,
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      validator: AppValidators.validatePassword,
                    ),
                    AppSpacing.v16,
                    AppTextField(
                      name: 'confirmNewPassword',
                      hint: 'Xác nhận mật khẩu mới',
                      isPassword: true,
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                        if (value != _formKey.currentState?.fields['newPassword']?.value) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.v40,
                    AppButton(
                      text: 'Cập nhật mật khẩu',
                      onPressed: () => _submit(context),
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
