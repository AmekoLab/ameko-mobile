import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/cart/domain/entities/cart_entity.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_event.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedItems = {};
  bool _isEditMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
      } else {
        _selectedItems.add(id);
      }
    });
  }

  void _toggleSelectAll(List<CartItemEntity> items) {
    setState(() {
      if (_selectedItems.length == items.length) {
        _selectedItems.clear();
      } else {
        _selectedItems.addAll(items.map((e) => e.orderItemId));
      }
    });
  }

  Future<void> _showQuantityDialog(CartItemEntity item) async {
    final controller = TextEditingController(text: item.quantity.toString());
    final newQty = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Quantity', style: AppTextStyles.titleSmall),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enter number',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(context, val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newQty != null && newQty != item.quantity && mounted) {
      context.read<CartBloc>().add(UpdateCartItemQuantity(itemId: item.orderItemId, quantity: newQty));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final count = state.cart?.items.length ?? 0;
            return Text(
              'Cart ($count)',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
            child: Text(
              _isEditMode ? 'Done' : 'Edit',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.status == CartStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final cart = state.cart;
          if (cart == null || cart.items.isEmpty) {
            return _buildEmptyCart();
          }

          final groupedItems = <String, List<CartItemEntity>>{};
          for (var item in cart.items) {
            groupedItems.putIfAbsent(item.shopId, () => []).add(item);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8),
                  children: [
                    ...groupedItems.entries.map((entry) => _buildShopSection(entry.value)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _buildBottomSection(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShopSection(List<CartItemEntity> items) {
    final shopName = items.first.shopName;
    final allShopSelected = items.every((i) => _selectedItems.contains(i.orderItemId));

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: allShopSelected,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedItems.addAll(items.map((e) => e.orderItemId));
                      } else {
                        for (var item in items) {
                          _selectedItems.remove(item.orderItemId);
                        }
                      }
                    });
                  },
                ),
                const Icon(Icons.storefront_outlined, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(shopName, style: AppTextStyles.titleSmall),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
                const Spacer(),
                if (!_isEditMode)
                  TextButton(
                    onPressed: () {},
                    child: Text('Edit', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...items.map((item) => _buildCartItem(item)),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItemEntity item) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final isSelected = _selectedItems.contains(item.orderItemId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            activeColor: AppColors.primary,
            onChanged: (val) => _toggleSelection(item.orderItemId),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: item.productImage ?? '',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.keyboard_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.body.copyWith(height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (item.isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Custom Build', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                        const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textHint),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${formatter.format(item.unitPrice.toInt())}đ',
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          _buildQtyBtn(Icons.remove, () {
                            if (item.quantity > 1) {
                              context.read<CartBloc>().add(UpdateCartItemQuantity(itemId: item.orderItemId, quantity: item.quantity - 1));
                            }
                          }),
                          InkWell(
                            onTap: () => _showQuantityDialog(item),
                            child: Container(
                              width: 32,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                border: Border.symmetric(vertical: BorderSide(color: AppColors.border)),
                              ),
                              child: Text('${item.quantity}', style: AppTextStyles.caption),
                            ),
                          ),
                          _buildQtyBtn(Icons.add, () {
                            context.read<CartBloc>().add(UpdateCartItemQuantity(itemId: item.orderItemId, quantity: item.quantity + 1));
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildBottomSection(CartEntity cart) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final selectedCount = _selectedItems.length;
    final allSelected = cart.items.isNotEmpty && selectedCount == cart.items.length;

    double selectedTotal = 0;
    for (var item in cart.items) {
      if (_selectedItems.contains(item.orderItemId)) {
        selectedTotal += item.totalPrice;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Vouchers Row
          _buildVoucherRow('Shop Voucher', 'Add or enter code', Icons.confirmation_number_outlined),
          const Divider(height: 1, color: AppColors.divider),
          _buildVoucherRow('Ameko Voucher', 'Select or enter code', Icons.local_activity_outlined),
          const Divider(height: 1, color: AppColors.divider),
          
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text('Select products to see discounts', style: AppTextStyles.caption),
                  const Spacer(),
                  const Icon(Icons.help_outline, size: 14, color: AppColors.textHint),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.divider),
          Row(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    activeColor: AppColors.primary,
                    onChanged: (val) => _toggleSelectAll(cart.items),
                  ),
                  Text('All', style: AppTextStyles.body),
                ],
              ),
              const Spacer(),
              if (!_isEditMode) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Total ', style: AppTextStyles.bodySecondary),
                        Text(
                          '${formatter.format(selectedTotal.toInt())}đ',
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: selectedCount > 0 ? () {
                    context.push('/checkout', extra: {
                      'itemIds': _selectedItems.toList(),
                      'total': selectedTotal,
                    });
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: selectedCount > 0 ? AppColors.primary : AppColors.textHint,
                    child: Text(
                      'Check Out ($selectedCount)',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: () {},
                  child: Text('Move to Likes', style: AppTextStyles.body.copyWith(color: AppColors.primary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  color: selectedCount > 0 ? AppColors.primary : AppColors.textHint,
                  child: Text(
                    'Delete ($selectedCount)',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherRow(String label, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.body),
          const Spacer(),
          Text(hint, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text('SHOP NOW', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}
