import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/widgets/app_card.dart';
import 'package:ameko_app/core/widgets/app_divider.dart';
import 'package:ameko_app/features/order/domain/entities/order_entity.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.order});
  final String orderId;
  final OrderEntity? order;

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final entity = order!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Text('Order Details', style: AppTextStyles.headingMedium),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(entity),
              const SizedBox(height: 20),
              _buildSectionTitle('Shipping Information'),
              const SizedBox(height: 12),
              _buildShippingInfo(entity),
              const SizedBox(height: 20),
              _buildSectionTitle('Order Items'),
              const SizedBox(height: 12),
              _buildItemsCard(entity),
              const SizedBox(height: 20),
              _buildSectionTitle('Shop'),
              const SizedBox(height: 12),
              _buildShopCard(entity),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildHeader(OrderEntity order) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID: #${order.orderId.substring(0, 8)}', style: AppTextStyles.titleSmall),
              _StatusBadge(status: order.orderStatus),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMMM d, yyyy · h:mm a').format(order.createdAt),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo(OrderEntity order) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person_outline, 'Receiver', order.receiverName),
          const Divider(height: 24),
          _infoRow(Icons.phone_outlined, 'Phone', order.receiverPhone),
          const Divider(height: 24),
          _infoRow(Icons.location_on_outlined, 'Address', order.shippingAddress),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard(OrderEntity order) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return AppCard(
      child: Column(
        children: [
          ...order.orderItems.map((item) => _ItemRow(item: item)),
          const Divider(height: 32),
          _summaryRow('Subtotal', currencyFormat.format(order.subTotal)),
          const SizedBox(height: 8),
          _summaryRow('Shipping', currencyFormat.format(order.shippingFee)),
          const SizedBox(height: 8),
          _summaryRow('Discount', '-${currencyFormat.format(order.discountAmount)}', isDiscount: true),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(
                currencyFormat.format(order.totalAmount),
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodySmall.copyWith(
          color: isDiscount ? Colors.red : AppColors.textPrimary,
          fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
        )),
      ],
    );
  }

  Widget _buildShopCard(OrderEntity order) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primarySurface,
            radius: 24,
            backgroundImage: order.shopAvatar != null ? NetworkImage(order.shopAvatar!) : null,
            child: order.shopAvatar == null 
                ? const Icon(Icons.store_outlined, color: AppColors.primary, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.shopName, style: AppTextStyles.titleSmall),
                Text('View Shop Profiles', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              image: item.productImage != null ? DecorationImage(image: NetworkImage(item.productImage!), fit: BoxFit.cover) : null,
            ),
            child: item.productImage == null 
                ? const Icon(Icons.image_outlined, size: 24, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${currencyFormat.format(item.unitPrice)} × ${item.quantity}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(currencyFormat.format(item.totalPrice), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: _getStatusColor(status), fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing': return Colors.blue;
      case 'paid': return Colors.green;
      case 'delivered': return AppColors.primary;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
