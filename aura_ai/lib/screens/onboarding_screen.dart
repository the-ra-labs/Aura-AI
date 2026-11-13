import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/ai_orb.dart';
import '../widgets/buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  static const _pages = [
    (null, 'Smart AI Assistant',
        'Sawal poochein, likhwayen, code karwayen. Aura aap ki zubaan mein jawab deta hai.',
        [AppColors.violet, AppColors.purple]),
    (Icons.mic_rounded, 'Voice & Files',
        'Bol kar poochein, images ya files attach karein, aur jawab sunein.',
        [AppColors.cyan, AppColors.violet]),
    (Icons.folder_rounded, 'Projects & Control',
        'Chats ko projects mein organize karein aur AI ko apne hisab se customize karein.',
        [AppColors.gold, AppColors.pink]),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Widget _hero((IconData?, String, String, List<Color>) p) {
    if (p.$1 == null) return const AiOrb(size: 280);
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(alignment: Alignment.center, children: [
        for (final s in const [270.0, 210.0])
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: p.$4.first.withOpacity(0.25)),
            ),
          ),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.$4),
            boxShadow: [
              BoxShadow(
                  color: p.$4.first.withOpacity(0.55),
                  blurRadius: 50,
                  spreadRadius: 4),
            ],
          ),
          child: Icon(p.$1, size: 68, color: Colors.white),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: widget.onDone, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (v) => setState(() => _i = v),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _hero(p),
                            const SizedBox(height: 36),
                            Text(p.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 14),
                            Text(p.$3,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                    height: 1.5)),
                          ]),
                    );
                  },
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var k = 0; k < _pages.length; k++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.all(4),
                    width: k == _i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: k == _i ? AppColors.brand : null,
                      color: k == _i ? null : Colors.white24,
                    ),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.all(24),
                child: GradientButton(
                  label: last ? 'Get started' : 'Next',
                  onTap: () => last
                      ? widget.onDone()
                      : _pc.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}