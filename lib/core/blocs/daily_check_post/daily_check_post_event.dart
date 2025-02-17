part of 'daily_check_post_bloc.dart';

class DailyCheckPostEvent extends Equatable {
  final List<Map<String, dynamic>> dailyCheck;
  const DailyCheckPostEvent({required this.dailyCheck});

  @override
  List<Object> get props => [];
}
