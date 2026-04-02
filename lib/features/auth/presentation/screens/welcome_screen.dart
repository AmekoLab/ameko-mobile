import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/router/app_router.dart';
import 'package:ameko_app/core/widgets/app_avatar_circle.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;

  static const _avatars = [
    _AvatarData(name: 'Alex Chen', x: -0.5, y: -0.6),
    _AvatarData(name: 'Maria S', x: 0.3, y: -0.8),
    _AvatarData(name: 'David K', x: -0.7, y: 0.1),
    _AvatarData(name: 'Lena M', x: 0.6, y: 0.0),
    _AvatarData(name: 'Jake R', x: -0.2, y: 0.7),
    _AvatarData(name: 'Priya N', x: 0.5, y: 0.6),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _avatars.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + i * 150),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Floating avatars
            ...List.generate(_avatars.length, (i) {
              final avatar = _avatars[i];
              final dx = size.width / 2 + avatar.x * size.width * 0.38;
              final dy = size.height * 0.3 + avatar.y * size.height * 0.22;
              final rad = 28.0 + (i % 3) * 8.0;

              return Positioned(
                left: dx - rad,
                top: dy - rad,
                child: FadeTransition(
                  opacity: _controllers[i],
                  child: SlideTransition(
                    position: _animations[i],
                    child: AppAvatarCircle(
                      name: avatar.name,
                      radius: rad,
                      borderColor: AppColors.surface,
                      borderWidth: 2.5,
                    ),
                  ),
                ),
              );
            }),

            // Bottom content
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome to Ameko',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Discover and buy premium custom keyboards\nfrom makers around the world.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 36),
                  TextButton.icon(
                    onPressed: () => context.go(AppRouter.authChoice),
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: Text(
                      'Skip',
                      style: AppTextStyles.link,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarData {
  final String name;
  final double x;
  final double y;
  const _AvatarData({required this.name, required this.x, required this.y});
}
