import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/base/base_screen.dart';
import 'package:ameko_app/core/widgets/app_button.dart';
import 'package:ameko_app/core/widgets/app_text_field.dart';
import 'package:ameko_app/core/widgets/app_spacing.dart';
import 'package:ameko_app/core/widgets/app_snack_bar.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/utils/validators.dart';
import 'package:ameko_app/core/router/app_router.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  static const _otpLength = 6;
  final _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _submit(BuildContext context) {
    final code = _otpCode;
    if (code.length != _otpLength) {
      AppSnackBar.showError(context, message: 'Vui lòng nhập đầy đủ mã 6 số.');
      return;
    }

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      context.read<AuthBloc>().add(ResetPasswordRequested(
            email: widget.email,
            code: code,
            newPassword: values['newPassword'] as String,
            confirmPassword: values['confirmPassword'] as String,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionSuccess) {
          AppSnackBar.showSuccess(context, message: state.message);
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              context.go(AppRouter.login);
            }
          });
        } else if (state is AuthFailure) {
          AppSnackBar.showError(context, message: state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return BaseScreen(
            showAppBar: true,
            centerContent: true,
            body: FormBuilder(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.security_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    AppSpacing.v24,
                    Text('Đặt lại mật khẩu', style: AppTextStyles.heading),
                    AppSpacing.v8,
                    Text(
                      'Nhập mã 6 số đã được gửi tới ${widget.email}\nvà mật khẩu mới của bạn.',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.v32,
                    _buildOtpInput(),
                    AppSpacing.v32,
                    AppTextField(
                      name: 'newPassword',
                      hint: 'Mật khẩu mới',
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      validator: AppValidators.validatePassword,
                    ),
                    AppSpacing.v16,
                    AppTextField(
                      name: 'confirmPassword',
                      hint: 'Xác nhận mật khẩu',
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_reset_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      validator: (value) => AppValidators.validateConfirmPassword(
                        value,
                        _formKey.currentState?.fields['newPassword']?.value as String?,
                      ),
                    ),
                    AppSpacing.v24,
                    AppButton(
                      text: 'Đặt lại mật khẩu',
                      onPressed: () => _submit(context),
                      isLoading: isLoading,
                      enabled: !isLoading,
                    ),
                    AppSpacing.v20,
                    TextButton(
                      onPressed: () => context.go(AppRouter.login),
                      child: Text('Quay lại Đăng nhập', style: AppTextStyles.link),
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

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 45,
          height: 56,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < _otpLength - 1) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}
