import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:ameko_app/features/assembled_product/domain/repositories/assembled_product_repository.dart';
import 'assembled_product_search_event.dart';
import 'assembled_product_search_state.dart';

class AssembledProductSearchBloc
    extends Bloc<AssembledProductSearchEvent, AssembledProductSearchState> {
  final AssembledProductRepository repository;

  AssembledProductSearchBloc({required this.repository})
      : super(const AssembledProductSearchState()) {
    on<SearchTermChanged>(
      _onSearchTermChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 500))
          .switchMap(mapper),
    );
    on<FiltersChanged>(_onFiltersChanged);
    on<LoadMoreSearch>(_onLoadMoreSearch);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onSearchTermChanged(
    SearchTermChanged event,
    Emitter<AssembledProductSearchState> emit,
  ) async {
    emit(state.copyWith(
      status: SearchStatus.loading,
      searchTerm: event.searchTerm,
      currentPage: 1,
    ));
    await _performSearch(emit);
  }

  Future<void> _onFiltersChanged(
    FiltersChanged event,
    Emitter<AssembledProductSearchState> emit,
  ) async {
    emit(state.copyWith(
      status: SearchStatus.loading,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      layout: event.layout,
      mounting: event.mounting,
      pcb: event.pcb,
      connection: event.connection,
      battery: event.battery,
      minRating: event.minRating,
      currentPage: 1,
    ));
    await _performSearch(emit);
  }

  Future<void> _onLoadMoreSearch(
    LoadMoreSearch event,
    Emitter<AssembledProductSearchState> emit,
  ) async {
    if (state.status == SearchStatus.loading || !state.hasNextPage) return;

    final nextPage = state.currentPage + 1;
    try {
      final result = await repository.search(
        searchTerm: state.searchTerm,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        layout: state.layout,
        mounting: state.mounting,
        pcb: state.pcb,
        connection: state.connection,
        battery: state.battery,
        minRating: state.minRating,
        pageNumber: nextPage,
      );

      emit(state.copyWith(
        products: [...state.products, ...result.items],
        currentPage: nextPage,
        hasNextPage: result.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<AssembledProductSearchState> emit,
  ) async {
    emit(const AssembledProductSearchState(status: SearchStatus.loading));
    await _performSearch(emit);
  }

  Future<void> _performSearch(Emitter<AssembledProductSearchState> emit) async {
    try {
      final result = await repository.search(
        searchTerm: state.searchTerm,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        layout: state.layout,
        mounting: state.mounting,
        pcb: state.pcb,
        connection: state.connection,
        battery: state.battery,
        minRating: state.minRating,
        pageNumber: 1,
      );

      emit(state.copyWith(
        status: SearchStatus.success,
        products: result.items,
        currentPage: 1,
        hasNextPage: result.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SearchStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
