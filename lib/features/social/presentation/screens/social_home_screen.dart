import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_bloc.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_event.dart';
import 'package:ameko_app/features/social/presentation/screens/social_feed_screen.dart';
import 'package:ameko_app/features/assembled_product/presentation/screens/assembled_product_list_screen.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_bloc.dart';
import 'package:ameko_app/features/assembled_product/presentation/bloc/assembled_product_list_event.dart';
import 'package:ameko_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ameko_app/features/notification/presentation/bloc/notification_state.dart';
import 'package:ameko_app/injection_container.dart';

class SocialHomeScreen extends StatefulWidget {
  const SocialHomeScreen({super.key});

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.titleSmall,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Khám phá'),
            Tab(text: 'Đang theo dõi'),
            Tab(text: 'Sản phẩm'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (_tabController.index == 2) {
                context.push('/assembled-products/search');
              } else {
                // Handle social search if needed later
              }
            },
            icon: const Icon(Icons.search, color: AppColors.primary),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BlocProvider(
            create: (context) => sl<SocialFeedBloc>()..add(const FetchInitialFeed(isPersonalized: false)),
            child: const SocialFeedScreen(),
          ),
          BlocProvider(
            create: (context) => sl<SocialFeedBloc>()..add(const FetchInitialFeed(isPersonalized: true)),
            child: const SocialFeedScreen(),
          ),
          BlocProvider(
            create: (_) => sl<AssembledProductListBloc>()..add(FetchAssembledProducts()),
            child: const AssembledProductListScreen(),
          ),
        ],
      ),
    );
  }
}
