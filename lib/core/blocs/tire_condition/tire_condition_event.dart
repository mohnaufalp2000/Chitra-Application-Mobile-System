part of 'tire_condition_bloc.dart';

abstract class TireConditionEvent extends Equatable {
  const TireConditionEvent();

  @override
  List<Object> get props => [];
}

class GetTireConditionEvent extends TireConditionEvent {
  final String idSite;
  GetTireConditionEvent({
    required this.idSite,
  });
}
