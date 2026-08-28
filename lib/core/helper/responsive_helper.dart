import 'package:flutter/material.dart';
import '../constant/app_sizes.dart';

/// Responsive viewport detection helper
class ResponsiveHelper {
  ResponsiveHelper._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppSizes.tabletBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppSizes.tabletBreakpoint && width < AppSizes.desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppSizes.desktopBreakpoint;

  static double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double screenHeight(BuildContext context) => MediaQuery.sizeOf(context).height;
}

/// Adaptive Layout Builder
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.desktopBreakpoint) {
          return desktop;
        } else if (constraints.maxWidth >= AppSizes.tabletBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
