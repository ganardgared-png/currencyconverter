part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginWithPassword extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLoginWithPassword({required this.email, required this.password});
  
  @override
  List<Object> get props => [email, password];
}

class AuthLoginWithPin extends AuthEvent {
  final String pin;
  
  const AuthLoginWithPin({required this.pin});
  
  @override
  List<Object> get props => [pin];
}

class AuthLoginWithPattern extends AuthEvent {
  final String pattern;
  
  const AuthLoginWithPattern({required this.pattern});
  
  @override
  List<Object> get props => [pattern];
}

class AuthLoginWithBiometrics extends AuthEvent {}

class AuthLogout extends AuthEvent {}

class AuthRegister extends AuthEvent {
  final String username;
  final String email;
  final String password;
  
  const AuthRegister({
    required this.username,
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [username, email, password];
}

class AuthSetupPin extends AuthEvent {
  final String pin;
  
  const AuthSetupPin({required this.pin});
  
  @override
  List<Object> get props => [pin];
}

class AuthSetupPattern extends AuthEvent {
  final String pattern;
  
  const AuthSetupPattern({required this.pattern});
  
  @override
  List<Object> get props => [pattern];
}

class AuthToggleBiometrics extends AuthEvent {
  final bool enabled;
  
  const AuthToggleBiometrics({required this.enabled});
  
  @override
  List<Object> get props => [enabled];
}