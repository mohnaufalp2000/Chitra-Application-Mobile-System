// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tire_invent_bloc.dart';

abstract class TireInventEvent extends Equatable {
  const TireInventEvent();

  @override
  List<Object> get props => [];
}

class GetTireInventEvent extends TireInventEvent {
  String idSite;
  List<String> status;
  GetTireInventEvent({
    required this.idSite,
    required this.status,
  });
}
