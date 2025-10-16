import 'dart:async';

import 'package:bloc/bloc.dart';
import '../../utils/functions/functions.dart';
import 'package:equatable/equatable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  NetworkBloc._() : super(NetworkInitial()) {
    on<NetworkObserverEvent>(_observe);
    on<NetworkNotifyEvent>(_notifyStatus);
  }

  static final NetworkBloc _instance = NetworkBloc._();

  factory NetworkBloc() => _instance;

  void _observe(event, emit) {
    NetworkHelper.observeNetwork();
  }

  void _notifyStatus(NetworkNotifyEvent event, emit) {
    print('terkoneksi = ${event.isConnected}');
    event.isConnected ? emit(NetworkConnected()) : emit(NetworkDisconnected());
  }
}
