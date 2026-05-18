import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/domain/entities/transaction_entity.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/wallet/wallet_state.dart';
import 'package:ameko_app/features/payment/presentation/widgets/withdraw_dialog.dart';
import 'package:ameko_app/features/payment/domain/entities/withdrawal_entity.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFormatter = NumberFormat('#,###', 'vi_VN');
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletBloc>()
        ..add(FetchTransactions())
        ..add(FetchHeldTransactions())
        ..add(const FetchWithdrawals());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WithdrawalSuccess) {
          _showSnackBar(context, '✓ Gửi yêu cầu rút tiền thành công!', isSuccess: true);
          context.read<WalletBloc>()
            ..add(FetchTransactions())
            ..add(const FetchWithdrawals());
        } else if (state is WalletFailure) {
          _showSnackBar(context, state.message, isSuccess: false);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<WalletBloc>()
                ..add(FetchTransactions())
                ..add(FetchHeldTransactions())
                ..add(const FetchWithdrawals());
            },
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                if (state is WalletLoading && state is! WalletLoaded)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (state is WalletLoaded) ...[
                  _buildBalanceCard(state),
                  _buildQuickActions(state),
                  _buildTabSection(state),
                ] else if (state is WalletFailure) ...[
                  SliverFillRemaining(child: _buildError(context, state.message)),
                ] else ...[
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text('Ví Ameko', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Làm mới',
          onPressed: () {
            context.read<WalletBloc>()
              ..add(FetchTransactions())
              ..add(FetchHeldTransactions())
              ..add(const FetchWithdrawals());
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (val) {
            if (val == 'change_pin') {
              context.push('/wallet/pin-change');
            } else if (val == 'reset_pin') {
              context.push('/wallet/pin-reset');
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'change_pin', child: Text('Đổi mã PIN')),
            const PopupMenuItem(value: 'reset_pin', child: Text('Quên mã PIN')),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(WalletLoaded state) {
    final balance = state.wallet.balance;
    final heldBalance = state.wallet.heldBalance;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số dư khả dụng',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                        child: Icon(
                          _balanceVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _balanceVisible
                        ? Text(
                            key: const ValueKey('shown'),
                            '${_currencyFormatter.format(balance.toInt())}đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          )
                        : Text(
                            key: const ValueKey('hidden'),
                            '••••••đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                  ),
                  if (heldBalance > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Đang giữ: ${_currencyFormatter.format(heldBalance.toInt())}đ',
                          style: AppTextStyles.caption.copyWith(color: Colors.amber),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Ví điện tử Ameko',
                        style: AppTextStyles.caption.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(WalletLoaded state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            _buildActionButton(
              icon: Icons.add_rounded,
              label: 'Nạp tiền',
              color: const Color(0xFF2E7D32),
              onTap: () => context.push('/wallet/topup'),
            ),
            const SizedBox(width: 12),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final isShop = authState is AuthSuccess && authState.user.role?.toLowerCase() == 'shop';
                if (!isShop) return const SizedBox.shrink();
                
                return _buildActionButton(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Rút tiền',
                  color: const Color(0xFFE65100),
                  onTap: () => _showWithdrawDialog(context, state.wallet.balance),
                );
              },
            ),
            if (context.read<AuthBloc>().state is AuthSuccess && (context.read<AuthBloc>().state as AuthSuccess).user.role?.toLowerCase() == 'shop')
              const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.security_rounded,
              label: 'Mã PIN',
              color: AppColors.primary,
              onTap: () => _showPinOptions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection(WalletLoaded state) {
    final transactions = state.paginatedTransactions?.items ?? [];
    final heldTransactions = state.heldTransactions;
    final withdrawals = state.withdrawals;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.caption,
              tabs: [
                Tab(text: 'Giao dịch (${transactions.length})'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đang giữ'),
                      if (heldTransactions.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${heldTransactions.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(text: 'Rút tiền (${withdrawals.length})'),
              ],
            ),
            SizedBox(
              height: transactions.isEmpty && heldTransactions.isEmpty ? 200 : 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionTab(state),
                  _buildHeldTab(heldTransactions),
                  _buildWithdrawalTab(withdrawals),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTab(WalletLoaded state) {
    final transactions = state.paginatedTransactions?.items ?? [];
    final paginated = state.paginatedTransactions;

    if (transactions.isEmpty) {
      return _buildEmpty('Chưa có giao dịch nào', Icons.receipt_long_outlined);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100 &&
            paginated?.hasNextPage == true &&
            !state.isLoadingMore) {
          context.read<WalletBloc>().add(LoadMoreTransactions());
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: transactions.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 72, endIndent: 16),
        itemBuilder: (context, index) {
          if (index >= transactions.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final tx = transactions[index];
          return _buildTransactionItem(tx);
        },
      ),
    );
  }

  Widget _buildTransactionItem(TransactionEntity tx) {
    final isIn = tx.flowDirection == 'In';
    final isHeld = tx.flowDirection == 'Held';
    final dateStr = DateFormat('dd/MM • HH:mm').format(tx.createdAt);

    Color iconColor;
    Color bgColor;
    IconData iconData;
    if (isIn) {
      iconColor = const Color(0xFF2E7D32);
      bgColor = const Color(0xFFE8F5E9);
      iconData = Icons.arrow_downward_rounded;
    } else if (isHeld) {
      iconColor = Colors.amber[700]!;
      bgColor = Colors.amber[50]!;
      iconData = Icons.lock_outlined;
    } else {
      iconColor = const Color(0xFFE65100);
      bgColor = const Color(0xFFFFF3E0);
      iconData = Icons.arrow_upward_rounded;
    }

    return InkWell(
      onTap: () => context.push('/wallet/transaction/${tx.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localizeType(tx.type),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.description?.isNotEmpty == true
                        ? tx.description!
                        : dateStr,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? "+" : isHeld ? "" : "-"}${_currencyFormatter.format(tx.amount.toInt())}đ',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIn
                        ? const Color(0xFF2E7D32)
                        : isHeld
                            ? Colors.amber[700]
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                _buildStatusChip(tx.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF2E7D32);
        break;
      case 'pending':
        color = Colors.amber[700]!;
        break;
      case 'failed':
        color = Colors.red[600]!;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _localizeStatus(status),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeldTab(List<HeldTransactionEntity> held) {
    if (held.isEmpty) {
      return _buildEmpty('Không có tiền đang giữ', Icons.lock_open_outlined);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: held.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final item = held[index];
        final dateStr = DateFormat('dd/MM/yyyy').format(item.date);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded, color: Colors.amber[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn hàng #${item.orderId.substring(0, 8)}',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.reason.isNotEmpty ? item.reason : 'Đang xử lý',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      dateStr,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_currencyFormatter.format(item.amount.toInt())}đ',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.orderStatus,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWithdrawalTab(List<WithdrawalEntity> withdrawals) {
    if (withdrawals.isEmpty) {
      return _buildEmpty('Không có lịch sử rút tiền', Icons.outbox_outlined);
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: withdrawals.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final item = withdrawals[index];
        final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt);
        
        Color statusColor;
        switch (item.status.toLowerCase()) {
          case 'completed': statusColor = const Color(0xFF2E7D32); break;
          case 'rejected': statusColor = Colors.red; break;
          default: statusColor = Colors.amber[700]!;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_rounded, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.bankName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.bankAccountName} • ${item.bankAccountNumber}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      dateStr,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_currencyFormatter.format(item.amount.toInt())}đ',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textHint.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<WalletBloc>().add(FetchTransactions()),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double balance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<WalletBloc>(),
        child: WithdrawDialog(availableBalance: balance),
      ),
    );
  }

  void _showPinOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quản lý mã PIN', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              ),
              title: const Text('Đổi mã PIN'),
              subtitle: const Text('Thay đổi PIN hiện tại'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wallet/pin-change');
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.help_outline, color: Color(0xFFE65100)),
              ),
              title: const Text('Quên mã PIN'),
              subtitle: const Text('Đặt lại qua OTP email'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wallet/pin-reset');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF2E7D32) : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  String _localizeStatus(String status) {
    switch (status) {
      case 'Completed': return 'Thành công';
      case 'Pending': return 'Đang xử lý';
      case 'Failed': return 'Thất bại';
      case 'Cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}
