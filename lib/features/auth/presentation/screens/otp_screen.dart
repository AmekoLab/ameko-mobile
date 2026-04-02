import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/base/base_screen.dart';
import 'package:ameko_app/core/widgets/app_button.dart';
import 'package:ameko_app/core/widgets/app_spacing.dart';
import 'package:ameko_app/core/widgets/app_snack_bar.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/router/app_router.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.email = ''});
  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 4;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _submit(BuildContext context) {
    if (_otp.length < _length) {
      AppSnackBar.showError(context, message: 'Please enter the complete OTP.');
      return;
    }
    context.read<AuthBloc>().add(VerifyOtpRequested(otp: _otp));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthActionSuccess) {
          AppSnackBar.showSuccess(context, message: state.message);
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) context.go(AppRouter.login);
          });
        } else if (state is AuthFailure) {
          AppSnackBar.showError(context, message: state.message);
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return BaseScreen(
            showAppBar: true,
            centerContent: true,
            body: Column(
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
                    Icons.verified_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                AppSpacing.v24,
                Text('Enter OTP', style: AppTextStyles.heading),
                AppSpacing.v8,
                Text(
                  'Enter the $_length-digit code sent to\n${widget.email.isNotEmpty ? widget.email : "your phone"}',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.v32,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_length, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 56,
                      height: 64,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        autofocus: i == 0,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.primary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < _length - 1) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          setState(() {});
                        },
                      ),
                    );
                  }),
                ),
                AppSpacing.v32,
                AppButton(
                  text: 'Verify OTP',
                  onPressed: () => _submit(context),
                  isLoading: isLoading,
                  enabled: _otp.length == _length && !isLoading,
                ),
                AppSpacing.v20,
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Resend OTP',
                    style: AppTextStyles.link,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
