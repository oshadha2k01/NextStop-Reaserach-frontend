import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flow_surface_card.dart';
import '../../../../core/widgets/primary_button.dart';

class Onboarding2Screen extends StatelessWidget {
  const Onboarding2Screen({super.key});

  void _onGetStarted(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/permission');
  }

  void _onPrevious(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF8), Color(0xFFF7F8FA)],
          ),
        ),
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 0) {
              _onPrevious(context);
            } else if ((details.primaryVelocity ?? 0) < 0) {
              _onGetStarted(context);
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: FlowSurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _onPrevious(context),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Step 2/2',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/onboarding.png',
                            height: 260,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Track Your Bus in Real Time',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Know where your bus is, predict crowd levels, and reach your stop with confidence.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_Dot(false), _Dot(true)],
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Get Started',
                      onPressed: () => _onGetStarted(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.active);

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 9,
      height: 9,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : const Color(0xFFD8DEE6),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
