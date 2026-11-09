import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  const testUser = UserModel(
    id: 'user-1',
    phone: '0599111111',
    name: 'أحمد ناصر',
    role: UserRole.buyer,
    verificationStatus: VerificationStatus.verified,
  );

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(authRepository: mockAuthRepository);
      expect(bloc.state, const AuthInitial());
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when session exists and user is found',
      build: () {
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenAnswer((_) async => testUser);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const CheckAuthSessionEvent()),
      expect: () => [const AuthLoading(), const Authenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no session exists',
      build: () {
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenAnswer((_) async => null);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const CheckAuthSessionEvent()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'says "offline" when the server cannot be asked who is signed in',
      build: () {
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenThrow(Exception('no connection'));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const CheckAuthSessionEvent()),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(Strings.loginOffline),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful login',
      build: () {
        when(
          () => mockAuthRepository.login(phone: '0599111111', pin: '1234'),
        ).thenAnswer((_) async => testUser);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) =>
          bloc.add(const LoginRequestedEvent(phone: '0599111111', pin: '1234')),
      expect: () => [const AuthLoading(), const Authenticated(testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when login fails with existing phone',
      build: () {
        when(
          () => mockAuthRepository.login(phone: '0599111111', pin: '0000'),
        ).thenAnswer((_) async => null);
        when(
          () => mockAuthRepository.phoneExists('0599111111'),
        ).thenAnswer((_) async => true);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) =>
          bloc.add(const LoginRequestedEvent(phone: '0599111111', pin: '0000')),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(Strings.loginError),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'reports a connection problem, not "not registered", when PIN login '
      'gets no answer',
      build: () {
        when(
          () => mockAuthRepository.login(phone: '0599111111', pin: '1234'),
        ).thenThrow(Exception('SocketException: Failed host lookup'));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) =>
          bloc.add(const LoginRequestedEvent(phone: '0599111111', pin: '1234')),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(Strings.loginOffline),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSwitchToRegister] when phone is unknown',
      build: () {
        when(
          () => mockAuthRepository.login(phone: '0599999999', pin: '1234'),
        ).thenAnswer((_) async => null);
        when(
          () => mockAuthRepository.phoneExists('0599999999'),
        ).thenAnswer((_) async => false);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) =>
          bloc.add(const LoginRequestedEvent(phone: '0599999999', pin: '1234')),
      expect: () => [
        const AuthLoading(),
        const AuthSwitchToRegister(phone: '0599999999'),
      ],
    );

    const pendingUser = UserModel(
      id: 'user-1',
      phone: '0599111111',
      name: 'أحمد ناصر',
      verificationStatus: VerificationStatus.pending,
    );

    blocTest<AuthBloc, AuthState>(
      'verifies the account when the server accepts the wallet code',
      build: () {
        when(
          () => mockAuthRepository.verifyWallet(code: '1234'),
        ).thenAnswer((_) async => testUser); // testUser is verified
        return AuthBloc(authRepository: mockAuthRepository);
      },
      seed: () => const Authenticated(pendingUser),
      act: (bloc) =>
          bloc.add(const WalletVerificationRequestedEvent(code: '1234')),
      expect: () => [
        const Authenticated(pendingUser, profileSaving: true),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'stays pending with an error when the server refuses the code',
      build: () {
        when(
          () => mockAuthRepository.verifyWallet(code: '0000'),
        ).thenAnswer((_) async => null);
        return AuthBloc(authRepository: mockAuthRepository);
      },
      seed: () => const Authenticated(pendingUser),
      act: (bloc) =>
          bloc.add(const WalletVerificationRequestedEvent(code: '0000')),
      expect: () => [
        const Authenticated(pendingUser, profileSaving: true),
        const Authenticated(pendingUser, profileError: Strings.wrongOtpError),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'reports a connection problem without verifying',
      build: () {
        when(
          () => mockAuthRepository.verifyWallet(code: any(named: 'code')),
        ).thenThrow(Exception('offline'));
        return AuthBloc(authRepository: mockAuthRepository);
      },
      seed: () => const Authenticated(pendingUser),
      act: (bloc) =>
          bloc.add(const WalletVerificationRequestedEvent(code: '1234')),
      expect: () => [
        const Authenticated(pendingUser, profileSaving: true),
        const Authenticated(
          pendingUser,
          profileError: Strings.walletVerifyFailed,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] when logout is requested',
      build: () {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
        return AuthBloc(authRepository: mockAuthRepository);
      },
      act: (bloc) => bloc.add(const LogoutRequestedEvent()),
      expect: () => [const Unauthenticated()],
    );

    group('PIN Login Flow', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] on successful PIN login',
        build: () {
          when(
            () => mockAuthRepository.login(phone: '0599111111', pin: '1234'),
          ).thenAnswer((_) async => testUser);
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(
          const LoginRequestedEvent(phone: '0599111111', pin: '1234'),
        ),
        expect: () => [const AuthLoading(), const Authenticated(testUser)],
      );

      for (final blocked in {
        'account_disabled': Strings.loginAccountDisabled,
        'store_archived': Strings.loginStoreArchived,
        'login_locked': Strings.loginLocked,
      }.entries) {
        blocTest<AuthBloc, AuthState>(
          'a ${blocked.key} account is told so, not "wrong PIN" or "offline"',
          build: () {
            when(
              () => mockAuthRepository.login(phone: '0599111111', pin: '1234'),
            ).thenThrow(AccountBlockedException(blocked.key));
            return AuthBloc(authRepository: mockAuthRepository);
          },
          act: (bloc) => bloc.add(
            const LoginRequestedEvent(phone: '0599111111', pin: '1234'),
          ),
          expect: () => [const AuthLoading(), AuthFailure(blocked.value)],
        );
      }

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when PIN is wrong for existing user',
        build: () {
          when(
            () => mockAuthRepository.login(phone: '0599111111', pin: '0000'),
          ).thenAnswer((_) async => null);
          when(
            () => mockAuthRepository.phoneExists('0599111111'),
          ).thenAnswer((_) async => true);
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(
          const LoginRequestedEvent(phone: '0599111111', pin: '0000'),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthFailure(Strings.loginError),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthSwitchToRegister] when the phone is not registered',
        build: () {
          when(
            () => mockAuthRepository.login(phone: '0599999999', pin: '1234'),
          ).thenAnswer((_) async => null);
          when(
            () => mockAuthRepository.phoneExists('0599999999'),
          ).thenAnswer((_) async => false);
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(
          const LoginRequestedEvent(phone: '0599999999', pin: '1234'),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthSwitchToRegister(phone: '0599999999'),
        ],
      );
    });
  });
}
