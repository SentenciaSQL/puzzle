import 'package:flutter/material.dart';

import '../paint/grove_art.dart';
import '../theme.dart';

class GroveButton extends StatefulWidget {
  const GroveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool enabled;

  @override
  State<GroveButton> createState() => _GroveButtonState();
}

class _GroveButtonState extends State<GroveButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: widget.primary ? 58 : 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: widget.primary
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE08A), gold, goldDeep],
                  )
                : const LinearGradient(
                    colors: [Color(0x553C2468), Color(0x88301C58)],
                  ),
            border: Border.all(
              color: widget.primary ? const Color(0xFFFFF3C8) : line,
            ),
            boxShadow: [
              if (widget.primary)
                const BoxShadow(
                  color: Color(0x66E0941D),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.primary
                ? display(22, color: goldInk, height: 1)
                : body(16, color: cream),
          ),
        ),
      ),
    );
  }
}

class IconDisc extends StatelessWidget {
  const IconDisc({
    super.key,
    required this.draw,
    required this.onPressed,
    this.tooltip,
  });
  final void Function(Canvas, Size) draw;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: const Color(0x55301C58),
      shape: const CircleBorder(side: BorderSide(color: line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(child: GroveMark(draw, size: 24)),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.coins, this.onTap});
  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: const Color(0xCC2A1754),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GroveMark(paintCoin, size: 22),
            const SizedBox(width: 6),
            Text('$coins', style: display(18, color: cream, height: 1)),
          ],
        ),
      ),
    );
  }
}

class GroveCard extends StatelessWidget {
  const GroveCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF02E1C58), Color(0xF01A1038)],
        ),
        border: Border.all(color: line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x660C0618),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

Future<T?> showGroveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Close',
    barrierColor: const Color(0xC8140A28),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, _) {
      final bottom = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: builder(context),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class SkyBackdrop extends StatelessWidget {
  const SkyBackdrop({super.key, required this.motion, required this.child});
  final bool motion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _SkyField(motion: motion)),
        child,
      ],
    );
  }
}

class _SkyField extends StatefulWidget {
  const _SkyField({required this.motion});
  final bool motion;

  @override
  State<_SkyField> createState() => _SkyFieldState();
}

class _SkyFieldState extends State<_SkyField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    if (widget.motion) _controller.repeat();
  }

  @override
  void didUpdateWidget(_SkyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motion && !_controller.isAnimating) _controller.repeat();
    if (!widget.motion && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: SkyPainter(_controller.value * 8000, motion: widget.motion),
        size: Size.infinite,
      ),
    );
  }
}
