import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';

enum SearchStatus { initial, loading, success, failure }

class AssembledProductSearchState extends Equatable {
  final SearchStatus status;
  final List<AssembledProductEntity> products;
  final String? searchTerm;
  final double? minPrice;
  final double? maxPrice;
  final String? layout;
  final String? mounting;
  final String? pcb;
  final String? connection;
  final String? battery;
  final double? minRating;
  final int currentPage;
  final bool hasNextPage;
  final String? errorMessage;

  const AssembledProductSearchState({
    this.status = SearchStatus.initial,
    this.products = const [],
    this.searchTerm,
    this.minPrice,
    this.maxPrice,
    this.layout,
    this.mounting,
    this.pcb,
    this.connection,
    this.battery,
    this.minRating,
    this.currentPage = 1,
    this.hasNextPage = false,
    this.errorMessage,
  });

  AssembledProductSearchState copyWith({
    SearchStatus? status,
    List<AssembledProductEntity>? products,
    String? searchTerm,
    double? minPrice,
    double? maxPrice,
    String? layout,
    String? mounting,
    String? pcb,
    String? connection,
    String? battery,
    double? minRating,
    int? currentPage,
    bool? hasNextPage,
    String? errorMessage,
  }) {
    return AssembledProductSearchState(
      status: status ?? this.status,
      products: products ?? this.products,
      searchTerm: searchTerm ?? this.searchTerm,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      layout: layout ?? this.layout,
      mounting: mounting ?? this.mounting,
      pcb: pcb ?? this.pcb,
      connection: connection ?? this.connection,
      battery: battery ?? this.battery,
      minRating: minRating ?? this.minRating,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        searchTerm,
        minPrice,
        maxPrice,
        layout,
        mounting,
        pcb,
        connection,
        battery,
        minRating,
        currentPage,
        hasNextPage,
        errorMessage,
      ];
}
