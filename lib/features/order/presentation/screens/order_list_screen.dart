import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/widgets/app_card.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ameko_app/features/order/domain/entities/order_entity.dart';
import 'package:ameko_app/features/order/presentation/bloc/order_bloc.dart';
import 'package:ameko_app/features/order/presentation/bloc/order_event.dart';
import 'package:ameko_app/features/order/presentation/bloc/order_state.dart';
import 'package:ameko_app/injection_container.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _shopTabController;
  late TabController _purchasesTabController;
  final OrderBloc _orderBloc = sl<OrderBloc>();

  final List<String> _shopStatusLabels = [
    'Chờ xử lý', 'Đang xử lý', 'Đang giao', 
    'Hoàn thành', 'Đã hủy', 'Đang trả hàng', 'Đã trả hàng', 'Đã hoàn tiền'
  ];

  // Map shop tab index to actual status ID (skipping 1: InCart)
  final List<int> _shopStatusIds = [0, 2, 3, 4, 5, 6, 7, 8];

  final List<String> _purchasesStatusLabels = [
    'Đang xử lý', 'Hoàn thành', 'Đã hủy'
  ];

  // Map purchases tab index to actual status ID
  final List<int> _purchasesStatusIds = [2, 4, 5];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _shopTabController = TabController(length: 8, vsync: this);
    _purchasesTabController = TabController(length: 3, vsync: this);
    
    _loadData();
    
    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) return;
      _loadData();
    });

    _shopTabController.addListener(() {
      if (_shopTabController.indexIsChanging) return;
      if (_mainTabController.index == 1) {
        _orderBloc.add(ShopOrdersFetched(status: _shopStatusIds[_shopTabController.index]));
      }
    });

    _purchasesTabController.addListener(() {
      if (_purchasesTabController.indexIsChanging) return;
      if (_mainTabController.index == 0) {
        _orderBloc.add(MyOrdersFetched(status: _purchasesStatusIds[_purchasesTabController.index]));
      }
    });
  }

  void _loadData() {
    if (_mainTabController.index == 0) {
      _orderBloc.add(MyOrdersFetched(status: _purchasesStatusIds[_purchasesTabController.index]));
    } else {
      _orderBloc.add(ShopOrdersFetched(status: _shopStatusIds[_shopTabController.index]));
    }
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _shopTabController.dispose();
    _purchasesTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _orderBloc,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final role = (authState is AuthSuccess) ? authState.user.role?.toLowerCase() ?? '' : '';
          final isShop = role.contains('shop');

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: Column(
                children: [
                  Text('Đơn hàng', style: AppTextStyles.headingMedium),
                ],
              ),
              centerTitle: true,
              actions: [
                _buildSortButton(context),
              ],
              bottom: isShop
                  ? _buildMainTabBar()
                  : null,
            ),
            body: isShop
                ? TabBarView(
                    controller: _mainTabController,
                    children: [
                      _PurchasesManagementView(
                        tabController: _purchasesTabController,
                        statusLabels: _purchasesStatusLabels,
                      ),
                      _ShopManagementView(
                        tabController: _shopTabController,
                        statusLabels: _shopStatusLabels,
                      ),
                    ],
                  )
                : _PurchasesManagementView(
                    tabController: _purchasesTabController,
                    statusLabels: _purchasesStatusLabels,
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildMainTabBar() {
    return TabBar(
      controller: _mainTabController,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      labelColor: AppColors.primary,
      labelStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelColor: AppColors.textSecondary,
      tabs: const [
        Tab(text: 'Mua sắm'),
        Tab(text: 'Cửa hàng'),
      ],
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        final currentSort = state is OrderLoaded ? state.sortByPrice : PriceSort.none;
        return PopupMenuButton<PriceSort>(
          icon: Icon(
            currentSort == PriceSort.none ? Icons.sort : Icons.filter_list,
            color: currentSort == PriceSort.none ? AppColors.textPrimary : AppColors.primary,
          ),
          onSelected: (sort) => context.read<OrderBloc>().add(OrderSortChanged(sort)),
          itemBuilder: (context) => [
            const PopupMenuItem(value: PriceSort.none, child: Text('Mặc định (Mới nhất)')),
            const PopupMenuItem(value: PriceSort.lowToHigh, child: Text('Giá: Thấp đến Cao')),
            const PopupMenuItem(value: PriceSort.highToLow, child: Text('Giá: Cao đến Thấp')),
          ],
        );
      },
    );
  }
}

class _PurchasesManagementView extends StatelessWidget {
  final TabController tabController;
  final List<String> statusLabels;

  const _PurchasesManagementView({
    required this.tabController,
    required this.statusLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: tabController,
            isScrollable: false,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTextStyles.bodySmall,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: statusLabels.map((label) => Tab(text: label)).toList(),
          ),
        ),
        // Centralized view driven by Bloc state
        const Expanded(
          child: _OrdersView(isShopView: false),
        ),
      ],
    );
  }
}

class _ShopManagementView extends StatelessWidget {
  final TabController tabController;
  final List<String> statusLabels;

  const _ShopManagementView({
    required this.tabController,
    required this.statusLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: statusLabels.map((label) => Tab(text: label)).toList(),
          ),
        ),
        // Centralized view driven by Bloc state
        const Expanded(
          child: _OrdersView(isShopView: true),
        ),
      ],
    );
  }
}

class _OrdersView extends StatelessWidget {
  final bool isShopView;
  const _OrdersView({required this.isShopView});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OrderFailure) {
          return _buildErrorState(context, state.message);
        }
        if (state is OrderLoaded) {
          return _buildOrderList(context, state);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: () => _refresh(context), child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, OrderLoaded state) {
    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('Chưa có đơn hàng nào', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _refresh(context),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: state.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _MinimalistOrderCard(
          order: state.orders[index],
          isShopView: isShopView,
        ),
      ),
    );
  }

  void _refresh(BuildContext context) {
    final bloc = context.read<OrderBloc>();
    final state = bloc.state;
    if (state is OrderLoaded && state.isShopOrders) {
      bloc.add(ShopOrdersFetched(status: state.currentStatus));
    } else {
      bloc.add(const MyOrdersFetched());
    }
  }
}

class _MinimalistOrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isShopView;
  const _MinimalistOrderCard({
    required this.order,
    required this.isShopView,
  });

  @override
  Widget build(BuildContext context) {
    final firstItem = order.orderItems.isNotEmpty 
        ? order.orderItems.first 
        : null;

    return AppCard(
      onTap: () => context.push('/orders/${order.orderId}', extra: order),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Shop Name + Status)
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.shopName,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // 2. Product Info (Image + Details)
          if (firstItem != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image (Reduced to 60x60)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: firstItem.productImage != null
                        ? Image.network(firstItem.productImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 20, color: AppColors.textHint))
                        : const Icon(Icons.image_outlined, size: 20, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(width: 10),
                // Product Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem.productName,
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (firstItem.note != null && firstItem.note!.isNotEmpty)
                        Text(
                          firstItem.note!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'x${firstItem.quantity}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(firstItem.unitPrice),
                            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

          if (order.orderItems.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(child: Text('Thêm ${order.orderItems.length - 1} sản phẩm', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary))),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // 3. Footer (Summary Count + Total Amount)
          Align(
            alignment: Alignment.centerRight,
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'Tổng số tiền (${order.orderItems.length} sản phẩm): ', style: const TextStyle(fontSize: 11)),
                  TextSpan(
                    text: NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.totalAmount),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Action Buttons (Compact height)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                _buildActionButton(
                  label: 'Chi tiết',
                  onPressed: () => context.push('/orders/${order.orderId}', extra: order),
                  isPrimary: false,
                ),
                if (!isShopView && order.orderStatus.toLowerCase() == 'completed') // Show Repurchase only for completed orders
                  _buildActionButton(
                    label: 'Mua lại',
                    onPressed: () {
                      if (order.orderItems.isNotEmpty) {
                        final item = order.orderItems.first;
                        final productId = item.assembledProductId ?? item.productId;
                        context.push('/assembled-products/$productId');
                      }
                    },
                    isPrimary: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 30, // Reduced from 36
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Text(
      status.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'incart':
      case 'in cart': return Colors.grey;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.cyan;
      case 'completed': return AppColors.primary;
      case 'cancelled': return Colors.red;
      case 'returning': return Colors.indigo;
      case 'returned': return Colors.teal;
      case 'refunded': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
