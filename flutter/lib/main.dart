import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/connectivity/connectivity_banner.dart';
import 'core/connectivity/connectivity_monitor.dart';
import 'core/di/injection.dart';
import 'core/i18n/strings.dart';
import 'core/onboarding/onboarding_store.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_notice.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/demo_accounts.dart';
import 'features/guest/guest_home_screen.dart';
import 'features/guest/pending_booking.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/navigation/buyer_shell.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/repositories/queue_repository.dart';
import 'features/navigation/owner_shell.dart';
import 'domain/models/store_model.dart';
import 'features/queue/queue_controller.dart';
import 'features/verification/wallet_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const RaghifApp());
  startPushLater();
}

class RaghifApp extends StatefulWidget {
  const RaghifApp({
    super.key,
    this.authBloc,
    this.queueController,
    this.guestRepository,
  });

  /// Test seam: inject a pre-built bloc instead of resolving one from [sl].
  final AuthBloc? authBloc;
  final QueueController? queueController;

  /// Read-only bakery source for the signed-out screen; [sl] when null.
  final QueueRepository? guestRepository;

  @override
  State<RaghifApp> createState() => _RaghifAppState();
}

class _RaghifAppState extends State<RaghifApp> {
  late final QueueController _controller;
  late final AuthBloc _authBloc;
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// null while loading, then whether the intro carousel has been seen —
  /// shown once per install, ahead of login/registration.
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.queueController ??
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
      // The root route below swaps between login and home by auth state,
      // but routes pushed on top of it (store list, receipt, registration)
      // would survive the swap: signing out from the store list left it on
      // screen with the login form hidden underneath, one back press away.
      // Crossing the signed-in/signed-out line clears them, whichever screen
      // it happened on.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            (prev is Authenticated ? prev.user.id : null) !=
            (curr is Authenticated ? curr.user.id : null),
        listener: (prev, _) {
          // The saved offline copy is wiped only when a signed-in person
          // leaves. Starting the app (signed out -> restored session) must
          // keep it, or it would be erased before an offline start can read it.
          _controller.resetForSession(clearCache: prev is Authenticated);
          _navigatorKey.currentState?.popUntil((route) => route.isFirst);
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'رغيف',
          theme: AppTheme.light,
          // Forced RTL regardless of device locale — this app is Arabic-only.
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: sl.isRegistered<ConnectivityMonitor>()
                ? ConnectivityBanner(
                    monitor: sl<ConnectivityMonitor>(),
                    child: child!,
                  )
                : child!,
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthInitial) return const SplashScreen();

              if (state is Authenticated) {
                // Owners are seeded as verified; a buyer confirms the Jawwal
                // Pay number once before they can book.
                if (!state.user.isOwner && !state.user.isVerified) {
                  return WalletVerificationScreen(
                    key: ValueKey('verify-${state.user.id}'),
                    number: state.user.phone,
                    busy: state.profileSaving,
                    error: state.profileError,
                    onVerify: (code) => context.read<AuthBloc>().add(
                      WalletVerificationRequestedEvent(code: code),
                    ),
                    onLogout: () => context.read<AuthBloc>().add(
                      const LogoutRequestedEvent(),
                    ),
                  );
                }

                final demoUser = DemoUser(
                  id: state.user.id,
                  phone: state.user.phone,
                  pin: '',
                  role: state.user.isOwner ? UserRole.owner : UserRole.buyer,
                  name: state.user.name,
                );

                return state.user.isOwner
                    ? _OwnerHome(
                        controller: _controller,
                        ownerId: state.user.id,
                      )
                    : BuyerShell(
                        key: ValueKey(state.user.id),
                        openStoreId: PendingBooking.take(),
                        controller: _controller,
                        currentUser: demoUser,
                        notifications: sl.isRegistered<NotificationRepository>()
                            ? sl<NotificationRepository>()
                            : null,
                      );
              }

              // Unauthenticated, AuthLoading (session check or a login/register
              // submit in flight), AuthFailure, AuthSwitchToRegister — all show
              // the guest screen (after the once-per-install intro carousel);
              // the login and registration screens it opens read AuthBloc
              // state themselves for their own loading/error UI.
              if (_hasSeenOnboarding == null) return const SplashScreen();
              if (_hasSeenOnboarding == false) {
                return OnboardingScreen(
                  onDone: () => setState(() => _hasSeenOnboarding = true),
                );
              }
              // Not signed in: show what the app does first; an account is
              // only asked for when the visitor chooses to book or sign up.
              return GuestHomeScreen(
                repository: widget.guestRepository ?? sl<QueueRepository>(),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Resolves which store this owner manages before showing the dashboard.
///
/// Used to be a hardcoded `demoOwnerStoreId = 1`, which only worked because
/// every install seeded its own store #1 locally. Ownership is a server
/// fact now (`stores.owner_id`), so it has to be asked for.
class _OwnerHome extends StatefulWidget {
  const _OwnerHome({required this.controller, required this.ownerId});

  final QueueController controller;
  final String ownerId;

  @override
  State<_OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<_OwnerHome> {
  late Future<StoreModel?> _store;

  @override
  void initState() {
    super.initState();
    _store = widget.controller.storeForOwner(widget.ownerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoreModel?>(
      future: _store,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: OfflineNotice(
              onRetry: () => setState(() {
                _store = widget.controller.storeForOwner(widget.ownerId);
              }),
            ),
          );
        }
        final store = snapshot.data;
        if (store == null) {
          // An owner account with no store attached. Better to say so than
          // to guess at a store and let them manage someone else's queue.
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  Strings.noStoreForOwner,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return OwnerShell(controller: widget.controller, storeId: store.id);
      },
    );
  }
}
