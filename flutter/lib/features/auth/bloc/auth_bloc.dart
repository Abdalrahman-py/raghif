import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/session_store.dart';
import '../../../core/i18n/strings.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required SessionStore sessionStore,
  })  : _authRepository = authRepository,
        _sessionStore = sessionStore,
        super(const AuthInitial()) {
    on<CheckAuthSessionEvent>(_onCheckAuthSession);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<RegisterRequestedEvent>(_onRegisterRequested);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<VerificationApprovedEvent>(_onVerificationApproved);
  }

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;

  Future<void> _onCheckAuthSession(
    CheckAuthSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.ensureSeeded();
      final userId = await _sessionStore.loadUserId();
      if (userId == null) {
        emit(const Unauthenticated());
        return;
      }

      final user = await _authRepository.findById(userId);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        await _sessionStore.clear();
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final phone = event.phone.trim();
      final pin = event.pin.trim();

      final user = await _authRepository.login(phone: phone, pin: pin);
      if (user != null) {
        emit(Authenticated(user));
        return;
      }

      final exists = await _authRepository.phoneExists(phone);
      if (exists) {
        emit(const AuthFailure(Strings.loginError));
      } else {
        emit(AuthSwitchToRegister(phone: phone));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final validationError = _authRepository.validateRegistration(
      phone: event.phone,
      pin: event.pin,
      nationalId: event.nationalId,
      name: event.name,
      jawwalPayNumber: event.jawwalPayNumber,
    );

    if (validationError != null) {
      emit(AuthFailure(validationError));
      return;
    }

    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(
        phone: event.phone,
        pin: event.pin,
        nationalId: event.nationalId,
        name: event.name,
        jawwalPayNumber: event.jawwalPayNumber,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const Unauthenticated());
  }

  Future<void> _onVerificationApproved(
    VerificationApprovedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated) return;
    await _authRepository.updateVerificationStatus(
      current.user.id,
      VerificationStatus.verified,
    );
    final updated = await _authRepository.findById(current.user.id);
    if (updated != null) emit(Authenticated(updated));
  }
}
