import 'package:flutter/material.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  int _currentStep = 0;

  final List<PermissionStep> _steps = [
    PermissionStep(
      icon: Icons.location_on,
      title: 'Enable Location',
      description: 'We need your location to find nearby bus stops and provide accurate arrival times.',
      buttonText: 'Allow',
    ),
    PermissionStep(
      icon: Icons.notifications,
      title: 'Enable Notifications',
      description: 'Get real-time updates about your bus arrivals and route changes.',
      buttonText: 'Allow',
    ),
  ];

  void _onAllow() async {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Last step - navigate to registration
      Navigator.of(context).pushReplacementNamed('/registration');
    }
  }

  void _onSkip() {
    Navigator.of(context).pushReplacementNamed('/registration');
  }

  @override
  Widget build(BuildContext context) {
    final currentPermission = _steps[_currentStep];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => _buildStepDot(index),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentPermission.icon,
                  size: 60,
                  color: const Color(0xFFFF6B35),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                currentPermission.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Description
              Text(
                currentPermission.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              
              const Spacer(),
              
              // Allow button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onAllow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    currentPermission.buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Skip button
              TextButton(
                onPressed: _onSkip,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentStep == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentStep == index ? const Color(0xFFFF6B35) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class PermissionStep {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;

  PermissionStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}
