import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_search_bloc.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_search_event.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_search_state.dart';
import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';

class AssembledProductSearchScreen extends StatefulWidget {
  const AssembledProductSearchScreen({super.key});

  @override
  State<AssembledProductSearchScreen> createState() => _AssembledProductSearchScreenState();
}

class _AssembledProductSearchScreenState extends State<AssembledProductSearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      context.read<AssembledProductSearchBloc>().add(LoadMoreSearch());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                context.read<AssembledProductSearchBloc>().add(SearchTermChanged(value));
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bàn phím...',
                hintStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<AssembledProductSearchBloc, AssembledProductSearchState>(
        builder: (context, state) {
          if (state.status == SearchStatus.loading && state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state.status == SearchStatus.failure && state.products.isEmpty) {
            return Center(child: Text(state.errorMessage ?? 'Có lỗi xảy ra', style: AppTextStyles.bodySecondary));
          }

          if (state.status == SearchStatus.success && state.products.isEmpty) {
            return const Center(child: Text('Không tìm thấy sản phẩm nào'));
          }

          return Column(
            children: [
              if (state.products.isNotEmpty)
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: state.products.length + (state.hasNextPage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.products.length) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
                      }
                      final product = state.products[index];
                      return _ProductSearchCard(product: product);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AssembledProductSearchBloc>(),
        child: const _SearchFilterSheet(),
      ),
    );
  }
}

class _ProductSearchCard extends StatelessWidget {
  final AssembledProductEntity product;
  const _ProductSearchCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    return GestureDetector(
      onTap: () => context.push('/assembled-products/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.image1 != null
                    ? CachedNetworkImage(
                        imageUrl: product.image1!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant),
                      )
                    : Container(color: AppColors.surfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(product.rating.toString(), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(${product.totalReviews})', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${formatter.format(product.price.toInt())}đ',
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet();

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  double? _minPrice;
  double? _maxPrice;
  String? _layout;
  String? _mounting;
  String? _connection;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    final state = context.read<AssembledProductSearchBloc>().state;
    _minPrice = state.minPrice;
    _maxPrice = state.maxPrice;
    _layout = state.layout;
    _mounting = state.mounting;
    _connection = state.connection;
    _minRating = state.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bộ lọc', style: AppTextStyles.subheading),
              TextButton(
                onPressed: () {
                  context.read<AssembledProductSearchBloc>().add(ClearFilters());
                  Navigator.pop(context);
                },
                child: const Text('Xóa tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Khoảng giá (đ)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Tối thiểu'),
                  onChanged: (v) => _minPrice = double.tryParse(v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Tối đa'),
                  onChanged: (v) => _maxPrice = double.tryParse(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Layout', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['60%', '65%', '75%', 'Fullsize', 'TKL'].map((l) {
              final isSelected = _layout == l;
              return ChoiceChip(
                label: Text(l),
                selected: isSelected,
                onSelected: (v) => setState(() => _layout = v ? l : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Đánh giá tối thiểu', style: AppTextStyles.label),
          Slider(
            value: _minRating ?? 0,
            min: 0,
            max: 5,
            divisions: 5,
            label: _minRating?.toString() ?? '0',
            onChanged: (v) => setState(() => _minRating = v > 0 ? v : null),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<AssembledProductSearchBloc>().add(FiltersChanged(
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                      layout: _layout,
                      mounting: _mounting,
                      connection: _connection,
                      minRating: _minRating,
                    ));
                Navigator.pop(context);
              },
              child: Text('Áp dụng', style: AppTextStyles.button.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
