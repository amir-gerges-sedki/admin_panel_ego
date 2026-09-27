import 'package:equatable/equatable.dart';
import '../../data/models/stock_movement_model.dart';

abstract class StockMovementState extends Equatable {
  const StockMovementState();

  @override
  List<Object?> get props => [];
}

class StockMovementInitial extends StockMovementState {}

class StockMovementLoading extends StockMovementState {}

class StockMovementLoaded extends StockMovementState {
  final List<StockMovementModel> allMovements;
  final List<StockMovementModel> filteredMovements;
  final String searchQuery;
  final StockMovementType? selectedType;
  final String? selectedProductId;

  const StockMovementLoaded({
    required this.allMovements,
    required this.filteredMovements,
    this.searchQuery = '',
    this.selectedType,
    this.selectedProductId,
  });

  int get totalInflowCount => allMovements.where((m) => m.isInflow).fold<int>(0, (sum, m) => sum + m.quantity);
  double get totalInflowValue => allMovements.where((m) => m.isInflow).fold<double>(0.0, (sum, m) => sum + m.totalCost);

  int get totalOutflowCount => allMovements.where((m) => m.isOutflow).fold<int>(0, (sum, m) => sum + m.quantity.abs());
  double get totalOutflowValue => allMovements.where((m) => m.isOutflow).fold<double>(0.0, (sum, m) => sum + m.totalCost);

  StockMovementLoaded copyWith({
    List<StockMovementModel>? allMovements,
    List<StockMovementModel>? filteredMovements,
    String? searchQuery,
    StockMovementType? selectedType,
    bool clearType = false,
    String? selectedProductId,
    bool clearProduct = false,
  }) {
    return StockMovementLoaded(
      allMovements: allMovements ?? this.allMovements,
      filteredMovements: filteredMovements ?? this.filteredMovements,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedProductId: clearProduct ? null : (selectedProductId ?? this.selectedProductId),
    );
  }

  @override
  List<Object?> get props => [
        allMovements,
        filteredMovements,
        searchQuery,
        selectedType,
        selectedProductId,
      ];
}

class StockMovementError extends StockMovementState {
  final String message;

  const StockMovementError(this.message);

  @override
  List<Object?> get props => [message];
}

class StockMovementActionSuccess extends StockMovementState {
  final String message;

  const StockMovementActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
