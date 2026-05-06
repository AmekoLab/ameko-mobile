import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';

class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final _amountCtrl = TextEditingController();
  final List<double> _suggestions = [50000, 100000, 200000, 500000, 1000000, 2000000];
  double? _selectedAmount;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onTopup() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền tối thiểu là 10,000đ')),
      );
      return;
    }
    context.read<WalletBloc>().add(RequestDeposit(amount));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is DepositReady) {
          context.push('/payment/vnpay-webview', extra: {
            'paymentUrl': state.paymentUrl,
            'checkoutBloc': null,
          }).then((result) {
            if (result == true) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nạp tiền thành công!'), backgroundColor: Colors.green),
                );
                // Refresh data and go back to Dashboard
                context.read<WalletBloc>().add(FetchWallet());
                context.read<WalletBloc>().add(FetchTransactions());
                Navigator.of(context).pop();
              }
            } else if (result == false) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giao dịch đã hủy'), backgroundColor: Colors.orange),
                );
              }
            }
          });
        } else if (state is WalletFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Nạp tiền vào ví',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập số tiền cần nạp',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 24,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'đ',
                  suffixStyle: AppTextStyles.titleMedium.copyWith(color: AppColors.textHint),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _selectedAmount = null);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Hoặc chọn mức nạp nhanh',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final amount = _suggestions[index];
                  final isSelected = _selectedAmount == amount;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                        _amountCtrl.text = amount.toInt().toString();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${(amount / 1000).toInt()}K',
                        style: AppTextStyles.body.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              _buildPaymentNote(),
              const SizedBox(height: 60),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) {
              final isLoading = state is WalletLoading;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onTopup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                        : Text(
                            'Nạp tiền ngay',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
  
    Widget _buildPaymentNote() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Giao dịch được thực hiện an toàn qua cổng thanh toán trực tuyến. Tiền sẽ được cộng vào ví ngay sau khi thanh toán thành công.',
                style: AppTextStyles.caption.copyWith(color: Colors.blue[800], height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
  }
