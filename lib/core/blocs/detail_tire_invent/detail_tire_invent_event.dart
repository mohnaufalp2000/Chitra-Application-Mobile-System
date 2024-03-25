// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'detail_tire_invent_bloc.dart';

abstract class DetailTireInventEvent extends Equatable {
  const DetailTireInventEvent();

  @override
  List<Object> get props => [];
}

class GetDetailTireInventEvent extends DetailTireInventEvent {
  String idSite;
  String status;
  String total;
  GetDetailTireInventEvent({
    required this.idSite,
    required this.status,
    required this.total,
  });
}
