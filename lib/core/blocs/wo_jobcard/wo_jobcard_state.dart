part of 'wo_jobcard_bloc.dart';

class WoJobcardState extends Equatable {
  const WoJobcardState();

  @override
  List<Object> get props => [];
}

class WoJobcardInitial extends WoJobcardState {}

class WoJobcardLoadingState extends WoJobcardState {}

class WoJobcardErrorState extends WoJobcardState {}

class WoJobcardLoadedState extends WoJobcardState {
  final List<Map<String, dynamic>> WOList;

  WoJobcardLoadedState({required this.WOList});
}
