import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

/// Shown while the app works out who is signed in. A short, light animation:
/// the logo pops in on a white disc with two soft rings, the name and tagline
/// rise in behind it, and three dots pulse underneath for as long as loading
/// lasts. Nothing here delays start-up: it only fills the time that loading
/// already takes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // The intro (0..1) plays over the first 0.55 of the loop, then holds.
  double _intro(double t, double from, double to) => Curves.easeOutCubic
      .transform(((t * 1.0 - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bread, AppColors.accentPressed],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final pop = Curves.easeOutBack.transform(
              (t / 0.28).clamp(0.0, 1.0),
            );
            final textIn = _intro(t, 0.18, 0.42);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final delay in const [0.0, 0.33])
                        _Ring(progress: ((t + 1 - delay) % 1.0)),
                      Transform.scale(
                        scale: 0.4 + 0.6 * pop,
                        child: Opacity(
                          opacity: pop.clamp(0.0, 1.0),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(26),
                            child: SvgPicture.asset(
                              'assets/images/stitch_loaf.svg',
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: textIn,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - textIn)),
                    child: const Column(
                      children: [
                        Text(
                          'رغيف',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'خبزك بدون ازدحام',
                          style: TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _Dots(progress: t),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 120 + 100 * progress;
    return Opacity(
      opacity: (1 - progress) * 0.35,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Opacity(
            opacity:
                0.35 + 0.65 * (((progress * 3) - i) % 1.0 < 0.5 ? 1.0 : 0.0),
            child: const SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
