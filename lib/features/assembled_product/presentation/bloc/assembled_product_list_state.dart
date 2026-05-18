import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';

enum AssembledProductListStatus { initial, loading, success, failure, loadingMore }

class AssembledProductListState extends Equatable {
  final List<AssembledProductEntity> products;
  final AssembledProductListStatus status;
  final int currentPage;
  final bool hasMore;
  final String? error;
  final String? searchQuery;

  const AssembledProductListState({
    this.products = const [],
    this.status = AssembledProductListStatus.initial,
    this.currentPage = 1,
    this.hasMore = true,
    this.error,
    this.searchQuery,
  });

  AssembledProductListState copyWith({
    List<AssembledProductEntity>? products,
    AssembledProductListStatus? status,
    int? currentPage,
    bool? hasMore,
    String? error,
    String? searchQuery,
  }) {
    return AssembledProductListState(
      products: products ?? this.products,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [products, status, currentPage, hasMore, error, searchQuery];
}
