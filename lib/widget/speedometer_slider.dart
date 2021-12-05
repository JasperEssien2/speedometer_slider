import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const int numberOfPoints = 30;

class CustomSlider extends LeafRenderObjectWidget {
  final MaterialColor? speedometerColor;
  const CustomSlider({Key? key, this.speedometerColor}) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCustomSlider(color: speedometerColor);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderCustomSlider renderObject) {
    renderObject.color = speedometerColor;
  }
}

const unitArc = 180 / numberOfPoints;

class _RenderCustomSlider extends RenderAligningShiftedBox with MathsMixin {
  var _trackerPath = Path();
  Offset knobPosition = const Offset(0, 0);
  late final DragGestureRecognizer dragGestureRecognizer;
  late final TapGestureRecognizer tapGestureRecognizer;
  double pointerPoint = numberOfPoints / 2;

  _RenderCustomSlider({MaterialColor? color})
      : super(textDirection: TextDirection.ltr, alignment: Alignment.center) {
    dragGestureRecognizer = PanGestureRecognizer()
      ..onStart = _dragStart
      ..onEnd = _dragEnd
      ..onUpdate = _dragUpdate;
    tapGestureRecognizer = TapGestureRecognizer()..onTapDown = _tapDown;
    _color = color;
  }

  MaterialColor? _color;

  MaterialColor? get color => _color;

  set color(MaterialColor? color) {
    if (_color == color) return;

    _color = color;
    markNeedsPaint();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final size = math.min(constraints.maxHeight, constraints.maxWidth);

    return Size(size, size);
  }

  @override
  bool get sizedByParent => true;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.min(width, size.height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.min(height, size.width);

  @override
  bool hitTestSelf(Offset position) {
    var radius = (size.width / 2);
    position = position.translate(-radius, -(size.height / 2)).scale(1, 1);

    if (position.dx > radius || position.dx < -radius) {
      return false;
    }
    return _trackerPath.contains(position);
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    knobPosition =
        event.localPosition.translate(-(size.width / 2), -(size.height / 2));

    if (event is PointerDownEvent && _trackerPath.contains(knobPosition)) {
      tapGestureRecognizer.addPointer(event);
      dragGestureRecognizer.addPointer(event);
    }

    markNeedsPaint();
  }

  void _dragStart(DragStartDetails details) {}

  void _dragEnd(DragEndDetails details) {}

  void _dragUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    if (_notWithinBound(position)) return;

    pointerPoint = pointFromRadius(position.dx);

    markNeedsPaint();
  }

  void _tapDown(TapDownDetails details) {
    if (_notWithinBound(details.localPosition)) return;
    pointerPoint = pointFromRadius(details.localPosition.dx);
    markNeedsPaint();
  }

  bool _notWithinBound(Offset position) =>
      position.dx > size.width || position.dx < 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final radius = (size.width / 2);

    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) {
        final canvas = context.canvas;
        log("OFFSET =============== $offset");
        canvas.translate(
            (size.width / 2) + offset.dx, (size.height / 2) + offset.dy);

        _drawSpeedometerTicks(canvas, offset, unitArc, radius);

        _drawPointer(radius, canvas);

        _drawSlider(canvas);
      },
    );
  }

  void _drawSpeedometerTicks(
    Canvas canvas,
    Offset offset,
    double unitArc,
    double radius,
  ) {
    for (int i = 0; i < numberOfPoints + 1; i++) {
      final sectorLength = (unitArc * i);

      final tickLength = (size.width) * (i % 5 == 0 ? .15 : .08);

      final Offset startPosition = Offset(
          computeHorizontalPoint(sectorLength, radius - tickLength),
          computeVerticalPoint(sectorLength, radius - tickLength));

      final Offset endPosition = Offset(
          computeHorizontalPoint(sectorLength, radius),
          computeVerticalPoint(sectorLength, radius));

      final colorRatio = colorWithRatio(pointerPoint, majorColor: _color);
      canvas.drawLine(
        endPosition,
        startPosition,
        Paint()
          ..shader = SweepGradient(
            colors: colorRatio.colors,
            stops: colorRatio.ratio,
            endAngle: 2 * math.pi,
            startAngle: math.pi,
            tileMode: TileMode.mirror,
          ).createShader(
            Rect.fromCircle(center: const Offset(0, 0), radius: radius),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }

  void _drawPointer(double radius, Canvas canvas) {
    final pointerAngle = unitArc * pointerPoint;

    final paint = Paint()
      ..color = Colors.blueGrey[500]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final Offset startPosition = Offset(
        computeHorizontalPoint(pointerAngle, radius - 20),
        computeVerticalPoint(pointerAngle, radius - 20));

    const Offset endPosition = Offset(0, 0);

    canvas.drawLine(startPosition, endPosition, paint);

    canvas.drawCircle(
      const Offset(0, 0),
      15,
      Paint()
        ..color = Colors.blueGrey[500]!
        ..strokeWidth = 5,
    );
    canvas.drawCircle(
      const Offset(0, 0),
      8,
      Paint()
        ..color = Colors.amber
        ..strokeWidth = 5,
    );
  }

  void _drawSlider(Canvas canvas) {
    var curveRadius = const Radius.circular(30);

    final topMargin = size.height * .2;

    var radius = size.width / 2;

    _trackerPath = _trackerPath
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromPoints(
            Offset(-radius, topMargin + 10),
            Offset(radius, topMargin),
          ),
          topLeft: curveRadius,
          topRight: curveRadius,
          bottomLeft: curveRadius,
          bottomRight: curveRadius,
        ),
      );
    final colorRatio = colorWithRatio(pointerPoint, majorColor: _color);

    canvas.drawPath(
      _trackerPath,
      Paint()
        ..shader = LinearGradient(
          colors: colorRatio.colors,
          stops: colorRatio.ratio,
        ).createShader(
          Rect.fromCenter(
            center: const Offset(0, 0),
            width: size.width,
            height: size.width,
          ),
        )
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(
      Offset(knobPosition.dx, topMargin + 5),
      20,
      Paint()
        ..color = Colors.blueGrey[500]!
        ..strokeWidth = 5,
    );

    canvas.drawCircle(
      Offset(knobPosition.dx, topMargin + 5),
      15,
      Paint()..color = Colors.amber,
    );
  }
}

mixin MathsMixin {
   
  double computeVerticalPoint(double sectorLength, double radius) {
    final angle = convertToRadian(sectorLength + 90);

    return radius * math.cos(angle);
  }

  double computeHorizontalPoint(double sectorLength, double radius) {
    final angle = convertToRadian(sectorLength + 90);

    return -radius * math.sin(angle);
  }

  double pointFromRadius(double radius) {
    return (math.pi / numberOfPoints) * radius;
  }

  double interpolate(
      {required double start, required double end, int index = 1}) {
    return ((start + end) - end) * index;
  }

  double convertToRadian(double degree) {
    return degree * math.pi / 180;
  }

  double ratio(double value) => value / numberOfPoints;

  ColorsRatio colorWithRatio(double value, {MaterialColor? majorColor}) {
    return ColorsRatio(
      colors: List.generate(
        numberOfPoints,
        (index) {
          final indexRatio = ratio(index.toDouble());
          bool isPassedPoint = value >= index;
          majorColor = majorColor ?? Colors.red;

          Color color = majorColor!;

          const startRatio = 7 / numberOfPoints;
          const midRatio = 20 / numberOfPoints;
          const endRatio = 25 / numberOfPoints;

          if (indexRatio <= startRatio) {
            color = majorColor![300]!;
          } else if (indexRatio > startRatio && indexRatio <= midRatio) {
            color = majorColor![400]!;
          } else {
            color = majorColor![900]!;
          }

          return isPassedPoint ? color : Colors.grey;
        },
      ),
      ratio: List<double>.generate(
          numberOfPoints, (index) => ratio(index.toDouble())).toList(),
    );
  }

  int colorLenth(List<Color> colors) {
    return colors.length;
  }
}

class ColorsRatio {
  final List<Color> colors;
  final List<double> ratio;

  ColorsRatio({required this.colors, required this.ratio});
}
