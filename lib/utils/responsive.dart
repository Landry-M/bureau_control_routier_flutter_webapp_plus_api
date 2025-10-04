import 'package:flutter/widgets.dart';

/// Simple responsive utilities and breakpoints for the app.
/// Usage:
///   - if (Responsive.isMobile(context)) ...
///   - Responsive.value(context, mobile: 8, tablet: 12, desktop: 16)
///   - ResponsiveBuilder(builder: (context, bp) { ... })
class Responsive {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static Breakpoint breakpointOfWidth(double width) {
    if (width < mobileMax) return Breakpoint.mobile;
    if (width < tabletMax) return Breakpoint.tablet;
    return Breakpoint.desktop;
  }

  static Breakpoint of(BuildContext context) =>
      breakpointOfWidth(MediaQuery.sizeOf(context).width);

  static bool isMobile(BuildContext context) =>
      of(context) == Breakpoint.mobile;
  static bool isTablet(BuildContext context) =>
      of(context) == Breakpoint.tablet;
  static bool isDesktop(BuildContext context) =>
      of(context) == Breakpoint.desktop;

  static T value<T>(BuildContext context,
      {required T mobile, T? tablet, T? desktop}) {
    final bp = of(context);
    switch (bp) {
      case Breakpoint.mobile:
        return mobile;
      case Breakpoint.tablet:
        return tablet ?? mobile;
      case Breakpoint.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

enum Breakpoint { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, Breakpoint breakpoint) builder;
  @override
  Widget build(BuildContext context) =>
      builder(context, Responsive.of(context));
}

class ResponsiveVisibility extends StatelessWidget {
  const ResponsiveVisibility(
      {super.key,
      this.visibleOn = const {Breakpoint.desktop},
      required this.child});
  final Set<Breakpoint> visibleOn;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return visibleOn.contains(Responsive.of(context))
        ? child
        : const SizedBox.shrink();
  }
}
