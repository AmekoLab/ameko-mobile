import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/domain/entities/wallet_transaction_entity.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ví Ameko',
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<WalletBloc>().add(FetchTransactions()),
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is WalletFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTextStyles.body),
                  TextButton(
                    onPressed: () => context.read<WalletBloc>().add(FetchTransactions()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is WalletLoaded) {
            return Column(
              children: [
                _buildHeader(state.wallet.balance, formatter),
                Expanded(
                  child: _buildTransactionList(state.transactions, formatter),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(double balance, NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Text(
            'Số dư khả dụng',
            style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatter.format(balance.toInt())}đ',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderAction(
                icon: Icons.add_circle_outline,
                label: 'Nạp tiền',
                onTap: () => context.push('/wallet/topup'),
              ),
              const SizedBox(width: 40),
              _buildHeaderAction(
                icon: Icons.security_outlined,
                label: 'Mã PIN',
                onTap: () => context.push('/wallet/pin-setup', extra: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<WalletTransactionEntity> transactions, NumberFormat formatter) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: AppTextStyles.body.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Lịch sử giao dịch',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _buildTransactionItem(tx, formatter);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransactionEntity tx, NumberFormat formatter) {
    final isCredit = tx.isCredit;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isCredit ? Colors.green : Colors.orange).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? Colors.green : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        tx.type,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        dateStr,
        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isCredit ? "+" : "-"}${formatter.format(tx.amount.toInt())}đ',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : AppColors.textPrimary,
            ),
          ),
          Text(
            tx.status,
            style: AppTextStyles.caption.copyWith(
              color: tx.status == 'Completed' ? Colors.green : Colors.orange,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
