import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc() : super(FeedbackInitial()) {
    on<FeedbackEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
