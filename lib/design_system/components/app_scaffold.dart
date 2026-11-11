import 'package:flutter/material.dart';

/// Standard scaffold for the My Sweet Home app.
///
/// Standardizes the visual look of [Scaffold] and [AppBar] (Material 3, no
/// exaggerated elevation, theme colors) across all screens.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.appBar,
    this.showAppBar = true,
    this.centerTitle = false,
    this.padding,
    this.drawer,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final PreferredSizeWidget? appBar;
  final bool showAppBar;
  final bool centerTitle;
  final EdgeInsetsGeometry? padding;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    PreferredSizeWidget? effectiveAppBar = appBar;
    if (effectiveAppBar == null &&
        showAppBar &&
        (title != null ||
            titleWidget != null ||
            leading != null ||
            actions != null)) {
      effectiveAppBar = AppBar(
        title: titleWidget ?? (title != null ? Text(title!) : null),
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        elevation: 0,
        scrolledUnderElevation: 1,
      );
    }

    Widget? effectiveBody = body;
    if (padding != null && effectiveBody != null) {
      effectiveBody = Padding(padding: padding!, child: effectiveBody);
    }

    return Scaffold(
      appBar: effectiveAppBar,
      body: effectiveBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
    );
  }
}
