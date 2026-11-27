import 'package:flutter/material.dart';
import 'package:remote/l10n/app_localizations.dart';

/// Swipe pad for webOS pointer navigation.
///
/// Dragging moves the on-screen cursor: [unitsPerPixel] logical pixels of
/// finger travel make one pointer unit, and the leftover fraction is carried
/// into the next drag update so slow swipes still move the cursor. A tap
/// clicks wherever the cursor is. Callbacks are passed in rather than read
/// from the bloc so the gesture maths can be tested on its own.
class Touchpad extends StatefulWidget {
  const Touchpad({
    required this.onMove,
    required this.onClick,
    this.unitsPerPixel = 4,
    super.key,
  });

  /// Called with the pointer-unit delta of a swipe.
  final void Function(int dx, int dy) onMove;

  /// Called when the pad is tapped.
  final VoidCallback onClick;

  /// Logical pixels of finger travel per pointer unit. Lower is faster.
  final double unitsPerPixel;

  @override
  State<Touchpad> createState() => _TouchpadState();
}

class _TouchpadState extends State<Touchpad> {
  /// The part of a swipe that has not reached a whole pointer unit yet.
  double _pendingX = 0;
  double _pendingY = 0;
  bool _dragging = false;

  void _handlePanStart(DragStartDetails details) {
    _dragging = true;
    setState(() {});
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _pendingX += details.delta.dx / widget.unitsPerPixel;
    _pendingY += details.delta.dy / widget.unitsPerPixel;
    final dx = _pendingX.truncate();
    final dy = _pendingY.truncate();
    if (dx == 0 && dy == 0) return;
    _pendingX -= dx;
    _pendingY -= dy;
    widget.onMove(dx, dy);
  }

  void _handlePanEnd(DragEndDetails details) => _finishDrag();

  void _handlePanCancel() => _finishDrag();

  void _finishDrag() {
    // A fraction under one unit is dropped: the next gesture starts fresh.
    _pendingX = 0;
    _pendingY = 0;
    if (_dragging) setState(() => _dragging = false);
  }

  void _handleTap() {
    _finishDrag();
    widget.onClick();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onPanCancel: _handlePanCancel,
      child: Semantics(
        label: l.touchpad,
        hint: l.touchpadHint,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _dragging
                  ? const [Color(0XFF2a2a2a), Color(0XFF3f3f3f)]
                  : const [Color(0XFF1c1c1c), Color(0XFF383838)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0XFF1c1c1c),
                offset: Offset(5, 5),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Color(0XFF404040),
                offset: Offset(-5, -5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe,
                  size: 44,
                  color: _dragging ? Colors.white : Colors.white54,
                ),
                const SizedBox(height: 12),
                Text(
                  l.touchpadHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
