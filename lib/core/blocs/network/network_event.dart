part of 'network_bloc.dart';

abstract class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object> get props => [];
}

class NetworkNotifyEvent extends NetworkEvent {
  final bool isConnected;

  NetworkNotifyEvent({this.isConnected = false});
}

class NetworkObserverEvent extends NetworkEvent {}
