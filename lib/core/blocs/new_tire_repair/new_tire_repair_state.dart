part of 'new_tire_repair_bloc.dart';

class NewTireRepairState extends Equatable {
  const NewTireRepairState();

  @override
  List<Object> get props => [];
}

class NewTireRepairInitial extends NewTireRepairState {}

class NewTireRepairLoadingState extends NewTireRepairState {}

class NewTireRepairSuccessState extends NewTireRepairState {
  final String message;
  NewTireRepairSuccessState({required this.message});
}

class NewTireRepairErrorState extends NewTireRepairState {
  final String error;
  NewTireRepairErrorState({required this.error});
}
