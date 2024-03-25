// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tire_bloc.dart';

@immutable
abstract class TireEvent {}

class GetTireCountEvent extends TireEvent {
  String idSite;
  List<String> status;
  GetTireCountEvent({
    required this.idSite,
    required this.status,
  });
}

class GetUnitTiresEvent extends TireEvent {
  final String idSite;
  final String unitNumber;
  GetUnitTiresEvent({
    required this.idSite,
    required this.unitNumber,
  });
}
