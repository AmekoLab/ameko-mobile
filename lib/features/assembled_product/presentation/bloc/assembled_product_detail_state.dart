import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';

enum AssembledProductDetailStatus { initial, loading, success, failure }

class AssembledProductDetailState extends Equatable {
  final AssembledProductDetailEntity? product;
  final AssembledProductDetailStatus status;
  final String? error;

  const AssembledProductDetailState({
    this.product,
    this.status = AssembledProductDetailStatus.initial,
    this.error,
  });

  AssembledProductDetailState copyWith({
    AssembledProductDetailEntity? product,
    AssembledProductDetailStatus? status,
    String? error,
  }) {
    return AssembledProductDetailState(
      product: product ?? this.product,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [product, status, error];
}
