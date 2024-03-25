part of 'tire_condition_bloc.dart';

abstract class TireConditionState extends Equatable {
  const TireConditionState();

  @override
  List<Object> get props => [];
}

class TireConditionInitial extends TireConditionState {}

class TireConditionLoadingState extends TireConditionState {}

class TireConditionLoadedState extends TireConditionState {
  final List<Map<String, dynamic>> listSize;
  final Map<String, dynamic> mapRating;
  TireConditionLoadedState({
    required this.listSize,
    required this.mapRating,
  });
}

class TireConditionErrorState extends TireConditionState {
  final String message;
  TireConditionErrorState({
    required this.message,
  });
}
