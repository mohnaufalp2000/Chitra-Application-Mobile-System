// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'detail_tire_condition_bloc.dart';

abstract class DetailTireConditionState extends Equatable {
  const DetailTireConditionState();

  @override
  List<Object> get props => [];
}

class DetailTireConditionInitial extends DetailTireConditionState {}

class DetailTireConditionLoadingState extends DetailTireConditionState {}

class DetailTireConditionLoadedState extends DetailTireConditionState {
  final List<UnitTire> units;
  DetailTireConditionLoadedState({
    required this.units,
  });
}
