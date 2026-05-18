import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';
import 'package:ameko_app/features/payment/presentation/widgets/pin_input_widget.dart';

enum _ChangePinStep { enterOld, enterNew, confirm }

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  _ChangePinStep _step = _ChangePinStep.enterOld;
  String _oldPin = '';
  String _newPin = '';
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is PinChangedSuccess) {
          _showSnack(context, '✓ Đổi mã PIN thành công!', isSuccess: true);
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) context.pop();
          });
        } else if (state is WalletFailure) {
          setState(() {
            _errorText = state.message;
            _step = _ChangePinStep.enterOld;
            _oldPin = '';
            _newPin = '';
          });
          _showSnack(context, state.message, isSuccess: false);
          context.read<WalletBloc>().add(ResetWalletStatus());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 18),
            onPressed: () {
              if (_step == _ChangePinStep.enterNew) {
                setState(() { _step = _ChangePinStep.enterOld; _oldPin = ''; _errorText = null; });
              } else if (_step == _ChangePinStep.confirm) {
                setState(() { _step = _ChangePinStep.enterNew; _newPin = ''; _errorText = null; });
              } else {
                context.pop();
              }
            },
          ),
          title: Text('Đổi mã PIN ví', style: AppTextStyles.titleMedium),
          centerTitle: true,
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildStepIndicator(),
                  const SizedBox(height: 40),
                  _buildIcon(),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 8),
                  _buildSubtitle(),
                  const SizedBox(height: 40),
                  PinInputWidget(
                    key: ValueKey(_step),
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

  Widget _buildStepIndicator() {
    final steps = ['PIN cũ', 'PIN mới', 'Xác nhận'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _step.index >= i ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: _step.index >= i ? AppColors.primary : AppColors.border,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _step.index > i
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: _step.index >= i ? Colors.white : AppColors.textHint,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[i],
                style: AppTextStyles.caption.copyWith(
                  color: _step.index >= i ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          ),
          if (i < steps.length - 1)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              color: _step.index > i ? AppColors.primary : AppColors.border,
            ),
        ],
      ],
    );
  }

  Widget _buildIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_step),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _step == _ChangePinStep.enterOld ? Icons.lock_open_rounded : Icons.lock_rounded,
          color: AppColors.primary,
          size: 44,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    const titles = {
      _ChangePinStep.enterOld: 'Nhập PIN hiện tại',
      _ChangePinStep.enterNew: 'Nhập PIN mới',
      _ChangePinStep.confirm: 'Xác nhận PIN mới',
    };
    return Text(
      titles[_step]!,
      style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle() {
    const subtitles = {
      _ChangePinStep.enterOld: 'Nhập mã PIN 6 số hiện tại của bạn',
      _ChangePinStep.enterNew: 'Tạo mã PIN 6 số mới để bảo vệ ví',
      _ChangePinStep.confirm: 'Nhập lại mã PIN mới để xác nhận',
    };
    return Text(
      subtitles[_step]!,
      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  void _handlePinCompleted(BuildContext context, String pin) {
    switch (_step) {
      case _ChangePinStep.enterOld:
        setState(() {
          _oldPin = pin;
          _step = _ChangePinStep.enterNew;
          _errorText = null;
        });
        break;
      case _ChangePinStep.enterNew:
        setState(() {
          _newPin = pin;
          _step = _ChangePinStep.confirm;
          _errorText = null;
        });
        break;
      case _ChangePinStep.confirm:
        if (pin == _newPin) {
          context.read<WalletBloc>().add(ChangePinEvent(
                oldPin: _oldPin,
                newPin: _newPin,
                confirmNewPin: pin,
              ));
        } else {
          setState(() {
            _errorText = 'PIN mới không khớp. Vui lòng thử lại.';
            _step = _ChangePinStep.enterNew;
            _newPin = '';
          });
        }
        break;
    }
  }

  void _showSnack(BuildContext context, String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? const Color(0xFF2E7D32) : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
