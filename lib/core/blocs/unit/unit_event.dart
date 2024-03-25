// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'unit_bloc.dart';

abstract class UnitEvent extends Equatable {
  const UnitEvent();

  @override
  List<Object> get props => [];
}

class GetUnitsEvent extends UnitEvent {
  final String idSite;
  GetUnitsEvent({
    required this.idSite,
  });
}

// class GetUnitTiresEvent extends UnitEvent {
//   final String idSite;
//   final String unitNumber;
//   GetUnitTiresEvent({
//     required this.idSite,
//     required this.unitNumber,
//   });
// }
