import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';
import 'package:ameko_app/features/payment/presentation/widgets/pin_input_widget.dart';

enum _WithdrawStep { enterAmount, enterBankInfo }

class WithdrawDialog extends StatefulWidget {
  final double availableBalance;

  const WithdrawDialog({super.key, required this.availableBalance});

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  _WithdrawStep _step = _WithdrawStep.enterAmount;
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  double _amount = 0;
  String? _amountError;
  String? _bankError;
  final _formatter = NumberFormat('#,###', 'vi_VN');

  final List<double> _quickAmounts = [100000, 200000, 500000, 1000000];

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WithdrawalSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yêu cầu rút tiền đã được gửi')),
          );
          Navigator.of(context).pop();
        } else if (state is WalletFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<WalletBloc>().add(ResetWalletStatus());
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _step == _WithdrawStep.enterAmount
                ? _buildAmountStep()
                : _buildBankInfoStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: Color(0xFFE65100), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rút tiền', style: AppTextStyles.titleMedium),
                  Text(
                    'Số dư: ${_formatter.format(widget.availableBalance.toInt())}đ',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text('Số tiền muốn rút', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.heading.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: AppTextStyles.heading.copyWith(color: AppColors.textHint),
            suffixText: 'đ',
            suffixStyle: AppTextStyles.headingMedium.copyWith(color: AppColors.textSecondary),
            errorText: _amountError,
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
            if (_amountError != null) setState(() => _amountError = null);
          },
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amount) {
            final isAvailable = amount <= widget.availableBalance;
            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      _amountController.text = amount.toInt().toString();
                      setState(() => _amountError = null);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.border.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAvailable ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                  ),
                ),
                child: Text(
                  '${_formatter.format(amount.toInt())}đ',
                  style: AppTextStyles.caption.copyWith(
                    color: isAvailable ? AppColors.primary : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _validateAndContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Tiếp tục', style: AppTextStyles.button),
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfoStep() {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final isLoading = state is WalletLoading;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _step = _WithdrawStep.enterAmount),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                Text('Thông tin ngân hàng', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: 24),

            _buildLabel('Tên ngân hàng'),
            _buildTextField(_bankNameController, 'VD: Vietcombank'),
            const SizedBox(height: 16),

            _buildLabel('Số tài khoản'),
            _buildTextField(_accountNumberController, 'Nhập số tài khoản', isNumber: true),
            const SizedBox(height: 16),

            _buildLabel('Tên chủ tài khoản'),
            _buildTextField(_accountNameController, 'VD: NGUYEN VAN A'),
            const SizedBox(height: 24),

            if (_bankError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_bankError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Gửi yêu cầu', style: AppTextStyles.button),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.label),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _validateAndContinue() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() => _amountError = 'Vui lòng nhập số tiền');
      return;
    }
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      setState(() => _amountError = 'Số tiền không hợp lệ');
      return;
    }
    if (parsed > widget.availableBalance) {
      setState(() => _amountError = 'Số tiền vượt quá số dư khả dụng');
      return;
    }
    if (parsed < 10000) {
      setState(() => _amountError = 'Số tiền tối thiểu là 10,000đ');
      return;
    }
    setState(() {
      _amount = parsed;
      _step = _WithdrawStep.enterBankInfo;
    });
  }

  void _submitWithdrawal() {
    final bank = _bankNameController.text.trim();
    final accNum = _accountNumberController.text.trim();
    final accName = _accountNameController.text.trim();

    if (bank.isEmpty || accNum.isEmpty || accName.isEmpty) {
      setState(() => _bankError = 'Vui lòng điền đầy đủ thông tin');
      return;
    }

    context.read<WalletBloc>().add(
          RequestWithdrawalEvent(
            amount: _amount,
            bankName: bank,
            bankAccountNumber: accNum,
            bankAccountName: accName,
          ),
        );
  }
}
