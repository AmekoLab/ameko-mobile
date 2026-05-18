import 'package:equatable/equatable.dart';

abstract class AssembledProductDetailEvent extends Equatable {
  const AssembledProductDetailEvent();
  @override
  List<Object?> get props => [];
}

class FetchAssembledProductDetail extends AssembledProductDetailEvent {
  final String productId;
  const FetchAssembledProductDetail(this.productId);
  @override
  List<Object?> get props => [productId];
}
