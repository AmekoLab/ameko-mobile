import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/base/base_screen.dart';
import 'package:ameko_app/core/widgets/app_logo.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      context.read<AuthBloc>().add(
            LoginRequested(
              email: values['email'] as String,
              password: values['password'] as String,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          context.go(AppRouter.home);
        } else if (state is AuthFailure) {
          AppSnackBar.showError(context, message: state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return BaseScreen(
            centerContent: true,
            body: FormBuilder(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AppLogo(size: 72),
                  AppSpacing.v24,
                  Text('Đăng nhập', style: AppTextStyles.heading),
                  AppSpacing.v8,
                  Text(
                    'Chào mừng trở lại! Vui lòng đăng nhập để tiếp tục.',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.v32,
                  AppTextField(
                    name: 'email',
                    hint: 'Email',
                    autofocus: true,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    validator: AppValidators.validateEmail,
                    onChanged: (_) => setState(() {}),
                  ),
                  AppSpacing.v16,
                  AppTextField(
                    name: 'password',
                    hint: 'Mật khẩu',
                    isPassword: true,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    validator: AppValidators.validatePassword,
                    onChanged: (_) => setState(() {}),
                  ),
                  AppSpacing.v12,
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(AppRouter.forgotPassword),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Quên mật khẩu?',
                        style: AppTextStyles.link,
                      ),
                    ),
                  ),
                  AppSpacing.v24,
                  AppButton(
                    text: 'Đăng nhập',
                    onPressed: () => _submit(context),
                    isLoading: isLoading,
                    enabled: !isLoading,
                  ),
                  AppSpacing.v20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Chưa có tài khoản? ",
                        style: AppTextStyles.bodySecondary,
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRouter.register),
                        child: Text(
                          'Đăng ký',
                          style: AppTextStyles.link.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
