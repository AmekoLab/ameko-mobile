import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';
import 'package:ameko_app/features/payment/presentation/widgets/pin_input_widget.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isSetup; // true = first-time setup, false = change PIN

  const PinSetupScreen({super.key, this.isSetup = true});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  int _step = 1; // 1 = enter, 2 = confirm
  String _firstPin = '';
  String? _errorText;
  final _pinKey = GlobalKey<State>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is PinSetupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thiết lập PIN thành công!'),
              backgroundColor: Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is WalletFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (_step == 2) {
                setState(() {
                  _step = 1;
                  _firstPin = '';
                  _errorText = null;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.isSetup ? 'Tạo mã PIN ví' : 'Đổi mã PIN ví',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Step indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStep(1, 'Nhập PIN', _step >= 1),
                      Container(
                        width: 48,
                        height: 2,
                        color: _step >= 2 ? AppColors.primary : AppColors.border,
                      ),
                      _buildStep(2, 'Xác nhận', _step >= 2),
                    ],
                  ),
                  const SizedBox(height: 40),

                  const Icon(Icons.lock_rounded,
                      color: AppColors.primary, size: 52),
                  const SizedBox(height: 16),

                  Text(
                    _step == 1 ? 'Nhập mã PIN 6 số' : 'Xác nhận mã PIN',
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 1
                        ? 'Tạo mã PIN để bảo vệ ví của bạn'
                        : 'Nhập lại mã PIN để xác nhận',
                    style:
                        AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  PinInputWidget(
                    key: ValueKey(_step), // remount on step change
                    errorText: _errorText,
                    onCompleted: (pin) => _handlePinCompleted(context, pin),
                  ),

                  if (state is WalletLoading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: AppColors.primary),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.background,
            border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textHint,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.textHint),
        ),
      ],
    );
  }

  void _handlePinCompleted(BuildContext context, String pin) {
    if (_step == 1) {
      setState(() {
        _firstPin = pin;
        _step = 2;
        _errorText = null;
      });
    } else {
      if (pin == _firstPin) {
        context.read<WalletBloc>().add(SetupPin(pin));
      } else {
        setState(() {
          _errorText = 'Mã PIN không khớp. Vui lòng thử lại.';
          _step = 1;
          _firstPin = '';
        });
      }
    }
  }
}
