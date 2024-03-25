// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'detail_tire_condition_bloc.dart';

abstract class DetailTireConditionEvent extends Equatable {
  const DetailTireConditionEvent();

  @override
  List<Object> get props => [];
}

class GetDetailTireConditionEvent extends DetailTireConditionEvent {
  final String size;
  final String idSite;

  GetDetailTireConditionEvent({
    required this.size,
    required this.idSite,
  });
}
