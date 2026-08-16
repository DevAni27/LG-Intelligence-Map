import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../navigation/main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const Color _background = Color(0xFF0F172A);
  static const Color _cardColor = Color(0xFF111C31);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _secondaryText = Color(0xFF94A3B8);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < 2) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final box = Hive.box('settings_box');

    await box.put('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildIntroPage(),
                  _buildSetupPage(),
                  _buildCreditsPage(),
                ],
              ),
            ),

            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  //page 1

  Widget _buildIntroPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),

          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.18),
                  blurRadius: 55,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/lg_logo.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 76),

          const Text(
            'See the world as one\nconnected story.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Global Pulse transforms live global events into an immersive '
            '3D intelligence map — combining real-time data, Liquid Galaxy '
            'visualization and AI-powered explanations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 190, 203, 222),
              fontSize: 16,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 34),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _featureBadge(
                icon: Icons.public,
                label: 'LIVE EVENTS',
              ),
              _featureBadge(
                icon: Icons.language,
                label: '3D WORLD',
              ),
              _featureBadge(
                icon: Icons.auto_awesome,
                label: 'AI INSIGHTS',
              ),
            ],
          ),

          const Spacer(),
        ],
      ),
    );
  }

  //page 2

  Widget _buildSetupPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),

          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: _cyan.withValues(alpha: 0.09),
                border: Border.all(
                  color: _cyan.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.settings_input_antenna,
                color: _cyan,
                size: 46,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Connect your\nLiquid Galaxy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'Get your rig ready in three simple steps.',
              style: TextStyle(
                color: Color.fromARGB(255, 190, 203, 222),
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 36),

          _setupStep(
            number: '01',
            icon: Icons.settings_outlined,
            title: 'Open Settings',
            description:
                'Go to Settings from the bottom navigation.',
          ),

          _setupDivider(),

          _setupStep(
            number: '02',
            icon: Icons.router_outlined,
            title: 'Connect your LG rig',
            description:
                'Enter the rig details manually.',
          ),

          _setupDivider(),

          _setupStep(
            number: '03',
            icon: Icons.travel_explore,
            title: 'Explore the world',
            description:
                'Open Map, choose a location and send the view to Liquid Galaxy. Press the i button on the map to learn more.',
          ),

          const Spacer(),
        ],
      ),
    );
  }

  //page 3

  Widget _buildCreditsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: _cyan.withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              'GEMINI SUMMER OF CODE 2026',
              style: TextStyle(
                color: _cyan,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Icon(
            Icons.public,
            color: _cyan,
            size: 72,
          ),

          const SizedBox(height: 20),

          const Text(
            'Built with the\nLiquid Galaxy community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Global Pulse was developed through GESOC 2026 '
            'in collaboration with Liquid Galaxy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 190, 203, 222),
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'SPECIAL THANKS',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),

                const SizedBox(height: 18),

                _creditPerson(
                  name: 'Andreu Ibàñez Perales',
                  role: 'Liquid Galaxy Admin',
                ),

                const SizedBox(height: 16),

                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                const SizedBox(height: 16),

                _creditPerson(
                  name: 'Sidharth Mugdil',
                  role: 'Project Mentor',
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          const Text(
            'Built by Aniket Dhingra',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'GESOC 2026 · Liquid Galaxy Lab',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 12,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  //navigation bottom

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Row(
        children: [
          Row(
            children: List.generate(
              3,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 7),
                width: _currentPage == index ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _cyan
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const Spacer(),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == 2
                        ? 'Enter Global Pulse'
                        : 'Continue',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //widgets

  Widget _featureBadge({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _cyan,
              size: 28,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(255, 190, 203, 222),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: _cyan,
            size: 22,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: Color.fromARGB(255, 190, 203, 222),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _setupDivider() {
    return Container(
      margin: const EdgeInsets.only(
        left: 23,
        top: 7,
        bottom: 7,
      ),
      width: 1,
      height: 24,
      color: _cyan.withValues(alpha: 0.18),
    );
  }

  Widget _creditPerson({
    required String name,
    required String role,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _cyan.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.person_outline,
            color: _cyan,
            size: 20,
          ),
        ),

        const SizedBox(width: 13),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role,
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}