part of 'daily_check_post_bloc.dart';

abstract class DailyCheckPostState extends Equatable {
  const DailyCheckPostState();

  @override
  List<Object> get props => [];
}

class DailyCheckPostInitial extends DailyCheckPostState {}

class DailyCheckPostLoadingState extends DailyCheckPostState {}

class DailyCheckPostSuccessState extends DailyCheckPostState {
  final String message;
  DailyCheckPostSuccessState({required this.message});
}

class DailyCheckPostErrorState extends DailyCheckPostState {
  final String error;
  DailyCheckPostErrorState({required this.error});
}
