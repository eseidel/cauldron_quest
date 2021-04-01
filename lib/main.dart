import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'rules.dart';

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
      home: GameView(),
    );
  }
}

class GameView extends StatefulWidget {
  GameView({Key? key}) : super(key: key);

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late CauldronQuest game = CauldronQuest();

  _GameViewState();

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
          // child: CustomPaint(painter: BoardPainter()),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: BoardPainter())),
              Positioned.fill(
                  child: CustomPaint(painter: PiecesPainter(game.board))),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            game.takeTurn();
          });
        },
        child: Icon(game.isComplete ? Icons.refresh : Icons.skip_next),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class Palette {
  static const Color separators = Colors.white60;
  static final Color pathBackground = Colors.green.shade100;
  static final List<Color> voidSpaceColors = <Color>[
    Colors.orange.shade100,
    Colors.deepOrange.shade100
  ];
  static final Color wizardPathBackground = Colors.purple.shade100;
  static final Color cauldron = Colors.teal.shade300;

  static Color tokenColor(Token token) {
    if (token is Wizard) return Colors.deepPurple.shade300;
    if (token is Blocker) return Colors.black45;
    if (token is Bottle && token.isRevealed) return Colors.white70;
    if (token is Bottle) return Colors.green.shade300;
    return Colors.orangeAccent.shade400;
  }
}

class BoardMetrics {
  final Size size;
  BoardMetrics(this.size);

  static const int radiusStepCount = 12;
  static const int angleStepCount = 12;
  late final double radius = size.shortestSide / 2.0;
  late final double radiusStep = radius / radiusStepCount;
  late final double tokenRadius = radiusStep * .45;

  late final Offset center = size.center(Offset.zero);
  final double angleStep = 2 * pi / angleStepCount;

  static const wizardPathOffset = 4;

  double radiusWithOffset(int offset) => radius - (offset * radiusStep);

  Offset offsetFromPolar({required double angle, required double radius}) {
    return Offset(cos(angle) * radius, sin(angle) * radius) + center;
  }
}

class BackgroundPainter {
  final Canvas canvas;
  final BoardMetrics metrics;

  BackgroundPainter(this.canvas, Size size) : metrics = BoardMetrics(size);

  Paint get separatorsPaint {
    var separators = Paint();
    separators.style = PaintingStyle.stroke;
    separators.color = Palette.separators;
    return separators;
  }

  void drawPathBackground({int offset = 0}) {
    var pathBackground = Paint();
    pathBackground.color = Palette.pathBackground;
    canvas.drawCircle(
        metrics.center, metrics.radiusWithOffset(offset), pathBackground);
  }

  void drawVoids({int offset = 0}) {
    var voidSpace = Paint();
    voidSpace.shader = ui.Gradient.radial(
        metrics.center, metrics.radius, Palette.voidSpaceColors);

    // This paints around clockwise.
    for (int i = 0; i < BoardMetrics.angleStepCount / 2; i++) {
      var startAngle = 2 * i * metrics.angleStep;
      canvas.drawArc(
          Rect.fromCircle(
              center: metrics.center, radius: metrics.radiusWithOffset(offset)),
          startAngle,
          metrics.angleStep,
          true,
          voidSpace);
    }
  }

  void drawWizardRing({required int offset}) {
    var pathBackground = Paint();
    pathBackground.color = Palette.wizardPathBackground;
    canvas.drawCircle(metrics.center,
        metrics.radius - (offset * metrics.radiusStep), pathBackground);
  }

  void drawCircularSeparators({int offset = 0}) {
    for (int i = 1; i < BoardMetrics.radiusStepCount - offset; i++) {
      canvas.drawCircle(
          metrics.center, (i + 1) * metrics.radiusStep, separatorsPaint);
    }
  }

  void drawLineSeparators() {
    for (int i = 0; i < BoardMetrics.angleStepCount; i++) {
      var angle = i * metrics.angleStep;
      canvas.drawLine(
          metrics.center,
          Offset(cos(angle), sin(angle)) * metrics.radius + metrics.center,
          separatorsPaint);
    }
  }

  void drawCauldron() {
    var cauldron = Paint();
    cauldron.color = Palette.cauldron;
    canvas.drawCircle(metrics.center, 2 * metrics.radiusStep, cauldron);
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
    painter.drawWizardRing(offset: BoardMetrics.wizardPathOffset);
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

class PiecesPainter extends CustomPainter {
  final Board board;
  PiecesPainter(this.board);

  Offset centerForSpace(BoardMetrics metrics, Space space) {
    // This is the wrong method for painting in the cauldron.
    if (space == board.cauldron) {
      return metrics.center;
    }
    // All spaces except the goal have coords.
    Coords coords = space.coords!;
    return metrics.offsetFromPolar(
        angle: (coords.angle + 0.5) * metrics.angleStep,
        radius:
            metrics.radiusWithOffset(coords.radius) - metrics.radiusStep / 2);
  }

  void paintTokenAt(
      Canvas canvas, Token token, Offset tokenCenter, BoardMetrics metrics) {
    var paint = Paint();
    paint.color = Palette.tokenColor(token);
    canvas.drawCircle(tokenCenter, metrics.tokenRadius, paint);
  }

  void paintTokensInCauldron(
      Canvas canvas, BoardMetrics metrics, Space cauldron) {
    var tokens = cauldron.tokens;
    if (tokens.length == 1) {
      paintTokenAt(canvas, tokens.first, metrics.center, metrics);
    }
    if (tokens.length == 2) {
      paintTokenAt(canvas, tokens.first,
          metrics.offsetFromPolar(angle: 6, radius: 11), metrics);
      paintTokenAt(canvas, tokens.last,
          metrics.offsetFromPolar(angle: 0, radius: 11), metrics);
    }
    if (tokens.length == 3) {
      paintTokenAt(canvas, tokens[0],
          metrics.offsetFromPolar(angle: 9, radius: 11), metrics);
      paintTokenAt(canvas, tokens[1],
          metrics.offsetFromPolar(angle: 5, radius: 11), metrics);
      paintTokenAt(canvas, tokens[2],
          metrics.offsetFromPolar(angle: 1, radius: 11), metrics);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    BoardMetrics metrics = BoardMetrics(size);
    // Walk through pieces, paining them.
    Set<Space> spacesToPaint = <Space>{};
    spacesToPaint.add(board.wizard.location!);
    spacesToPaint.addAll(board.bottles.map((bottle) => bottle.location!));
    spacesToPaint.addAll(board.blockerSpaces);

    for (var space in spacesToPaint) {
      if (space == board.cauldron) {
        paintTokensInCauldron(canvas, metrics, space);
      }
      Offset tokenCenter = centerForSpace(metrics, space);
      for (var token in space.tokens) {
        paintTokenAt(canvas, token, tokenCenter, metrics);
        // FIXME: Handle two tokens.
      }
    }
  }

  @override
  bool shouldRepaint(covariant PiecesPainter oldDelegate) {
    // Should check if the board change (e.g. turn number maybe?)
    return true;
  }
}
