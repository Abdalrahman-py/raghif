import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/bloc/auth_bloc.dart';

/// Mock verification: auto-approves after a short delay (VerificationApprovedEvent).
/// Real ID/face-match, and a rejection path, are out of scope for this
/// prototype — see spec.md.
class WaitingForVerificationScreen extends StatefulWidget {
  const WaitingForVerificationScreen({super.key});

  @override
  State<WaitingForVerificationScreen> createState() => _WaitingForVerificationScreenState();
}

class _WaitingForVerificationScreenState extends State<WaitingForVerificationScreen> {
  bool _approved = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _approved = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_approved) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      Strings.verifyingTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      Strings.verifyingBody,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.check_circle,
                      size: 96,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      Strings.verifiedTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      Strings.verifiedBody,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      text: Strings.continueToApp,
                      onPressed: () {
                        context.read<AuthBloc>().add(const VerificationApprovedEvent());
                        // The ID/selfie/waiting steps are all pushed routes;
                        // pop back to the state-driven root so it can swap
                        // to StoreListScreen now that isVerified is true.
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
