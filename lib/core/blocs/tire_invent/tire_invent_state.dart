// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tire_invent_bloc.dart';

abstract class TireInventState extends Equatable {
  const TireInventState();

  @override
  List<Object> get props => [];
}

class TireInventInitial extends TireInventState {}

class TireInventLoadingState extends TireInventState {
  final double percentage;
  TireInventLoadingState({
    required this.percentage,
  });
}

class TireInventLoadedState extends TireInventState {
  final List<Map<String, dynamic>> tireBlocData;
  final Map<String, dynamic> site;

  TireInventLoadedState({
    required this.tireBlocData,
    required this.site,
  });

  String get nameSite => site['siteName'];
}

class TireInventErrorState extends TireInventState {
  final String message;
  TireInventErrorState({
    required this.message,
  });
}
