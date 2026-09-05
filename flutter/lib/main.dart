import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/onboarding/onboarding_store.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/demo_accounts.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/queue/owner_dashboard_screen.dart';
import 'features/queue/queue_controller.dart';
import 'features/queue/store_list_screen.dart';
import 'features/verification/photo_capture_screen.dart';
import 'features/verification/waiting_for_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const RaghifApp());
}

class RaghifApp extends StatefulWidget {
  const RaghifApp({super.key, this.authBloc, this.queueController});

  /// Test seam: inject a pre-built bloc instead of resolving one from [sl].
  final AuthBloc? authBloc;
  final QueueController? queueController;

  @override
  State<RaghifApp> createState() => _RaghifAppState();
}

class _RaghifAppState extends State<RaghifApp> {
  late final QueueController _controller;
  late final AuthBloc _authBloc;

  /// null while loading, then whether the intro carousel has been seen —
  /// shown once per install, ahead of login/registration.
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _controller = widget.queueController ??
        (sl.isRegistered<QueueController>()
            ? sl<QueueController>()
            : QueueController());
    _authBloc = (widget.authBloc ?? sl<AuthBloc>())
      ..add(const CheckAuthSessionEvent());
    OnboardingStore().hasSeenOnboarding().then((seen) {
      if (mounted) setState(() => _hasSeenOnboarding = seen);
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp(
        title: 'رغيف',
        theme: AppTheme.light,
        // Forced RTL regardless of device locale — this app is Arabic-only.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is Authenticated) {
              // Owners are pre-verified (seeded accounts); buyers go through
              // mock ID/selfie capture once before they can buy.
              if (!state.user.isOwner && !state.user.isVerified) {
                return PhotoCaptureScreen(
                  kind: PhotoCaptureKind.id,
                  onContinue: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PhotoCaptureScreen(
                        kind: PhotoCaptureKind.selfie,
                        onContinue: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const WaitingForVerificationScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final demoUser = DemoUser(
                id: state.user.id,
                phone: state.user.phone,
                pin: '',
                role: state.user.isOwner ? UserRole.owner : UserRole.buyer,
                name: state.user.name,
                jawwalPayNumber: state.user.jawwalPayNumber,
              );

              return state.user.isOwner
                  ? OwnerDashboardScreen(
                      controller: _controller,
                      storeId: demoOwnerStoreId,
                    )
                  : StoreListScreen(
                      controller: _controller,
                      currentUser: demoUser,
                    );
            }

            // Unauthenticated, AuthLoading (session check or a login/register
            // submit in flight), AuthFailure, AuthSwitchToRegister — all show
            // the login form (after the once-per-install intro carousel);
            // LoginScreen reads AuthBloc state itself for its own
            // loading/error UI.
            if (_hasSeenOnboarding == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (_hasSeenOnboarding == false) {
              return OnboardingScreen(
                onDone: () => setState(() => _hasSeenOnboarding = true),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
