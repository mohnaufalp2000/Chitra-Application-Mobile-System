// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tire_bloc.dart';

@immutable
abstract class TireState {}

class TireInitial extends TireState {}

class TireLoadingState extends TireState {}

class TireCountLoadedState extends TireState {
  final List<Map<String, dynamic>> tireBlocData;
  final Map<String, dynamic> site;

  TireCountLoadedState({
    required this.tireBlocData,
    required this.site,
  });

  String get nameSite => site['siteName'];
}

class TireErrorState extends TireState {
  final String message;
  TireErrorState({
    required this.message,
  });
}

class TiresLoadedState extends TireState {
  final List<UnitTire> units;
  TiresLoadedState({
    required this.units,
  });
}
