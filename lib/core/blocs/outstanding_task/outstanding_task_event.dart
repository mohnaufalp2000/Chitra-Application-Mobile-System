// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'outstanding_task_bloc.dart';

abstract class OutstandingTaskEvent extends Equatable {
  const OutstandingTaskEvent();

  @override
  List<Object> get props => [];
}

class AddOutStandingTaskEvent extends OutstandingTaskEvent {
  final OutstandingTask task;

  AddOutStandingTaskEvent({
    required this.task,
  });
}

class ReadOutStandingTaskEvent extends OutstandingTaskEvent {
  final List<String> selectedDate;
  ReadOutStandingTaskEvent({
    required this.selectedDate,
  });
}

class DeleteOutStandingTaskEvent extends OutstandingTaskEvent {
  final String id;
  DeleteOutStandingTaskEvent({
    required this.id,
  });
}
