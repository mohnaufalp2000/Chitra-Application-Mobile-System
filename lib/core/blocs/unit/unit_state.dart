// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'unit_bloc.dart';

abstract class UnitState extends Equatable {
  const UnitState();

  @override
  List<Object> get props => [];
}

class UnitInitial extends UnitState {}

class UnitLoadingState extends UnitState {}

class UnitLoadedState extends UnitState {
  final List<UnitTire> units;
  // final List<ReccPress> reccPress;
  UnitLoadedState({
    required this.units,
    // required this.reccPress,
  });
}

class UnitErrorState extends UnitState {
  final String message;

  UnitErrorState({required this.message});
}

class UnitTiresErrorState extends UnitState {}
