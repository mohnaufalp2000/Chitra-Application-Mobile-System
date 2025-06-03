part of 'process_jobcard_bloc.dart';

class ProcessJobcardState extends Equatable {
  const ProcessJobcardState();

  @override
  List<Object> get props => [];
}

// === MATERIAL STATE ===
class MaterialInitialState extends ProcessJobcardState {}

class MaterialLoadingState extends ProcessJobcardState {}

class MaterialLoadedState extends ProcessJobcardState {
  final List<MaterialRepair> materials;
  MaterialLoadedState(this.materials);
}

class MaterialErrorState extends ProcessJobcardState {}

// === SUBMIT STATE ===
class SubmitInitialState extends ProcessJobcardState {}

class SubmitLoadingState extends ProcessJobcardState {}

class SubmitSuccessState extends ProcessJobcardState {}

class SubmitErrorState extends ProcessJobcardState {}
