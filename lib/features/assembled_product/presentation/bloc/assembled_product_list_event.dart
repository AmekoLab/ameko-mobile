import 'package:equatable/equatable.dart';

abstract class AssembledProductListEvent extends Equatable {
  const AssembledProductListEvent();
  @override
  List<Object?> get props => [];
}

class FetchAssembledProducts extends AssembledProductListEvent {}

class LoadMoreAssembledProducts extends AssembledProductListEvent {}

class RefreshAssembledProducts extends AssembledProductListEvent {}
 
class SearchAssembledProducts extends AssembledProductListEvent {
  final String query;
  const SearchAssembledProducts(this.query);

  @override
  List<Object?> get props => [query];
}
