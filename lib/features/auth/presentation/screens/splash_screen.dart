import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/widgets/app_logo.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/router/app_router.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    // Trigger AppStarted event
    context.read<AuthBloc>().add(const AppStarted());

    // Navigate after splash duration
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _navigateFromSplash();
    });
  }

  void _navigateFromSplash() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) {
      context.go(AppRouter.home);
    } else {
      context.go(AppRouter.welcome);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // If auth resolves before timer, navigate immediately (skip timer delay)
          if (state is AuthSuccess || state is AuthInitial) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _navigateFromSplash();
            });
          }
        },
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 100),
                  const SizedBox(height: 20),
                  Text('Ameko', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Custom Keyboard Marketplace',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
