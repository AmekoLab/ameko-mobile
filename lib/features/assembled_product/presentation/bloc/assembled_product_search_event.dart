import 'package:equatable/equatable.dart';

abstract class AssembledProductSearchEvent extends Equatable {
  const AssembledProductSearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchTermChanged extends AssembledProductSearchEvent {
  final String? searchTerm;
  const SearchTermChanged(this.searchTerm);

  @override
  List<Object?> get props => [searchTerm];
}

class FiltersChanged extends AssembledProductSearchEvent {
  final double? minPrice;
  final double? maxPrice;
  final String? layout;
  final String? mounting;
  final String? pcb;
  final String? connection;
  final String? battery;
  final double? minRating;

  const FiltersChanged({
    this.minPrice,
    this.maxPrice,
    this.layout,
    this.mounting,
    this.pcb,
    this.connection,
    this.battery,
    this.minRating,
  });

  @override
  List<Object?> get props => [
        minPrice,
        maxPrice,
        layout,
        mounting,
        pcb,
        connection,
        battery,
        minRating,
      ];
}

class LoadMoreSearch extends AssembledProductSearchEvent {}

class ClearFilters extends AssembledProductSearchEvent {}
