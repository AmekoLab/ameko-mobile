import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ameko_app/core/router/app_router.dart';
import 'package:ameko_app/core/theme/app_theme.dart';
import 'package:ameko_app/core/utils/app_bloc_observer.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Setup dependency injection
  await setupDependencies();

  // Setup BLoC observer for logging
  Bloc.observer = AppBlocObserver();

  runApp(const AmekoApp());
}

class AmekoApp extends StatelessWidget {
  const AmekoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _RouterWrapper(),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  const _RouterWrapper();

  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  late final router = AppRouter.createRouter(context);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ameko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
