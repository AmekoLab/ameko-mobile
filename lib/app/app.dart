import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/core/router/app_router.dart';
import 'package:ameko_app/core/theme/app_theme.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/injection_container.dart';

class AmekoApp extends StatefulWidget {
  const AmekoApp({super.key});

  @override
  State<AmekoApp> createState() => _AmekoAppState();
}

class _AmekoAppState extends State<AmekoApp> {
  late final AuthBloc _authBloc;
  late final _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _router = AppRouter.createRouter(context);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: _AppWithRouter(
        authBloc: _authBloc,
      ),
    );
  }
}

class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter({required this.authBloc});
  final AuthBloc authBloc;

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
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
