part of 'spm_bloc.dart';

abstract class SpmState {}

class SpmInitial extends SpmState {}

class SpmLoadingState extends SpmState {}

class SpmLoadedState extends SpmState {
  final List<Spm> listSpm;
  SpmLoadedState({
    required this.listSpm,
  });
}
