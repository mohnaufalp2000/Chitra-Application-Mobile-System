// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'attendance_bloc.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceSelectedShiftState extends AttendanceState {
  final String shift;
  AttendanceSelectedShiftState({
    required this.shift,
  });
}

class AttendancePresenceLoadingState extends AttendanceState {}

class AttendanceSaveCsvLoadingState extends AttendanceState {}

class AttendanceSuccessSaveCsvState extends AttendanceState {}

class AttendanceSuccessPresenceState extends AttendanceState {}

class AttendanceErrorState extends AttendanceState {
  final bool? isAlreadyPresence;
  AttendanceErrorState({
    this.isAlreadyPresence,
  });
}
