// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'outstanding_task_bloc.dart';

abstract class OutstandingTaskState extends Equatable {
  const OutstandingTaskState();

  @override
  List<Object> get props => [];
}

class OutstandingTaskInitial extends OutstandingTaskState {}

class OutStandingTaskLoadedState extends OutstandingTaskState {
  final List<OutstandingTaskEntity> initialTasks;
  final List<OutstandingTaskEntity> tasks;
  final DateTime timeStamp;
  OutStandingTaskLoadedState({
    required this.initialTasks,
    required this.tasks,
    required this.timeStamp,
  });

  @override
  List<Object> get props => [tasks, timeStamp];
}

class OutStandingTaskFilteredLoadedState extends OutstandingTaskState {
  final List<OutstandingTaskEntity> tasks;
  OutStandingTaskFilteredLoadedState({
    required this.tasks,
  });
}

class OutStandingTaskEmptyState extends OutstandingTaskState {}
