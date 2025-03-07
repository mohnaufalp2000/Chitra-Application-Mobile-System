part of 'daily_check_post_bloc.dart';

class DailyCheckPostEvent extends Equatable {
  final List<Map<String, dynamic>> dailyCheck;
  final List<UnitTire> allUnit;
  final int countAllTire;
  final Map<String, dynamic> allTireSize;
  final String typeSend;
  const DailyCheckPostEvent(
      {required this.dailyCheck,
      required this.countAllTire,
      required this.allUnit,
      required this.allTireSize,
      required this.typeSend});

  @override
  List<Object> get props => [];
}
