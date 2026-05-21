import 'package:flutter/material.dart';

class AdminLayout {
  static const double maxContentWidth = 760;
  static const double compactWidth = 360;
  static const double wideWidth = 600;

  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 16,
    double bottom = 24,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= wideWidth ? 24.0 : 16.0;
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compactWidth;
  }
}

class AdminContentFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AdminContentFrame({
    super.key,
    required this.child,
    this.maxWidth = AdminLayout.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AdminBottomActionFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AdminBottomActionFrame({
    super.key,
    required this.child,
    this.maxWidth = AdminLayout.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AdminResponsiveActions extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final double spacing;

  const AdminResponsiveActions({
    super.key,
    required this.children,
    this.breakpoint = AdminLayout.compactWidth,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < breakpoint;
        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                SizedBox(width: double.infinity, child: children[i]),
                if (i != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class AdminActionButtonBox extends StatelessWidget {
  final Widget child;

  const AdminActionButtonBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 52, child: child);
  }
}
