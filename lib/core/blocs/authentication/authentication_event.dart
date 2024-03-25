// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authentication_bloc.dart';

@immutable
abstract class AuthenticationEvent {}

class AuthenticationEventLogin extends AuthenticationEvent {
  final String email;
  final String password;

  AuthenticationEventLogin({
    required this.email,
    required this.password,
  });
}

class AuthenticationEventLogout extends AuthenticationEvent {
  final bool isDelete;

  AuthenticationEventLogout({
    this.isDelete = false,
  });
}

class AuthenticationEventRegister extends AuthenticationEvent {
  final String email;
  final String password;
  final String sn;
  final String idSite;
  AuthenticationEventRegister({
    required this.email,
    required this.password,
    required this.sn,
    required this.idSite,
  });
}

class AuthenticationEventUpdate extends AuthenticationEvent {
  final String username;
  final String position;
  final int age;
  final String image;
  AuthenticationEventUpdate({
    required this.username,
    required this.position,
    required this.age,
    required this.image,
  });
}

class AuthenticationEventChangePassword extends AuthenticationEvent {
  final String email;
  AuthenticationEventChangePassword({
    required this.email,
  });
}

class AuthenticationEventVerifyEmail extends AuthenticationEvent {}

class AuthenticationEventUploadPhoto extends AuthenticationEvent {
  final String email;
  final String path;

  AuthenticationEventUploadPhoto({
    required this.email,
    required this.path,
  });
}
