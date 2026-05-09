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
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_state.dart';

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
    // Update voucher preview if any vouchers are selected
    _updateVoucherPreview();
  }

  void _updateVoucherPreview() {
    final checkoutBloc = context.read<CheckoutBloc>();
    // Call preview calculation regardless of voucher selection to sync with backend prices
    checkoutBloc.add(CalculatePreview(_selectedItems.toList()));
  }

  void _toggleSelectAll(List<CartItemEntity> items) {
    setState(() {
      if (_selectedItems.length == items.length) {
        _selectedItems.clear();
      } else {
        _selectedItems.addAll(items.map((e) => e.orderItemId));
      }
    });
    _updateVoucherPreview();
  }

  Future<void> _showQuantityDialog(CartItemEntity item) async {
    final controller = TextEditingController(text: item.quantity.toString());
    final newQty = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật số lượng', style: AppTextStyles.titleSmall),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nhập số lượng',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(context, val);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
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
              'Giỏ hàng ($count)',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
            child: Text(
              _isEditMode ? 'Xong' : 'Sửa',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CartBloc, CartState>(
            listenWhen: (prev, curr) => prev.status != curr.status && curr.status == CartStatus.success,
            listener: (context, state) {
              if (_selectedItems.isNotEmpty) {
                _updateVoucherPreview();
              }
            },
          ),
          BlocListener<CheckoutBloc, CheckoutState>(
            listenWhen: (prev, curr) => prev.message != curr.message && curr.message != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            },
          ),
        ],
        child: BlocBuilder<CartBloc, CartState>(
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
                    _buildSelectAllHeader(cart),
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
    ),
  );
}

  Widget _buildSelectAllHeader(CartEntity cart) {
    final selectedCount = _selectedItems.length;
    final allSelected = cart.items.isNotEmpty && selectedCount == cart.items.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            activeColor: AppColors.primary,
            onChanged: (val) => _toggleSelectAll(cart.items),
          ),
          Text(
            'Chọn tất cả (${cart.items.length} sản phẩm)',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
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
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textHint),
                    onPressed: () {
                      // Delete all items from this shop
                      context.read<CartBloc>().add(
                        RemoveCartItems(items.map((e) => e.orderItemId).toList()),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...items.map((item) => _buildCartItem(item)),
          
          // Shop Voucher Row for this shop
          BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, state) {
              final shopId = items.first.shopId;
              final selectedCode = state.appliedShopVoucherCodes[shopId];
              
              // Find shop preview for this shop to show discounts/shipping
              final shopPreview = state.shopPreviews.isEmpty 
                  ? null 
                  : state.shopPreviews.where((p) => p.shopId == shopId).firstOrNull;

              final formatter = NumberFormat('#,###', 'vi_VN');

              return Column(
                children: [
                  if (shopPreview != null && (shopPreview.shopDiscountAmount > 0 || shopPreview.shippingFee > 0))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          if (shopPreview.shopDiscountAmount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Giảm giá từ Shop', style: AppTextStyles.caption.copyWith(color: Colors.red)),
                                Text('-${formatter.format(shopPreview.shopDiscountAmount.toInt())}đ', 
                                    style: AppTextStyles.caption.copyWith(color: Colors.red)),
                              ],
                            ),
                          if (shopPreview.shippingFee > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Phí vận chuyển', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                Text('+${formatter.format(shopPreview.shippingFee.toInt())}đ', 
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  _buildVoucherRow(
                    'Voucher Shop',
                    selectedCode ?? 'Thêm voucher',
                    Icons.confirmation_number_outlined,
                    onTap: () => _showVoucherBottomSheet(context, showSystem: false, shopId: shopId),
                  ),
                ],
              );
            },
          ),
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
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return _buildBottomSectionContent(cart, state);
      },
    );
  }

  Widget _buildBottomSectionContent(CartEntity cart, CheckoutState state) {
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
          // Ameko Voucher Row (Only System)
          _buildVoucherRow(
            'Voucher Ameko',
            state.appliedSystemVoucherCode != null ? 'Đã áp dụng: ${state.appliedSystemVoucherCode}' : 'Thêm voucher',
            Icons.local_activity_outlined,
            onTap: () => _showVoucherBottomSheet(context, showShop: false),
          ),
          const Divider(height: 1, color: AppColors.divider),
          
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text('Chọn sản phẩm để xem khuyến mãi', style: AppTextStyles.caption),
                  const Spacer(),
                  const Icon(Icons.help_outline, size: 14, color: AppColors.textHint),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                if (!_isEditMode) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedCount > 0 && (state.shippingFee > 0 || state.discountAmount > 0))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (state.discountAmount > 0)
                                Text(
                                  '-${formatter.format(state.discountAmount.toInt())}đ Giảm giá ',
                                  style: AppTextStyles.caption.copyWith(color: Colors.red),
                                ),
                              if (state.shippingFee > 0)
                                Text(
                                  '+${formatter.format(state.shippingFee.toInt())}đ Phí ship',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Tổng cộng ', style: AppTextStyles.bodySecondary),
                            Flexible(
                              child: Text(
                                '${formatter.format((selectedCount > 0 ? state.calculatedTotalAmount : 0.0).toInt())}đ',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: selectedCount > 0
                        ? () {
                            context.push('/checkout', extra: {
                              'itemIds': _selectedItems.toList(),
                              'total': selectedTotal,
                              'systemVoucherCode': state.appliedSystemVoucherCode,
                              'shopVoucherCodes': state.appliedShopVoucherCodes,
                            });
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedCount > 0 ? AppColors.primary : AppColors.textHint,
                      ),
                      constraints: const BoxConstraints(minWidth: 120),
                      alignment: Alignment.center,
                      child: Text(
                        'Thanh toán ($selectedCount)',
                        style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Lưu vào yêu thích',
                        style: AppTextStyles.body.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: selectedCount > 0 ? () {} : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: selectedCount > 0 ? AppColors.primary : AppColors.textHint,
                      ),
                      child: Text(
                        'Xóa ($selectedCount)',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherRow(String label, String hint, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }

  void _showVoucherBottomSheet(BuildContext context, {bool showSystem = true, bool showShop = true, String? shopId}) {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn sản phẩm trước khi áp dụng Voucher')),
      );
      return;
    }

    final checkoutBloc = context.read<CheckoutBloc>();
    checkoutBloc.add(FetchApplicableVouchers());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: checkoutBloc,
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      shopId != null ? 'Voucher của Shop' : (showShop && !showSystem ? 'Shop Vouchers' : (showSystem && !showShop ? 'Ameko Vouchers' : 'Chọn Voucher')),
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<CheckoutBloc, CheckoutState>(
                        builder: (context, state) {
                          if (state.applicableVouchers == null) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final vouchers = state.applicableVouchers!;
                          
                          // Filter shop groups if a specific shopId is provided
                          final filteredShopGroups = shopId != null
                              ? vouchers.shopVoucherGroups.where((g) => g.shopId == shopId).toList()
                              : vouchers.shopVoucherGroups;

                          return ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (showSystem) ...[
                                if (state.systemVoucherError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(state.systemVoucherError!,
                                        style: const TextStyle(color: Colors.red)),
                                  ),
                                Text('Voucher của hệ thống', style: AppTextStyles.titleSmall),
                                ...vouchers.systemVouchers.map((v) {
                                  final isSelected = state.appliedSystemVoucherCode == v.code;
                                  return CheckboxListTile(
                                    title: Text(v.code),
                                    value: isSelected,
                                    onChanged: (selected) {
                                      checkoutBloc.add(
                                        SelectVoucher(
                                          selectedOrderItemIds: _selectedItems.toList(),
                                          systemVoucherCode: selected == true ? v.code : null,
                                          shopVoucherCodes: state.appliedShopVoucherCodes,
                                        ),
                                      );
                                    },
                                  );
                                }),
                                const Divider(),
                              ],
                              if (showShop) ...[
                                if (filteredShopGroups.isEmpty && shopId != null)
                                  const Center(child: Text('Shop này hiện chưa có Voucher khả dụng')),
                                if (filteredShopGroups.isNotEmpty) ...[
                                  Text('Voucher của Shop', style: AppTextStyles.titleSmall),
                                  ...filteredShopGroups.map((g) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(g.shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        ...g.vouchers.map((v) {
                                          final isSelected = state.appliedShopVoucherCodes[g.shopId] == v.code;
                                          return CheckboxListTile(
                                            title: Text(v.code),
                                            value: isSelected,
                                            onChanged: (selected) {
                                              final newShopVouchers = Map<String, String>.from(state.appliedShopVoucherCodes);
                                              if (selected == true) {
                                                newShopVouchers[g.shopId] = v.code;
                                              } else {
                                                newShopVouchers.remove(g.shopId);
                                              }
                                              checkoutBloc.add(
                                                SelectVoucher(
                                                  selectedOrderItemIds: _selectedItems.toList(),
                                                  systemVoucherCode: state.appliedSystemVoucherCode,
                                                  shopVoucherCodes: newShopVouchers,
                                                ),
                                              );
                                            },
                                          );
                                        })
                                      ],
                                    );
                                  }),
                                ],
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Xong'),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Giỏ hàng của bạn đang trống', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text('MUA SẮM NGAY', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}
