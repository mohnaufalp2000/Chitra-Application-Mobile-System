// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'detail_tire_invent_bloc.dart';

abstract class DetailTireInventState extends Equatable {
  const DetailTireInventState();

  @override
  List<Object> get props => [];
}

class DetailTireInventInitial extends DetailTireInventState {}

class DetailTireInventLoadingState extends DetailTireInventState {}

class DetailTireInventLoadedState extends DetailTireInventState {
  Map<String, dynamic> mapSizeInvent;
  DetailTireInventLoadedState({
    required this.mapSizeInvent,
  });
}

class DetailTireInventErrorState extends DetailTireInventState {}
