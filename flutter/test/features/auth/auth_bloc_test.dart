import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raghif/core/auth/session_store.dart';
import 'package:raghif/core/i18n/strings.dart';
import 'package:raghif/domain/models/user_model.dart';
import 'package:raghif/domain/repositories/auth_repository.dart';
import 'package:raghif/features/auth/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSessionStore extends Mock implements SessionStore {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockSessionStore mockSessionStore;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSessionStore = MockSessionStore();
  });

  const testUser = UserModel(
    id: 1,
    phone: '0599111111',
    nationalId: '900111222',
    name: 'أحمد ناصر',
    role: UserRole.buyer,
    jawwalPayNumber: '0599000001',
    verificationStatus: VerificationStatus.verified,
  );

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(
        authRepository: mockAuthRepository,
        sessionStore: mockSessionStore,
      );
      expect(bloc.state, const AuthInitial());
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when session exists and user is found',
      build: () {
        when(() => mockAuthRepository.ensureSeeded())
            .thenAnswer((_) async {});
        when(() => mockSessionStore.loadUserId())
            .thenAnswer((_) async => 1);
        when(() => mockAuthRepository.findById(1))
            .thenAnswer((_) async => testUser);
        return AuthBloc(
          authRepository: mockAuthRepository,
          sessionStore: mockSessionStore,
        );
      },
      act: (bloc) => bloc.add(const CheckAuthSessionEvent()),
      expect: () => [
        const AuthLoading(),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no session exists',
      build: () {
        when(() => mockAuthRepository.ensureSeeded())
            .thenAnswer((_) async {});
        when(() => mockSessionStore.loadUserId())
            .thenAnswer((_) async => null);
        return AuthBloc(
          authRepository: mockAuthRepository,
          sessionStore: mockSessionStore,
        );
      },
      act: (bloc) => bloc.add(const CheckAuthSessionEvent()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful login',
      build: () {
        when(() => mockAuthRepository.login(phone: '0599111111', pin: '1234'))
            .thenAnswer((_) async => testUser);
        return AuthBloc(
          authRepository: mockAuthRepository,
          sessionStore: mockSessionStore,
        );
      },
      act: (bloc) => bloc.add(
        const LoginRequestedEvent(phone: '0599111111', pin: '1234'),
      ),
      expect: () => [
        const AuthLoading(),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when login fails with existing phone',
      build: () {
        when(() => mockAuthRepository.login(phone: '0599111111', pin: '0000'))
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.phoneExists('0599111111'))
            .thenAnswer((_) async => true);
        return AuthBloc(
          authRepository: mockAuthRepository,
          sessionStore: mockSessionStore,
        );
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
      'emits [AuthLoading, AuthSwitchToRegister] when phone is unknown',
      build: () {
        when(() => mockAuthRepository.login(phone: '0599999999', pin: '1234'))
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.phoneExists('0599999999'))
            .thenAnswer((_) async => false);
        return AuthBloc(
          authRepository: mockAuthRepository,
          sessionStore: mockSessionStore,
        );
      },
      act: (bloc) => bloc.add(
        const LoginRequestedEvent(phone: '0599999999', pin: '1234'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthSwitchToRegister(nationalId: '0599999999'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Authenticated] with verified status on VerificationApprovedEvent',
      build: () {
        when(
          () => mockAuthRepository.updateVerificationStatus(
            1,
            VerificationStatus.verified,
          ),
        ).thenAnswer((_) async {});
        when(() => mockAuthRepository.findById(1)).thenAnswer(
          (_) async => testUser, // testUser is already verified
        );
        return AuthBloc(
          authRepository: mockAuthRepository,
          sessionStore: mockSessionStore,
        );
      },
      seed: () => const Authenticated(
        UserModel(
          id: 1,
          phone: '0599111111',
          nationalId: '900111222',
          name: 'أحمد ناصر',
          verificationStatus: VerificationStatus.pending,
        ),
      ),
      act: (bloc) => bloc.add(const VerificationApprovedEvent()),
      expect: () => [
        const Authenticated(testUser),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepository.updateVerificationStatus(
            1,
            VerificationStatus.verified,
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] when logout is requested',
      build: () {
        when(() => mockAuthRepository.logout())
            .thenAnswer((_) async {});
        return AuthBloc(
          authRepository: mockAuthRepository,
          sessionStore: mockSessionStore,
        );
      },
      act: (bloc) => bloc.add(const LogoutRequestedEvent()),
      expect: () => [
        const Unauthenticated(),
      ],
    );

    group('OTP Login Flow', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthOtpSent] when national ID exists',
        build: () {
          when(() => mockAuthRepository.findByNationalId('900111222'))
              .thenAnswer((_) async => testUser);
          when(() => mockAuthRepository.requestOtp('900111222'))
              .thenAnswer((_) async => '4821');
          return AuthBloc(
            authRepository: mockAuthRepository,
            sessionStore: mockSessionStore,
          );
        },
        act: (bloc) => bloc.add(const RequestOtpEvent(nationalId: '900111222')),
        expect: () => [
          const AuthLoading(),
          const AuthOtpSent(
            nationalId: '900111222',
            phone: '0599111111',
            otpCode: '4821',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthSwitchToRegister] when national ID is not registered',
        build: () {
          when(() => mockAuthRepository.findByNationalId('900999999'))
              .thenAnswer((_) async => null);
          return AuthBloc(
            authRepository: mockAuthRepository,
            sessionStore: mockSessionStore,
          );
        },
        act: (bloc) => bloc.add(const RequestOtpEvent(nationalId: '900999999')),
        expect: () => [
          const AuthLoading(),
          const AuthSwitchToRegister(nationalId: '900999999'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when entered OTP matches',
        seed: () => const AuthOtpSent(
          nationalId: '900111222',
          phone: '0599111111',
          otpCode: '4821',
        ),
        build: () {
          when(() => mockAuthRepository.loginWithOtp(nationalId: '900111222'))
              .thenAnswer((_) async => testUser);
          return AuthBloc(
            authRepository: mockAuthRepository,
            sessionStore: mockSessionStore,
          );
        },
        act: (bloc) => bloc.add(
          const VerifyOtpEvent(nationalId: '900111222', otp: '4821'),
        ),
        expect: () => [
          const AuthLoading(),
          const Authenticated(testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when entered OTP is incorrect',
        seed: () => const AuthOtpSent(
          nationalId: '900111222',
          phone: '0599111111',
          otpCode: '4821',
        ),
        build: () {
          return AuthBloc(
            authRepository: mockAuthRepository,
            sessionStore: mockSessionStore,
          );
        },
        act: (bloc) => bloc.add(
          const VerifyOtpEvent(nationalId: '900111222', otp: '0000'),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthFailure(Strings.otpError),
        ],
      );
    });

    group('PIN Login Flow', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] on successful PIN login',
        build: () {
          when(
            () => mockAuthRepository.loginWithPin(
              nationalId: '900111222',
              pin: '1234',
            ),
          ).thenAnswer((_) async => testUser);
          return AuthBloc(
            authRepository: mockAuthRepository,
            sessionStore: mockSessionStore,
          );
        },
        act: (bloc) => bloc.add(
          const PinLoginRequestedEvent(
            nationalId: '900111222',
            pin: '1234',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const Authenticated(testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when PIN is wrong for existing user',
        build: () {
          when(
            () => mockAuthRepository.loginWithPin(
              nationalId: '900111222',
              pin: '0000',
            ),
          ).thenAnswer((_) async => null);
          when(() => mockAuthRepository.nationalIdExists('900111222'))
              .thenAnswer((_) async => true);
          return AuthBloc(
            authRepository: mockAuthRepository,
            sessionStore: mockSessionStore,
          );
        },
        act: (bloc) => bloc.add(
          const PinLoginRequestedEvent(
            nationalId: '900111222',
            pin: '0000',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthFailure(Strings.loginError),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthSwitchToRegister] when national ID is not registered',
        build: () {
          when(
            () => mockAuthRepository.loginWithPin(
              nationalId: '900999999',
              pin: '1234',
            ),
          ).thenAnswer((_) async => null);
          when(() => mockAuthRepository.nationalIdExists('900999999'))
              .thenAnswer((_) async => false);
          return AuthBloc(
            authRepository: mockAuthRepository,
            sessionStore: mockSessionStore,
          );
        },
        act: (bloc) => bloc.add(
          const PinLoginRequestedEvent(
            nationalId: '900999999',
            pin: '1234',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthSwitchToRegister(nationalId: '900999999'),
        ],
      );
    });
  });
}
