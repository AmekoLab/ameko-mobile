import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_event.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'dart:async';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/widgets/app_avatar_circle.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_bloc.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_event.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_state.dart';

class AssembledProductListScreen extends StatefulWidget {
  const AssembledProductListScreen({super.key});

  @override
  State<AssembledProductListScreen> createState() => _AssembledProductListScreenState();
}

class _AssembledProductListScreenState extends State<AssembledProductListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<AssembledProductListBloc>().add(FetchAssembledProducts());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AssembledProductListBloc>().add(SearchAssembledProducts(query));
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final current = _scrollCtrl.offset;
    if (current >= maxScroll * 0.9) {
      context.read<AssembledProductListBloc>().add(LoadMoreAssembledProducts());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = authState is AuthSuccess
            ? (authState.user.fullName ?? authState.user.username)
            : 'User';
        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<AssembledProductListBloc>().add(RefreshAssembledProducts());
            },
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                _buildSliverAppBar(context, userName, l10n),
                _buildFeaturedBanner(l10n),
                _buildSectionHeader(l10n),
                _buildProductGrid(l10n),
                _buildLoadingFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String userName, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${l10n.hello} 👋', style: AppTextStyles.bodySecondary),
                        const SizedBox(height: 2),
                        Text(userName,
                            style: AppTextStyles.headingMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/cart'),
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner(AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background pattern dots
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Custom Keyboard',
                        style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.discoverKeyboards,
                    style: AppTextStyles.headingMedium.copyWith(color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l10n.exploreNow,
                        style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.featuredProducts, style: AppTextStyles.subheading),
            TextButton(
              onPressed: () {},
              child: Text(l10n.seeAll, style: AppTextStyles.link),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(AppLocalizations l10n) {
    return BlocBuilder<AssembledProductListBloc, AssembledProductListState>(
      builder: (context, state) {
        if (state.status == AssembledProductListStatus.loading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (state.status == AssembledProductListStatus.failure && state.products.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('Could not load products', style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<AssembledProductListBloc>().add(RefreshAssembledProducts()),
                    child: Text('Try again', style: AppTextStyles.link),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.products.isEmpty) {
          return SliverFillRemaining(
            child: Center(child: Text('No products found', style: AppTextStyles.bodySecondary)),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = state.products[index];
                return _ProductCard(
                  product: product,
                  onTap: () => context.push('/assembled-products/${product.id}', extra: product),
                );
              },
              childCount: state.products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingFooter() {
    return BlocBuilder<AssembledProductListBloc, AssembledProductListState>(
      builder: (context, state) {
        if (state.status == AssembledProductListStatus.loadingMore) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox(height: 20));
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final AssembledProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'en_US');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildProductImage(product.image1),
                    // Layout badge
                    if (product.layout != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.layout!,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    // Out of stock overlay
                    if (product.quantity == 0)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Out of stock',
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Product info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    // Shop info row
                    Row(
                      children: [
                        AppAvatarCircle(imageUrl: product.logoUrl, name: product.shopName, radius: 8),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.shopName,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Price
                    Text(
                      '${formatter.format(product.price.toInt())}đ',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.surfaceVariant,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.keyboard_alt_outlined, size: 40, color: AppColors.textHint),
      ),
    );
  }
}
