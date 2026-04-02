import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/base/base_screen.dart';
import 'package:ameko_app/core/widgets/app_logo.dart';
import 'package:ameko_app/core/widgets/app_button.dart';
import 'package:ameko_app/core/widgets/app_spacing.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/router/app_router.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ameko_app/core/widgets/app_snack_bar.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionSuccess) {
          AppSnackBar.showSuccess(context, message: state.message);
        }
      },
      child: BaseScreen(
        centerContent: true,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 90, showName: true),
            AppSpacing.v12,
            Text(
              'Custom Keyboard Marketplace',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            AppSpacing.v48,
            AppButton(
              text: 'Sign In',
              onPressed: () => context.go(AppRouter.login),
              variant: AppButtonVariant.primary,
            ),
            AppSpacing.v16,
            AppButton(
              text: 'Sign Up',
              onPressed: () => context.go(AppRouter.register),
              variant: AppButtonVariant.secondary,
            ),
            AppSpacing.v32,
            Text(
              'By continuing, you agree to our Terms & Privacy Policy',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
