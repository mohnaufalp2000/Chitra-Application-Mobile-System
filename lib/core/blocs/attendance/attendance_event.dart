// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object> get props => [];
}

class PresenceAttendanceEvent extends AttendanceEvent {
  final BuildContext context;
  final String selectedShift;
  PresenceAttendanceEvent({
    required this.context,
    required this.selectedShift,
  });
}

class SelectShiftAttendanceEvent extends AttendanceEvent {
  final String shift;

  SelectShiftAttendanceEvent({
    required this.shift,
  });
}

class SaveCsvAttendanceEvent extends AttendanceEvent {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>>? presence;
  final String username;
  final String position;
  final String sn;
  final String site;
  SaveCsvAttendanceEvent({
    this.presence,
    required this.username,
    required this.position,
    required this.sn,
    required this.site,
  });
}

class SaveCsvPresenceEvent extends AttendanceEvent {
  final List<AttendanceEntity> presence;
  final String username;
  final String position;
  final String sn;
  final String site;
  final String desc;
  SaveCsvPresenceEvent(
      {required this.presence,
      required this.username,
      required this.position,
      required this.sn,
      required this.site,
      this.desc = ''});
}
