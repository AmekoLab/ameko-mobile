import 'package:equatable/equatable.dart';

abstract class AssembledProductListEvent extends Equatable {
  const AssembledProductListEvent();
  @override
  List<Object?> get props => [];
}

class FetchAssembledProducts extends AssembledProductListEvent {}

class LoadMoreAssembledProducts extends AssembledProductListEvent {}

class RefreshAssembledProducts extends AssembledProductListEvent {}
