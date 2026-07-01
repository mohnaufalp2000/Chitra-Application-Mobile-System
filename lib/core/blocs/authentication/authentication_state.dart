// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authentication_bloc.dart';

@immutable
abstract class AuthenticationState {}

class AuthenticatioLoginState extends AuthenticationState {}

class AuthenticationSuccessState extends AuthenticationState {
  final String targetRoute;
  final Map<String, dynamic>? arguments;

  AuthenticationSuccessState({
    required this.targetRoute,
    this.arguments,
  });
}

class AuthenticatioRegisterState extends AuthenticationState {}

class AuthenticatioLoadingState extends AuthenticationState {}

class AuthenticatioLogoutState extends AuthenticationState {}

class AuthenticationChangePasswordState extends AuthenticationState {}

class AuthenticationVerifyEmailState extends AuthenticationState {}

class AuthenticationErrorState extends AuthenticationState {
  final String errorMessage;

  AuthenticationErrorState({
    required this.errorMessage,
  });
}

class AuthenticationEmailNotVerifiedState extends AuthenticationState {}

class AuthenticationCompleteProfileState extends AuthenticationState {}
