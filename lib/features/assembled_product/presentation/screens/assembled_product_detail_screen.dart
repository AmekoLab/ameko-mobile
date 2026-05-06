import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/widgets/app_avatar_circle.dart';
import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_detail_bloc.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_detail_event.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_detail_state.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_event.dart';
import 'package:ameko_app/features/cart/presentation/bloc/cart_state.dart';
import 'package:ameko_app/core/widgets/app_snack_bar.dart';
import 'package:ameko_app/injection_container.dart';

class AssembledProductDetailScreen extends StatefulWidget {
  final String productId;

  const AssembledProductDetailScreen({super.key, required this.productId});

  @override
  State<AssembledProductDetailScreen> createState() => _AssembledProductDetailScreenState();
}

class _AssembledProductDetailScreenState extends State<AssembledProductDetailScreen> {
  late final AssembledProductDetailBloc _bloc;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AssembledProductDetailBloc>()
      ..add(FetchAssembledProductDetail(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider(create: (_) => sl<CartBloc>()),
      ],
      child: BlocListener<CartBloc, CartState>(
        listener: (context, cartState) {
          if (cartState.status == CartStatus.addedSuccessfully) {
            AppSnackBar.showSuccess(context, message: cartState.message ?? 'Đã thêm vào giỏ hàng');
          } else if (cartState.status == CartStatus.failure && cartState.error != null) {
            AppSnackBar.showError(context, message: cartState.error!);
          }
        },
        child: BlocBuilder<AssembledProductDetailBloc, AssembledProductDetailState>(
          builder: (context, state) {
            if (state.status == AssembledProductDetailStatus.loading) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }

            if (state.status == AssembledProductDetailStatus.failure) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(backgroundColor: AppColors.surface, leading: const BackButton()),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(state.error ?? 'Không thể tải sản phẩm', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _bloc.add(FetchAssembledProductDetail(widget.productId)),
                        child: Text('Thử lại', style: AppTextStyles.link),
                      ),
                    ],
                  ),
                ),
              );
            }

            final product = state.product;
            if (product == null) return const SizedBox.shrink();

            return _buildContent(context, product);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AssembledProductDetailEntity product) {
    final images = [product.image1, product.image2, product.image3]
        .where((u) => u != null && u.isNotEmpty)
        .cast<String>()
        .toList();
    final formatter = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Image gallery sliver
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isEmpty
                      ? _buildImagePlaceholder()
                      : Stack(
                          children: [
                            // Main image
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (i) => setState(() => _selectedImageIndex = i),
                              itemBuilder: (_, i) => CachedNetworkImage(
                                imageUrl: images[i],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
                                errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                              ),
                            ),
                            // Page indicator dots
                            if (images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    images.length,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: _selectedImageIndex == i ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _selectedImageIndex == i ? AppColors.primary : Colors.white70,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail row
                    if (images.length > 1)
                      SizedBox(
                        height: 72,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: images.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => setState(() => _selectedImageIndex = i),
                            child: Container(
                              width: 56,
                              height: 56,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedImageIndex == i ? AppColors.primary : AppColors.border,
                                  width: _selectedImageIndex == i ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: CachedNetworkImage(imageUrl: images[i], fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Main info card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price
                          Text(
                            '${formatter.format(product.price.toInt())}đ',
                            style: AppTextStyles.heading.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          // Name
                          Text(product.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 12),
                          // Stock badge
                          Row(
                            children: [
                              _buildBadge(
                                product.quantity > 0 ? 'Còn hàng' : 'Hết hàng',
                                product.quantity > 0 ? AppColors.primarySurface : AppColors.error.withValues(alpha: 0.1),
                                product.quantity > 0 ? AppColors.primary : AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              if (product.layout != null) _buildBadge(product.layout!, AppColors.surfaceVariant, AppColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (product.quantity > 0)
                            Text('Số lượng còn lại: ${product.quantity}',
                                style: AppTextStyles.caption),
                        ],
                      ),
                    ),

                    // Shop info card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          AppAvatarCircle(imageUrl: product.logoUrl, name: product.shopName, radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.shopName,
                                    style: AppTextStyles.titleSmall),
                                Text('Xem Shop', style: AppTextStyles.link.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textHint),
                        ],
                      ),
                    ),

                    // Specs card
                    _buildSpecsCard(product),

                    // Description card
                    if (product.description != null && product.description!.isNotEmpty)
                      _buildDescriptionCard(product.description!),

                    // Components card
                    if (product.details.isNotEmpty) _buildComponentsCard(product.details),

                    // Bottom padding for floating buttons
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Floating action buttons (Add to cart / Buy now)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: product.quantity == 0
                  ? SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Hết hàng', style: AppTextStyles.button.copyWith(color: AppColors.textHint)),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<CartBloc, CartState>(
                        builder: (context, cartState) {
                          return ElevatedButton(
                            onPressed: cartState.status == CartStatus.addingItem
                                ? null
                                : () {
                                    context.read<CartBloc>().add(AddItemToCart(
                                          productId: product.id,
                                          quantity: 1,
                                          isCustom: false,
                                        ));
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (cartState.status == CartStatus.addingItem)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                else
                                  const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('Thêm vào giỏ hàng', style: AppTextStyles.button.copyWith(color: Colors.white)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsCard(AssembledProductDetailEntity product) {
    final specs = <Map<String, String>>[];
    if (product.layout != null) specs.add({'key': 'Layout', 'value': product.layout!});
    if (product.mounting != null) specs.add({'key': 'Mounting', 'value': product.mounting!});
    if (product.pcb != null) specs.add({'key': 'PCB', 'value': product.pcb!});
    if (product.connection != null) specs.add({'key': 'Connection', 'value': product.connection!});
    if (product.battery != null) specs.add({'key': 'Battery', 'value': product.battery!});
    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông số kỹ thuật', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          ...specs.asMap().entries.map((e) => Column(
            children: [
              if (e.key > 0) Divider(color: AppColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(e.value['key']!, style: AppTextStyles.bodySecondary)),
                    Expanded(
                      flex: 3,
                      child: Text(e.value['value']!,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mô tả', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          Text(description, style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }

  Widget _buildComponentsCard(List<AssembledProductDetailItem> details) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Thành phần cấu tạo', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...details.asMap().entries.map((e) {
            final d = e.value;
            return Column(
              children: [
                if (e.key > 0) Divider(color: AppColors.divider, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.keyboard_outlined, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.componentName ?? d.baseKitName ?? 'Component',
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (d.baseKitName != null && d.componentName != null)
                              Text(d.baseKitName!, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Text(
                        'x${d.quantity}',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(child: Icon(Icons.keyboard_alt_outlined, size: 64, color: AppColors.textHint)),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}
