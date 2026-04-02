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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _submit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      context.read<AuthBloc>().add(
            RegisterRequested(
              name: values['name'] as String,
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
            showAppBar: true,
            title: 'Create Account',
            centerContent: false,
            body: SingleChildScrollView(
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.v8,
                    Text('Join Ameko', style: AppTextStyles.heading),
                    AppSpacing.v8,
                    Text(
                      'Fill in the details below to get started.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    AppSpacing.v32,
                    AppTextField(
                      name: 'name',
                      hint: 'Full Name',
                      autofocus: true,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      validator: AppValidators.validateName,
                    ),
                    AppSpacing.v16,
                    AppTextField(
                      name: 'email',
                      hint: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      validator: AppValidators.validateEmail,
                    ),
                    AppSpacing.v16,
                    AppTextField(
                      name: 'password',
                      hint: 'Password',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      validator: AppValidators.validatePassword,
                    ),
                    AppSpacing.v32,
                    AppButton(
                      text: 'Create Account',
                      onPressed: () => _submit(context),
                      isLoading: isLoading,
                      enabled: !isLoading,
                    ),
                    AppSpacing.v24,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.bodySecondary,
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRouter.login),
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.link.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.v32,
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
