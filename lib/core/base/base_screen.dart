import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

/// Scaffold wrapper enforcing consistent screen layout.
/// All screens should extend or use BaseScreen.
class BaseScreen extends StatelessWidget {
  const BaseScreen({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showAppBar = false,
    this.showBackButton = true,
    this.centerContent = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showAppBar;
  final bool showBackButton;
  final bool centerContent;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard on tap
      child: Scaffold(
        backgroundColor: backgroundColor ?? AppColors.background,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: showAppBar ? _buildAppBar(context) : null,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: SafeArea(
          child: centerContent
              ? Center(
                  child: SingleChildScrollView(
                    padding: padding,
                    child: body,
                  ),
                )
              : Padding(
                  padding: padding,
                  child: body,
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surface,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      title: title != null
          ? Text(title!, style: AppTextStyles.subheading)
          : null,
      actions: actions,
    );
  }
}
