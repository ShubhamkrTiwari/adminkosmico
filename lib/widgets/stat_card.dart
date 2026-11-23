import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

class AnimatedCounterText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const AnimatedCounterText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    final cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final double targetValue = double.tryParse(cleanText) ?? 0;
    final bool isCurrency = text.contains('₹') || text.contains('\$');
    final currencySymbol = text.contains('₹') ? '₹' : (text.contains('\$') ? '\$' : '');

    if (targetValue == 0 && cleanText.isEmpty) {
      return Text(text, style: style);
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween<double>(begin: 0, end: targetValue),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        String display = value.toStringAsFixed(0);
        if (targetValue >= 1000) {
          final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
          display = display.replaceAllMapped(reg, (Match m) => '${m[1]},');
        }
        final finalStr = isCurrency ? '$currencySymbol$display' : display;
        return Text(finalStr, style: style);
      },
    );
  }
}

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isTrendPositive;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isTrendPositive = true,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242424) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withOpacity(0.15)
                    : Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                blurRadius: _isHovered ? 16 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            Widget animatedIcon = Icon(widget.icon, color: widget.color, size: 20);

                            if (widget.title.toLowerCase().contains('revenue')) {
                              // Floating coin / drop motion vertically
                              animatedIcon = Transform.translate(
                                offset: Offset(0, -4.0 * _animation.value),
                                child: animatedIcon,
                              );
                            } else if (widget.title.toLowerCase().contains('notification')) {
                              // Ringing bell tilt rotation
                              animatedIcon = Transform.rotate(
                                angle: 0.2 * (_animation.value - 0.5),
                                child: animatedIcon,
                              );
                            } else if (widget.title.toLowerCase().contains('order')) {
                              // Bouncing scale
                              animatedIcon = Transform.scale(
                                scale: 1.0 + (0.12 * _animation.value),
                                child: animatedIcon,
                              );
                            } else {
                              // Gentle pulse
                              animatedIcon = Transform.scale(
                                scale: 0.95 + (0.08 * _animation.value),
                                child: animatedIcon,
                              );
                            }

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(_isHovered ? 0.25 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: animatedIcon,
                            );
                          },
                        ),
                        if (widget.trend != null)
                          Text(
                            widget.trend!,
                            style: TextStyle(
                              color: widget.isTrendPositive ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(widget.value),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * animValue),
                          child: Opacity(
                            opacity: animValue,
                            child: child,
                          ),
                        );
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedCounterText(
                          text: widget.value,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColors.getSecondaryTextColor(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
