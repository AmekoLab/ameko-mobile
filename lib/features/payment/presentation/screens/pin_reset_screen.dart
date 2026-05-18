import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';
import 'package:ameko_app/features/payment/presentation/widgets/pin_input_widget.dart';

enum _ResetStep { requestOtp, enterOtp, newPin, confirmPin }

class PinResetScreen extends StatefulWidget {
  const PinResetScreen({super.key});

  @override
  State<PinResetScreen> createState() => _PinResetScreenState();
}

class _PinResetScreenState extends State<PinResetScreen> {
  _ResetStep _step = _ResetStep.requestOtp;
  final _otpController = TextEditingController();
  String _otp = '';
  String _newPin = '';
  String? _errorText;
  bool _otpSent = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is PinResetRequested) {
          setState(() {
            _otpSent = true;
            _step = _ResetStep.enterOtp;
          });
          _showSnack(context, '✓ Đã gửi OTP tới email của bạn', isSuccess: true);
        } else if (state is PinResetSuccess) {
          _showSnack(context, '✓ Đặt lại mã PIN thành công!', isSuccess: true);
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) context.pop();
          });
        } else if (state is WalletFailure) {
          setState(() => _errorText = state.message);
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
              if (_step == _ResetStep.enterOtp) {
                setState(() { _step = _ResetStep.requestOtp; _errorText = null; });
              } else if (_step == _ResetStep.newPin) {
                setState(() { _step = _ResetStep.enterOtp; _errorText = null; });
              } else if (_step == _ResetStep.confirmPin) {
                setState(() { _step = _ResetStep.newPin; _newPin = ''; _errorText = null; });
              } else {
                context.pop();
              }
            },
          ),
          title: Text('Quên mã PIN', style: AppTextStyles.titleMedium),
          centerTitle: true,
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            final isLoading = state is WalletLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  _buildProgress(),
                  const SizedBox(height: 40),
                  if (_step == _ResetStep.requestOtp) ...[
                    _buildRequestOtpContent(context, isLoading),
                  ] else if (_step == _ResetStep.enterOtp) ...[
                    _buildEnterOtpContent(context, isLoading),
                  ] else if (_step == _ResetStep.newPin) ...[
                    _buildPinContent(context, isLoading, isConfirm: false),
                  ] else ...[
                    _buildPinContent(context, isLoading, isConfirm: true),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return LinearProgressIndicator(
      value: (_step.index + 1) / 4,
      backgroundColor: AppColors.border,
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(4),
      minHeight: 6,
    );
  }

  Widget _buildRequestOtpContent(BuildContext context, bool isLoading) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 44),
        ),
        const SizedBox(height: 20),
        Text('Đặt lại mã PIN', style: AppTextStyles.headingMedium),
        const SizedBox(height: 8),
        Text(
          'Chúng tôi sẽ gửi mã OTP đến email đã đăng ký tài khoản để đặt lại mã PIN ví của bạn.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'OTP có hiệu lực trong 5 phút. Vui lòng kiểm tra cả hộp thư spam.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () => context.read<WalletBloc>().add(RequestPinResetEvent()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: AppColors.border,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Gửi mã OTP', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterOtpContent(BuildContext context, bool isLoading) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: Color(0xFF2E7D32), size: 44),
        ),
        const SizedBox(height: 20),
        Text('Nhập mã OTP', style: AppTextStyles.headingMedium),
        const SizedBox(height: 8),
        Text(
          'Nhập mã 6 chữ số vừa được gửi đến email của bạn',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: AppTextStyles.heading.copyWith(letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: AppTextStyles.heading.copyWith(
              color: AppColors.textHint,
              letterSpacing: 8,
            ),
            errorText: _errorText,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (val) {
            setState(() => _errorText = null);
            if (val.length == 6) _otp = val;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Xác nhận OTP', style: AppTextStyles.button),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: isLoading
              ? null
              : () => context.read<WalletBloc>().add(RequestPinResetEvent()),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Gửi lại OTP'),
          style: TextButton.styleFrom(foregroundColor: AppColors.info),
        ),
      ],
    );
  }

  Widget _buildPinContent(BuildContext context, bool isLoading, {required bool isConfirm}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 44),
        ),
        const SizedBox(height: 20),
        Text(
          isConfirm ? 'Xác nhận PIN mới' : 'Tạo PIN mới',
          style: AppTextStyles.headingMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isConfirm
              ? 'Nhập lại mã PIN mới để xác nhận'
              : 'Nhập mã PIN 6 số mới để bảo vệ ví',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),
        PinInputWidget(
          key: ValueKey('${_step.index}_$_errorText'),
          errorText: _errorText,
          onCompleted: isLoading ? (_) {} : (pin) => _handleNewPin(context, pin, isConfirm),
        ),
        if (isLoading) ...[
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      ],
    );
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorText = 'Vui lòng nhập đủ 6 chữ số OTP');
      return;
    }
    setState(() {
      _otp = otp;
      _step = _ResetStep.newPin;
      _errorText = null;
    });
  }

  void _handleNewPin(BuildContext context, String pin, bool isConfirm) {
    if (!isConfirm) {
      setState(() {
        _newPin = pin;
        _step = _ResetStep.confirmPin;
        _errorText = null;
      });
    } else {
      if (pin == _newPin) {
        context.read<WalletBloc>().add(
              ResetPinWithOtpEvent(otp: _otp, newPin: _newPin),
            );
      } else {
        setState(() {
          _errorText = 'PIN không khớp, vui lòng thử lại';
          _step = _ResetStep.newPin;
          _newPin = '';
        });
      }
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
