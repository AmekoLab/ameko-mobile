import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/assembled_product/domain/repositories/assembled_product_repository.dart';
import 'assembled_product_list_event.dart';
import 'assembled_product_list_state.dart';

class AssembledProductListBloc extends Bloc<AssembledProductListEvent, AssembledProductListState> {
  final AssembledProductRepository repository;
  static const _pageSize = 10;

  AssembledProductListBloc({required this.repository}) : super(const AssembledProductListState()) {
    on<FetchAssembledProducts>(_onFetch);
    on<LoadMoreAssembledProducts>(_onLoadMore);
    on<RefreshAssembledProducts>(_onRefresh);
  }

  Future<void> _onFetch(FetchAssembledProducts event, Emitter<AssembledProductListState> emit) async {
    if (state.status == AssembledProductListStatus.success) return; // prevent double fetch
    emit(state.copyWith(status: AssembledProductListStatus.loading, currentPage: 1));
    try {
      final result = await repository.getAll(currentPage: 1, pageSize: _pageSize);
      emit(state.copyWith(
        status: AssembledProductListStatus.success,
        products: result.items,
        hasMore: result.hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(state.copyWith(status: AssembledProductListStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onLoadMore(LoadMoreAssembledProducts event, Emitter<AssembledProductListState> emit) async {
    if (!state.hasMore || state.status == AssembledProductListStatus.loadingMore) return;
    emit(state.copyWith(status: AssembledProductListStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final result = await repository.getAll(currentPage: nextPage, pageSize: _pageSize);
      emit(state.copyWith(
        status: AssembledProductListStatus.success,
        products: [...state.products, ...result.items],
        hasMore: result.hasMore,
        currentPage: nextPage,
      ));
    } catch (e) {
      emit(state.copyWith(status: AssembledProductListStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshAssembledProducts event, Emitter<AssembledProductListState> emit) async {
    emit(state.copyWith(status: AssembledProductListStatus.loading, currentPage: 1, products: []));
    try {
      final result = await repository.getAll(currentPage: 1, pageSize: _pageSize);
      emit(state.copyWith(
        status: AssembledProductListStatus.success,
        products: result.items,
        hasMore: result.hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(state.copyWith(status: AssembledProductListStatus.failure, error: e.toString()));
    }
  }
}
