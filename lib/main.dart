import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cauldron Quest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cauldron Quest"),
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          height: 600,
          child: CustomPaint(painter: BoardPainter()),
        ),
      ),
    );
  }
}

class BackgroundPainter {
  final Canvas canvas;
  final Size size;

  static const int radiusStepCount = 12;
  static const int angleStepCount = 12;
  late final double radius = size.shortestSide / 2.0;
  late final double radiusStep = radius / radiusStepCount;

  late final Offset center = size.center(Offset.zero);
  final double angleStep = 2 * pi / angleStepCount;

  BackgroundPainter(this.canvas, this.size);

  Paint get separatorsPaint {
    var separators = Paint();
    separators.style = PaintingStyle.stroke;
    separators.color = Colors.white60;
    return separators;
  }

  void drawPathBackground({int offset = 0}) {
    var pathBackground = Paint();
    pathBackground.color = Colors.green.shade100;
    canvas.drawCircle(center, radius - (offset * radiusStep), pathBackground);
  }

  void drawVoids({int offset = 0}) {
    var voidSpace = Paint();
    voidSpace.shader = ui.Gradient.radial(
        center, radius, [Colors.orange.shade100, Colors.deepOrange.shade100]);
    // voidSpace.color = Colors.orange.shade100;
    // This paints around clockwise.
    for (int i = 0; i < angleStepCount / 2; i++) {
      var startAngle = 2 * i * angleStep;
      canvas.drawArc(
          Rect.fromCircle(
              center: center, radius: radius - (offset * radiusStep)),
          startAngle,
          angleStep,
          true,
          voidSpace);
    }
  }

  void drawWizardRing({required int offset}) {
    var pathBackground = Paint();
    pathBackground.color = Colors.purple.shade100;
    canvas.drawCircle(center, radius - (offset * radiusStep), pathBackground);
  }

  void drawCircularSeparators({int offset = 0}) {
    for (int i = 1; i < radiusStepCount - offset; i++) {
      canvas.drawCircle(center, (i + 1) * radiusStep, separatorsPaint);
    }
  }

  void drawLineSeparators() {
    for (int i = 0; i < angleStepCount; i++) {
      var angle = i * angleStep;
      canvas.drawLine(center, Offset(cos(angle), sin(angle)) * radius + center,
          separatorsPaint);
    }
  }

  void drawCauldron() {
    var cauldron = Paint();
    cauldron.color = Colors.green.shade300;
    canvas.drawCircle(center, 2 * radiusStep, cauldron);
  }
}

class BoardPainter extends CustomPainter {
  BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    var painter = BackgroundPainter(canvas, size);
    painter.drawPathBackground();
    painter.drawCircularSeparators();
    painter.drawVoids();
    painter.drawWizardRing(offset: 4);
    painter.drawPathBackground(offset: 5);
    painter.drawVoids(offset: 5);
    painter.drawWizardRing(offset: 7);
    painter.drawPathBackground(offset: 8);
    painter.drawCircularSeparators(offset: 5);
    painter.drawVoids(offset: 5);
    painter.drawLineSeparators();
    painter.drawCauldron();
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return false;
  }
}
