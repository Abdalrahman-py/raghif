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
    on<RequestOtpEvent>(_onRequestOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<PinLoginRequestedEvent>(_onPinLoginRequested);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<RegisterRequestedEvent>(_onRegisterRequested);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<VerificationApprovedEvent>(_onVerificationApproved);
  }

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;

  String? _pendingOtp;
  String? _pendingNationalId;

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

  Future<void> _onRequestOtp(
    RequestOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final nationalId = event.nationalId.trim();
      final user = await _authRepository.findByNationalId(nationalId);
      if (user == null) {
        emit(AuthSwitchToRegister(nationalId: nationalId));
        return;
      }

      final otp = await _authRepository.requestOtp(nationalId);
      if (otp == null) {
        emit(AuthSwitchToRegister(nationalId: nationalId));
        return;
      }

      _pendingOtp = otp;
      _pendingNationalId = nationalId;
      emit(AuthOtpSent(
        nationalId: nationalId,
        phone: user.phone,
        otpCode: otp,
      ));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final nationalId = event.nationalId.trim();
      final otp = event.otp.trim();

      if (_pendingNationalId != null && _pendingNationalId != nationalId) {
        emit(const AuthFailure(Strings.otpError));
        return;
      }

      final expectedOtp = _pendingOtp ??
          (state is AuthOtpSent ? (state as AuthOtpSent).otpCode : '4821');

      if (otp != expectedOtp) {
        emit(const AuthFailure(Strings.otpError));
        return;
      }

      final user = await _authRepository.loginWithOtp(nationalId: nationalId);
      if (user != null) {
        _pendingOtp = null;
        _pendingNationalId = null;
        emit(Authenticated(user));
      } else {
        emit(const AuthFailure(Strings.loginError));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onPinLoginRequested(
    PinLoginRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final nationalId = event.nationalId.trim();
      final pin = event.pin.trim();

      final user = await _authRepository.loginWithPin(
        nationalId: nationalId,
        pin: pin,
      );
      if (user != null) {
        emit(Authenticated(user));
        return;
      }

      final exists = await _authRepository.nationalIdExists(nationalId);
      if (exists) {
        emit(const AuthFailure(Strings.loginError));
      } else {
        emit(AuthSwitchToRegister(nationalId: nationalId));
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
        emit(AuthSwitchToRegister(nationalId: phone));
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
      if (await _authRepository.phoneExists(event.phone)) {
        emit(const AuthFailure(Strings.phoneAlreadyRegistered));
        return;
      }
      if (await _authRepository.nationalIdExists(event.nationalId)) {
        emit(const AuthFailure(Strings.nationalIdAlreadyRegistered));
        return;
      }
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
