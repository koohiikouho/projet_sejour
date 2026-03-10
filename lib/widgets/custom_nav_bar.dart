import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: true,
        child: SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double slotWidth = totalWidth / 5;

              return Stack(
                children: [
                  // Moving Indicator background (Sleek Spotlight aesthetic)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutQuart,
                    tween: Tween<double>(
                      begin: currentIndex.toDouble(),
                      end: currentIndex.toDouble(),
                    ),
                    builder: (context, value, child) {
                      final double target = currentIndex.toDouble();
                      final double delta = (value - target).abs();
                      final bool inTransit = delta > 0.05 && delta < 0.95;

                      final double width = inTransit ? 24 : 44;
                      final double height = inTransit ? 3 : 44;
                      final double borderRadius = inTransit ? 2 : 22;
                      final double opacity = inTransit ? 0.4 : 0.15;

                      final double left =
                          (value * slotWidth) + (slotWidth / 2) - (width / 2);
                      final double top = (56 / 2) - (height / 2);

                      return Positioned(
                        left: left,
                        top: top,
                        child: Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: !inTransit
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(context, Icons.home_rounded, 0),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          context,
                          Icons.location_on_rounded,
                          1,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          context,
                          Icons.view_in_ar_rounded,
                          2,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(context, Icons.widgets_rounded, 3),
                      ),
                      Expanded(
                        child: _buildNavItem(context, Icons.person_rounded, 4),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    final isSelected = currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onNavTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 56,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              icon,
              color: isSelected ? primaryColor : unselectedColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
