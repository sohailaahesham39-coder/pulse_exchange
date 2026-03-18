import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/AppRoutes.dart';
import '../../widget/common/CustomButton.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _monitorAnimationController;
  late AnimationController _medExchangeAnimationController;
  late AnimationController _communityAnimationController;

  // Animations
  late Animation<double> _monitorScaleAnimation;
  late Animation<double> _monitorPulseAnimation;
  late Animation<double> _medExchangeSlideAnimation;
  late Animation<double> _medExchangeRotateAnimation;
  late Animation<double> _communityScaleAnimation;
  late Animation<Offset> _communitySlideAnimation;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Monitor Your Blood Pressure',
      'description': 'Track your BP readings with ease using our connected devices or manual input.',
      'animationType': 'monitor',
    },
    {
      'title': 'Exchange Medications',
      'description': 'Connect with your community to exchange unused medications safely.',
      'animationType': 'exchange',
    },
    {
      'title': 'Stay Connected',
      'description': 'Share your health journey and get support from our community.',
      'animationType': 'community',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _monitorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _medExchangeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _communityAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Set up animations
    _monitorScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _monitorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _monitorPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _monitorAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _medExchangeSlideAnimation = Tween<double>(begin: -50.0, end: 50.0).animate(
      CurvedAnimation(
        parent: _medExchangeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _medExchangeRotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _medExchangeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _communityScaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _communityAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _communitySlideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0.0),
      end: const Offset(0.1, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _communityAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _monitorAnimationController.dispose();
    _medExchangeAnimationController.dispose();
    _communityAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // Reset animations when page changes
    switch (index) {
      case 0:
        _monitorAnimationController.reset();
        _monitorAnimationController.repeat(reverse: true);
        break;
      case 1:
        _medExchangeAnimationController.reset();
        _medExchangeAnimationController.repeat();
        break;
      case 2:
        _communityAnimationController.reset();
        _communityAnimationController.repeat(reverse: true);
        break;
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                return _buildOnboardingPage(
                  title: _onboardingData[index]['title'],
                  description: _onboardingData[index]['description'],
                  animationType: _onboardingData[index]['animationType'],
                );
              },
            ),
            // Page indicator
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                      (index) => _buildPageIndicator(index),
                ),
              ),
            ),
            // Navigation buttons
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage != _onboardingData.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  CustomButton(
                    label: _currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    isFullWidth: false,
                    height: 50,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String title,
    required String description,
    required String animationType,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: _buildAnimation(animationType),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimation(String animationType) {
    switch (animationType) {
      case 'monitor':
        return _buildMonitorAnimation();
      case 'exchange':
        return _buildMedExchangeAnimation();
      case 'community':
        return _buildCommunityAnimation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMonitorAnimation() {
    return AnimatedBuilder(
      animation: _monitorAnimationController,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device monitor
              Transform.scale(
                scale: _monitorScaleAnimation.value,
                child: Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Heart rate line
                      CustomPaint(
                        size: const Size(180, 60),
                        painter: HeartRatePainter(
                          progress: _monitorPulseAnimation.value,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // BP reading
                      Text(
                        '120/80 mmHg',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Base of monitor
              Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedExchangeAnimation() {
    return AnimatedBuilder(
      animation: _medExchangeAnimationController,
      builder: (context, child) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // First pill moving
              Transform.translate(
                offset: Offset(_medExchangeSlideAnimation.value, 0),
                child: Transform.rotate(
                  angle: _medExchangeRotateAnimation.value * math.pi,
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              // Second pill moving in opposite direction
              Transform.translate(
                offset: Offset(-_medExchangeSlideAnimation.value, 40),
                child: Transform.rotate(
                  angle: -_medExchangeRotateAnimation.value * math.pi,
                  child: Container(
                    width: 80,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              // Third pill
              Transform.translate(
                offset: Offset(_medExchangeSlideAnimation.value * 0.5, -40),
                child: Transform.rotate(
                  angle: _medExchangeRotateAnimation.value * 1.5 * math.pi,
                  child: Container(
                    width: 60,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12.5),
                    ),
                  ),
                ),
              ),

              // Arrow icon
              Icon(
                Icons.sync,
                size: 60,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityAnimation() {
    return AnimatedBuilder(
      animation: _communityAnimationController,
      builder: (context, child) {
        return Center(
          child: SlideTransition(
            position: _communitySlideAnimation,
            child: Transform.scale(
              scale: _communityScaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Community circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Person icons representing community
                  Positioned(
                    top: 40,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 50,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    right: 50,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),

                  // Connection lines
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: ConnectionsPainter(
                      progress: _communityAnimationController.value,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Custom Painters for animations

class HeartRatePainter extends CustomPainter {
  final double progress;
  final Color color;

  HeartRatePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();

    // Calculate how much of the heartbeat to draw based on progress
    final drawWidth = size.width * progress;

    // Starting point
    path.moveTo(0, size.height / 2);

    // Normal line
    path.lineTo(size.width * 0.2, size.height / 2);

    if (progress > 0.2) {
      // Upward spike
      path.lineTo(size.width * 0.3, size.height * 0.2);
    }

    if (progress > 0.3) {
      // Downward spike
      path.lineTo(size.width * 0.4, size.height * 0.8);
    }

    if (progress > 0.4) {
      // Big upward spike (heartbeat)
      path.lineTo(size.width * 0.5, size.height * 0.1);
    }

    if (progress > 0.5) {
      // Return to baseline
      path.lineTo(size.width * 0.6, size.height / 2);
    }

    if (progress > 0.6) {
      // Small bump
      path.lineTo(size.width * 0.7, size.height * 0.4);
    }

    if (progress > 0.7) {
      // Back to baseline
      path.lineTo(size.width * 0.8, size.height / 2);
    }

    if (progress > 0.8) {
      // Continue baseline to end
      path.lineTo(size.width, size.height / 2);
    }

    // Only draw the visible part based on progress
    final metric = path.computeMetrics().first;
    final extractPath = metric.extractPath(0, metric.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(HeartRatePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class ConnectionsPainter extends CustomPainter {
  final double progress;
  final Color color;

  ConnectionsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw connection lines between people icons
    // Center to top
    _drawAnimatedLine(
        canvas,
        paint,
        Offset(size.width / 2, size.height / 2),
        Offset(size.width / 2, 40),
        progress
    );

    // Center to bottom left
    _drawAnimatedLine(
        canvas,
        paint,
        Offset(size.width / 2, size.height / 2),
        Offset(50, size.height - 40),
        progress
    );

    // Center to bottom right
    _drawAnimatedLine(
        canvas,
        paint,
        Offset(size.width / 2, size.height / 2),
        Offset(size.width - 50, size.height - 40),
        progress
    );
  }

  void _drawAnimatedLine(Canvas canvas, Paint paint, Offset start, Offset end, double progress) {
    // Calculate the point along the line according to progress
    final dx = start.dx + (end.dx - start.dx) * progress;
    final dy = start.dy + (end.dy - start.dy) * progress;

    canvas.drawLine(start, Offset(dx, dy), paint);
  }

  @override
  bool shouldRepaint(ConnectionsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}