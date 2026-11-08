import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/i18n/strings.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<CheckAuthSessionEvent>(_onCheckAuthSession);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<RegisterRequestedEvent>(_onRegisterRequested);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<WalletVerificationRequestedEvent>(_onWalletVerification);
    on<UpdateProfileRequestedEvent>(_onUpdateProfile);
  }

  final AuthRepository _authRepository;

  int _sessionEpoch = 0;

  Future<void> _onUpdateProfile(
    UpdateProfileRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated || current.profileSaving) return;
    final epoch = _sessionEpoch;
    emit(Authenticated(current.user, profileSaving: true));
    try {
      final updated = await _authRepository.updateProfile(
        name: event.name.trim(),
      );
      if (epoch != _sessionEpoch ||
          state is! Authenticated ||
          (state as Authenticated).user.id != current.user.id) {
        return;
      }
      emit(Authenticated(updated));
    } catch (_) {
      if (epoch != _sessionEpoch ||
          state is! Authenticated ||
          (state as Authenticated).user.id != current.user.id) {
        return;
      }
      emit(
        Authenticated(
          current.user,
          profileError: 'تعذر حفظ البيانات. تحقق من الاتصال وحاول مجدداً.',
        ),
      );
    }
  }

  Future<void> _onCheckAuthSession(
    CheckAuthSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.restoreSession();
      emit(user != null ? Authenticated(user) : const Unauthenticated());
    } catch (e) {
      // Signed in on this phone, but the server could not be asked who that
      // is: the profile is not kept locally, so say so on the login screen.
      emit(const AuthFailure(Strings.loginOffline));
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
    } on AccountBlockedException catch (e) {
      emit(AuthFailure(_blockedMessage(e)));
    } catch (e) {
      // The gateway answering "no" is handled in the repository; anything
      // that gets here is a call that never got an answer.
      emit(const AuthFailure(Strings.loginOffline));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final validationError = _authRepository.validateRegistration(
      phone: event.phone,
      pin: event.pin,
      name: event.name,
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
      final user = await _authRepository.register(
        phone: event.phone,
        pin: event.pin,
        name: event.name,
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
    _sessionEpoch++;
    await _authRepository.logout();
    emit(const Unauthenticated());
  }

  Future<void> _onWalletVerification(
    WalletVerificationRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated || current.profileSaving) return;
    final epoch = _sessionEpoch;
    emit(Authenticated(current.user, profileSaving: true));
    try {
      final updated = await _authRepository.verifyWallet(code: event.code);
      if (epoch != _sessionEpoch) return;
      emit(
        updated != null
            ? Authenticated(updated)
            : Authenticated(current.user, profileError: Strings.wrongOtpError),
      );
    } catch (_) {
      if (epoch != _sessionEpoch) return;
      emit(
        Authenticated(current.user, profileError: Strings.walletVerifyFailed),
      );
    }
  }

  static String _blockedMessage(AccountBlockedException e) =>
      switch (e.reason) {
        'store_archived' => Strings.loginStoreArchived,
        'login_locked' => Strings.loginLocked,
        _ => Strings.loginAccountDisabled,
      };
}
