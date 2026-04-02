import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:ameko_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/welcome_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/auth_choice_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:ameko_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:ameko_app/features/home/presentation/screens/home_screen.dart';
import 'package:ameko_app/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:ameko_app/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:ameko_app/features/order/domain/entities/order_entity.dart';
import 'package:ameko_app/features/order/presentation/screens/order_detail_screen.dart';
import 'package:ameko_app/features/order/presentation/screens/order_list_screen.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_event.dart';
import 'package:ameko_app/injection_container.dart';

class AppRouter {
  static const splash = '/';
  static const welcome = '/welcome';
  static const authChoice = '/auth';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const home = '/home';
  static const chat = '/chat';
  static const chatDetail = '/chat/:id';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const profile = '/profile';
  static const resetPassword = '/reset-password';

  static GoRouter createRouter(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return GoRouter(
      initialLocation: splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoading = authState is AuthLoading;
        final isAuthenticated = authState is AuthSuccess;
        final loc = state.matchedLocation;

        // Don't redirect while loading or on splash
        if (isLoading || loc == splash) return null;

        final isOnAuthRoute = [
          welcome,
          authChoice,
          login,
          register,
          forgotPassword,
          otp,
          resetPassword,
        ].contains(loc);

        if (isAuthenticated && isOnAuthRoute) return home;
        if (!isAuthenticated && !isOnAuthRoute) return authChoice;

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: welcome,
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: authChoice,
          builder: (_, __) => const AuthChoiceScreen(),
        ),
        GoRoute(
          path: login,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen(),
        ),
      GoRoute(
        path: otp,
        builder: (_, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: resetPassword,
        builder: (_, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
        // Shell route for bottom nav
        ShellRoute(
          builder: (context, state, child) {
            return BlocProvider(
              create: (context) => sl<ChatListBloc>()..add(FetchConversations()),
              child: HomeScreen(child: child),
            );
          },
          routes: [
            GoRoute(
              path: home,
              builder: (_, __) => const HomeBodyPlaceholder(),
            ),
            GoRoute(
              path: chat,
              builder: (_, __) => const ChatListScreen(),
            ),
            GoRoute(
              path: '/chat/:id',
              builder: (_, state) {
                final id = state.pathParameters['id'] ?? '';
                return ChatDetailScreen(chatId: id);
              },
            ),
            GoRoute(
              path: orders,
              builder: (_, __) => const OrderListScreen(),
            ),
            GoRoute(
              path: '/orders/:id',
              builder: (_, state) {
                final id = state.pathParameters['id'] ?? '';
                final order = state.extra as OrderEntity?;
                return OrderDetailScreen(orderId: id, order: order);
              },
            ),
            GoRoute(
              path: profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.matchedLocation}'),
        ),
      ),
    );
  }
}

/// Stream refresh notifier for GoRouter redirect on BLoC state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
