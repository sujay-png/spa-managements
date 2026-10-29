import 'package:flutter/material.dart';

/// Breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

/// Extension on BuildContext for quick responsive helpers
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet => screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.tablet;

  /// Returns value based on screen size
  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet ?? desktop;
    return mobile;
  }
}

/// Responsive layout builder widget
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
        if (constraints.maxWidth >= Breakpoints.tablet) return desktop;
        if (constraints.maxWidth >= Breakpoints.mobile) return tablet ?? desktop;
        return mobile;
      },
    );
  }
}
