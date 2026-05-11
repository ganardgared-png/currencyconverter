import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_expenses_plan/data/repositories/auth_repository.dart';
import 'package:smart_expenses_plan/data/models/user_model.dart';
import 'package:smart_expenses_plan/services/biometric_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginWithPassword>(_onAuthLoginWithPassword);
    on<AuthLoginWithPin>(_onAuthLoginWithPin);
    on<AuthLoginWithPattern>(_onAuthLoginWithPattern);
    on<AuthLoginWithBiometrics>(_onAuthLoginWithBiometrics);
    on<AuthLogout>(_onAuthLogout);
    on<AuthRegister>(_onAuthRegister);
    on<AuthSetupPin>(_onAuthSetupPin);
    on<AuthSetupPattern>(_onAuthSetupPattern);
    on<AuthToggleBiometrics>(_onAuthToggleBiometrics);
  }
  
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.getCurrentUser();
      final hasPassword = await _authRepository.hasPassword();
      final useBiometrics = await _authRepository.useBiometrics();
      
      if (user != null) {
        if (useBiometrics) {
          final biometricAvailable = await BiometricService.isBiometricAvailable();
          if (biometricAvailable) {
            emit(AuthBiometricAvailable());
          } else {
            emit(AuthAuthenticated(user: user));
          }
        } else {
          emit(AuthAuthenticated(user: user));
        }
      } else {
        if (!hasPassword) {
          emit(AuthPasswordSetupRequired());
        } else {
          emit(AuthUnauthenticated());
        }
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthLoginWithPassword(
    AuthLoginWithPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.loginWithPassword(
        event.email,
        event.password,
      );
      
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Invalid email or password'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthLoginWithPin(
    AuthLoginWithPin event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.loginWithPin(event.pin);
      
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Invalid PIN'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthLoginWithPattern(
    AuthLoginWithPattern event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.loginWithPattern(event.pattern);
      
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthError(message: 'Invalid pattern'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthLoginWithBiometrics(
    AuthLoginWithBiometrics event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final authenticated = await BiometricService.authenticate();
      
      if (authenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(const AuthError(message: 'Biometric authentication failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthLogout(
    AuthLogout event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = UserModel(
        username: event.username,
        email: event.email,
        password: event.password,
      );
      
      final id = await _authRepository.createUser(user);
      final createdUser = user.copyWith(id: id);
      
      await _authRepository.setHasPassword(true);
      
      emit(AuthAuthenticated(user: createdUser));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthSetupPin(
    AuthSetupPin event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(pin: event.pin);
        // Update user in database
        emit(AuthAuthenticated(user: updatedUser));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthSetupPattern(
    AuthSetupPattern event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(pattern: event.pattern);
        // Update user in database
        emit(AuthAuthenticated(user: updatedUser));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
  
  Future<void> _onAuthToggleBiometrics(
    AuthToggleBiometrics event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.setUseBiometrics(event.enabled);
      
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}