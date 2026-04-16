part of 'process_jobcard_bloc.dart';

class ProcessJobcardEvent extends Equatable {
  const ProcessJobcardEvent();

  @override
  List<Object> get props => [];
}

class FetchMaterialListEvent extends ProcessJobcardEvent {}

class SubmitJobcardEvent extends ProcessJobcardEvent {
  final Map<String, dynamic> jobcard;
  final bool isEdit;

  SubmitJobcardEvent({required this.jobcard, required this.isEdit});
}
