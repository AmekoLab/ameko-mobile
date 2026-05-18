import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/domain/entities/transaction_entity.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchTransactionDetail(widget.transactionId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Chi tiết giao dịch', style: AppTextStyles.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () {
              // TODO: implement share receipt
            },
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.read<WalletBloc>().add(
                            FetchTransactionDetail(widget.transactionId),
                          ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is TransactionDetailLoaded) {
            return _buildContent(state.detail);
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        },
      ),
    );
  }

  Widget _buildContent(TransactionDetailEntity detail) {
    final isIn = detail.flowDirection == 'In';
    final isHeld = detail.flowDirection == 'Held';
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(detail.createdAt);

    Color amountColor;
    Color iconColor;
    Color iconBg;
    IconData iconData;

    if (isIn) {
      amountColor = const Color(0xFF2E7D32);
      iconColor = const Color(0xFF2E7D32);
      iconBg = const Color(0xFFE8F5E9);
      iconData = Icons.arrow_downward_rounded;
    } else if (isHeld) {
      amountColor = Colors.amber[700]!;
      iconColor = Colors.amber[700]!;
      iconBg = Colors.amber[50]!;
      iconData = Icons.lock_rounded;
    } else {
      amountColor = AppColors.error;
      iconColor = AppColors.error;
      iconBg = Colors.red[50]!;
      iconData = Icons.arrow_upward_rounded;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero amount card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(iconData, color: iconColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  _localizeType(detail.type),
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isIn ? "+" : isHeld ? "" : "-"}${_formatter.format(detail.amount.toInt())}đ',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusBadge(detail.status),
                const SizedBox(height: 8),
                Text(dateStr, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transaction info card
          _buildCard(
            title: 'Thông tin giao dịch',
            icon: Icons.receipt_long_outlined,
            children: [
              _buildRow('Mã giao dịch', detail.transactionCode, copyable: true),
              _buildRow('Loại', _localizeType(detail.type)),
              _buildRow('Chiều', _localizeFlow(detail.flowDirection)),
              _buildRow('Đơn vị', detail.currency),
              if (detail.description?.isNotEmpty == true)
                _buildRow('Mô tả', detail.description!),
            ],
          ),
          const SizedBox(height: 12),

          // Amount breakdown card
          _buildCard(
            title: 'Chi tiết số tiền',
            icon: Icons.calculate_outlined,
            children: [
              _buildRow('Số tiền gốc', '${_formatter.format(detail.grossAmount.toInt())}đ'),
              if (detail.feeAmount > 0)
                _buildRow('Phí giao dịch', '${_formatter.format(detail.feeAmount.toInt())}đ',
                    valueColor: AppColors.error),
              _buildRow('Số tiền thực nhận', '${_formatter.format(detail.netAmount.toInt())}đ',
                  valueStyle: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  )),
              const Divider(height: 20),
              _buildRow('Số dư trước', '${_formatter.format(detail.balanceBeforeTransaction.toInt())}đ'),
              _buildRow('Số dư sau', '${_formatter.format(detail.balanceAfterTransaction.toInt())}đ',
                  valueStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),

          if (detail.bankName != null || detail.bankAccountNumber != null) ...[
            const SizedBox(height: 12),
            _buildCard(
              title: 'Thông tin ngân hàng',
              icon: Icons.account_balance_outlined,
              children: [
                if (detail.bankName != null) _buildRow('Ngân hàng', detail.bankName!),
                if (detail.bankAccountNumber != null)
                  _buildRow('Số tài khoản', detail.bankAccountNumber!, copyable: true),
                if (detail.bankAccountName != null)
                  _buildRow('Chủ tài khoản', detail.bankAccountName!),
              ],
            ),
          ],

          if (detail.shopName != null || detail.relatedOrderId != null) ...[
            const SizedBox(height: 12),
            _buildCard(
              title: 'Thông tin đơn hàng',
              icon: Icons.shopping_bag_outlined,
              children: [
                if (detail.shopName != null) _buildRow('Cửa hàng', detail.shopName!),
                if (detail.relatedOrderId != null)
                  _buildRow('Mã đơn hàng', detail.relatedOrderId!, copyable: true),
                if (detail.orderGroupId != null)
                  _buildRow('Mã nhóm đơn', detail.orderGroupId!, copyable: true),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool copyable = false,
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã copy: $value'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: valueStyle ??
                          AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: valueColor ?? AppColors.textPrimary,
                          ),
                    ),
                  ),
                  if (copyable)
                    Icon(Icons.copy_outlined, size: 14, color: AppColors.textHint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF2E7D32);
        text = 'Thành công';
        break;
      case 'pending':
        color = Colors.amber[700]!;
        text = 'Đang xử lý';
        break;
      case 'failed':
        color = Colors.red[600]!;
        text = 'Thất bại';
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  String _localizeType(String type) {
    switch (type) {
      case 'Deposit': return 'Nạp tiền';
      case 'Payment': return 'Thanh toán đơn hàng';
      case 'Refund': return 'Hoàn tiền';
      case 'Withdrawal': return 'Rút tiền';
      case 'Hold': return 'Giữ tiền';
      case 'Release': return 'Giải phóng tiền';
      default: return type;
    }
  }

  String _localizeFlow(String flow) {
    switch (flow) {
      case 'In': return 'Tiền vào (+)';
      case 'Out': return 'Tiền ra (-)';
      case 'Held': return 'Đang giữ';
      default: return flow;
    }
  }
}
