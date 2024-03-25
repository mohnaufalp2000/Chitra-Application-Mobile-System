part of 'feedback_bloc.dart';

abstract class FeedbackState extends Equatable {
  const FeedbackState();
  
  @override
  List<Object> get props => [];
}

class FeedbackInitial extends FeedbackState {}
