import 'package:flutter/material.dart';
import '../../core/i18n/strings.dart';
import '../../core/onboarding/onboarding_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../auth/registration_screen.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    Icons.shopping_bag_outlined,
    Strings.onboardingTitle1,
    Strings.onboardingBody1,
  ),
  _Slide(
    Icons.notifications_active_outlined,
    Strings.onboardingTitle2,
    Strings.onboardingBody2,
  ),
  _Slide(
    Icons.verified_user_outlined,
    Strings.onboardingTitle3,
    Strings.onboardingBody3,
  ),
];

/// First-run intro carousel. Shown once per install (OnboardingStore), then
/// hands off to registration (new users) or login (returning users).
///
/// Three slides is short enough that the last one carries the decision: the
/// primary action turns into "إنشاء حساب" and logging in becomes a real
/// secondary button, so a returning user never has to find the small skip link
/// to get back into their account.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageAnimation = Duration(milliseconds: 250);

  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingStore().markSeen();
    widget.onDone();
  }

  void _goToRegistration() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationScreen()));
    _finish();
  }

  /// Hands off without pushing: main.dart swaps the root child to the login
  /// screen, so pushing a second copy here only stacked two identical screens
  /// and made the system back gesture appear to do nothing.
  void _goToLogin() {
    _finish();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: _pageAnimation,
      curve: Curves.easeOut,
    );
  }

  void _next() {
    _pageController.nextPage(duration: _pageAnimation, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  // RTL puts the first child on the right, so the step counter
                  // reads first and "تخطي" takes the trailing corner.
                  Expanded(
                    child: Text(
                      Strings.onboardingPageOf(_page + 1, _slides.length),
                      style: textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(Strings.onboardingSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _PageDots(page: _page, count: _slides.length, onTap: _goToPage),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    text: isLast
                        ? Strings.onboardingGetStarted
                        : Strings.onboardingNext,
                    onPressed: isLast ? _goToRegistration : _next,
                  ),
                  if (isLast) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      text: Strings.onboardingHaveAccount,
                      onPressed: _goToLogin,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One slide: artwork badge, headline, body.
///
/// Scrollable, and the badge shrinks on short screens, so the 320x640dp
/// deployment target can never push the copy out of the viewport (a RenderFlex
/// overflow here would be a red-striped first impression).
class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 400;
        final badge = compact ? 120.0 : 152.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: badge,
                  height: badge,
                  decoration: const BoxDecoration(
                    color: AppColors.accentContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    slide.icon,
                    size: compact ? 56 : 72,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Page indicator. Each dot is a real target: 48dp of hit area around an 8dp
/// mark, and it announces the page it leads to, because three unlabelled dots
/// are invisible to a screen reader.
class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.page,
    required this.count,
    required this.onTap,
  });

  final int page;
  final int count;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == page;
        return Semantics(
          label: Strings.onboardingPageOf(i + 1, count),
          selected: selected,
          button: true,
          child: InkResponse(
            key: ValueKey('onboarding-dot-$i'),
            onTap: () => onTap(i),
            radius: 24,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
