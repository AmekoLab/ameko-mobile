import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/assembled_product/domain/repositories/assembled_product_repository.dart';
import 'assembled_product_detail_event.dart';
import 'assembled_product_detail_state.dart';

class AssembledProductDetailBloc extends Bloc<AssembledProductDetailEvent, AssembledProductDetailState> {
  final AssembledProductRepository repository;

  AssembledProductDetailBloc({required this.repository}) : super(const AssembledProductDetailState()) {
    on<FetchAssembledProductDetail>(_onFetch);
  }

  Future<void> _onFetch(FetchAssembledProductDetail event, Emitter<AssembledProductDetailState> emit) async {
    emit(state.copyWith(status: AssembledProductDetailStatus.loading));
    try {
      final product = await repository.getById(event.productId);
      emit(state.copyWith(status: AssembledProductDetailStatus.success, product: product));
    } catch (e) {
      emit(state.copyWith(status: AssembledProductDetailStatus.failure, error: e.toString()));
    }
  }
}
