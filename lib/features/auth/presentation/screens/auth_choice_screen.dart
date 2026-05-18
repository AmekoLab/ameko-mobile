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
              'Sàn thương mại Bàn phím Tùy chỉnh',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            AppSpacing.v48,
            AppButton(
              text: 'Đăng nhập',
              onPressed: () => context.go(AppRouter.login),
              variant: AppButtonVariant.primary,
            ),
            AppSpacing.v16,
            AppButton(
              text: 'Đăng ký',
              onPressed: () => context.go(AppRouter.register),
              variant: AppButtonVariant.secondary,
            ),
            AppSpacing.v32,
            Text(
              'Bằng cách tiếp tục, bạn đồng ý với Điều khoản & Chính sách Bảo mật của chúng tôi',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
