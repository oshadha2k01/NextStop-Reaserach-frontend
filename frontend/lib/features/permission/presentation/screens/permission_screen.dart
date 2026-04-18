import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/flow_surface_card.dart';
import '../../../../core/widgets/primary_button.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  int _currentStep = 0;

  final List<PermissionStep> _steps = const [
    PermissionStep(
      icon: Icons.location_on_outlined,
      title: 'Enable Location',
      description:
          'We use your location to find nearby bus stops and provide accurate ETAs.',
      buttonText: 'Allow Location',
    ),
    PermissionStep(
      icon: Icons.notifications_active_outlined,
      title: 'Enable Notifications',
      description:
          'Get live alerts for arrivals, route changes, and trip reminders.',
      buttonText: 'Allow Notifications',
    ),
  ];

  void _onAllow() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/registration');
    }
  }

  void _onSkip() {
    Navigator.of(context).pushReplacementNamed('/registration');
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps[_currentStep];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF8), Color(0xFFF7F8FA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: FlowSurfaceCard(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => _StepDot(active: _currentStep == index),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFE8),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFDFC8)),
                    ),
                    child: Icon(current.icon, size: 54, color: AppColors.primary),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    current.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    current.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: current.buttonText,
                    onPressed: _onAllow,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active});

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

class PermissionStep {
  const PermissionStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
}
