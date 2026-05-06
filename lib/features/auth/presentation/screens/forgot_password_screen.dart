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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _submit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final email = _formKey.currentState!.value['email'] as String;
      context.read<AuthBloc>().add(ForgotPasswordRequested(email: email));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionSuccess) {
          final email = _formKey.currentState?.fields['email']?.value as String? ?? '';
          AppSnackBar.showSuccess(context, message: state.message);
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              context.go('${AppRouter.resetPassword}?email=$email');
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
                      Icons.lock_reset_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  AppSpacing.v24,
                  Text('Quên mật khẩu?', style: AppTextStyles.heading),
                  AppSpacing.v8,
                  Text(
                    'Nhập email của bạn và chúng tôi sẽ gửi\nhướng dẫn đặt lại mật khẩu.',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.v32,
                  AppTextField(
                    name: 'email',
                    hint: 'Địa chỉ Email',
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    validator: AppValidators.validateEmail,
                  ),
                  AppSpacing.v24,
                  AppButton(
                    text: 'Gửi mã đặt lại',
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
          );
        },
      ),
    );
  }
}
