part of 'daily_check_post_bloc.dart';

class DailyCheckPostEvent extends Equatable {
  final List<Map<String, dynamic>> dailyCheck;
  final int countAllTire;
  const DailyCheckPostEvent(
      {required this.dailyCheck, required this.countAllTire});

  @override
  List<Object> get props => [];
}
