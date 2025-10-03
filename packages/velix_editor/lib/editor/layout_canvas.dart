import 'package:flutter/material.dart';

class LayoutCanvas extends StatefulWidget {
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final Widget child;

  const LayoutCanvas({
    super.key,
    required this.child,
    this.initialWidth = 400,
    this.minWidth = 100,
    this.maxWidth = 1000,
  });

  @override
  State<LayoutCanvas> createState() => _LayoutCanvasState();
}

class _LayoutCanvasState extends State<LayoutCanvas> {
  late double _width;
  bool _isDragging = false;
  double? _rulerX;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  void _startDrag(DragStartDetails details, bool fromLeft) {
    setState(() {
      _isDragging = true;
      _rulerX = details.globalPosition.dx;
    });
  }

  void _updateDrag(DragUpdateDetails details, bool fromLeft) {
    setState(() {
      if (fromLeft) {
        _width = (_width - details.delta.dx)
            .clamp(widget.minWidth, widget.maxWidth);
      } else {
        _width = (_width + details.delta.dx)
            .clamp(widget.minWidth, widget.maxWidth);
      }
      _rulerX = details.globalPosition.dx;
    });
  }

  void _endDrag(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _rulerX = null;
    });
  }

  Widget _buildHandle({required bool left}) {
    return Positioned(
      left: left ? -6 : null,
      right: left ? null : -6,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (d) => _startDrag(d, left),
          onHorizontalDragUpdate: (d) => _updateDrag(d, left),
          onHorizontalDragEnd: _endDrag,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: Container(
              width: 12,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 1.5,
                    height: 16,
                    color: Colors.grey.shade400,
                  ),
                  Container(
                    width: 1.5,
                    height: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final containerLeft = (constraints.maxWidth - _width) / 2;

      return Container(
        color: const Color(0xFFE5E7EB),
        child: Stack(
          children: [
            // Centered resizable container
            Positioned(
              left: containerLeft,
              top: 0,
              bottom: 0,
              width: _width,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isDragging
                        ? Colors.blue.shade400
                        : Colors.grey.shade300,
                    width: _isDragging ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                        child: widget.child,
                      ),
                    ),
                    _buildHandle(left: true),
                    _buildHandle(left: false),
                  ],
                ),
              ),
            ),

            // Ruler only while dragging
            if (_isDragging)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 60),
                  painter: _RulerPainter(
                    fullWidth: constraints.maxWidth,
                    containerWidth: _width,
                    containerLeft: containerLeft,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _RulerPainter extends CustomPainter {
  final double fullWidth;
  final double containerWidth;
  final double containerLeft;

  _RulerPainter({
    required this.fullWidth,
    required this.containerWidth,
    required this.containerLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintRulerBg = Paint()..color = const Color(0xFFF9FAFB);
    final paintLine = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1;
    final paintTick = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1;
    final paintHighlight = Paint()
      ..color = Colors.blue.shade400
      ..strokeWidth = 2;

    // ruler background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paintRulerBg,
    );

    // top border
    canvas.drawLine(
      const Offset(0, 0),
      Offset(fullWidth, 0),
      paintLine,
    );

    final containerRight = containerLeft + containerWidth;

    // ticks
    final textStyle = TextStyle(
      color: const Color(0xFF6B7280),
      fontSize: 10,
      fontFamily: 'monospace',
    );

    for (double i = 0; i <= containerWidth; i += 10) {
      final xPos = containerLeft + i;
      final isBigTick = i % 50 == 0;
      final tickHeight = isBigTick ? 16.0 : 8.0;

      canvas.drawLine(
        Offset(xPos, 0),
        Offset(xPos, tickHeight),
        paintTick,
      );

      if (isBigTick) {
        final textSpan = TextSpan(text: '${i.toInt()}', style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(xPos + 4, 20),
        );
      }
    }

    // highlight container edges
    canvas.drawLine(
      Offset(containerLeft, 0),
      Offset(containerLeft, size.height),
      paintHighlight,
    );
    canvas.drawLine(
      Offset(containerRight, 0),
      Offset(containerRight, size.height),
      paintHighlight,
    );

    // width label
    final actualWidth = containerWidth.toInt();
    final widthText = '${actualWidth}px';
    final labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final textSpan = TextSpan(text: widthText, style: labelStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final centerX = containerLeft + containerWidth / 2;
    final labelRect = Rect.fromCenter(
      center: Offset(centerX, size.height / 2),
      width: textPainter.width + 16,
      height: 24,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      Paint()..color = Colors.blue.shade400,
    );

    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.fullWidth != fullWidth ||
        oldDelegate.containerWidth != containerWidth ||
        oldDelegate.containerLeft != containerLeft;
  }
}
