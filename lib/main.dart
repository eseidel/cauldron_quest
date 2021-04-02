import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  _GameViewState createState() => _GameViewState(0);
}

class _GameViewState extends State<GameView> {
  int seed = 0;
  late CauldronQuest game;
  double maxTurns = 0;

  final _textController = TextEditingController();
  final _textFocusNode = FocusNode();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  _GameViewState(this.seed) {
    createNewGame();
  }

  @override
  void initState() {
    _textFocusNode.addListener(() {
      if (!_textFocusNode.hasFocus) return;
      final String text = _textController.text;
      _textController.value = _textController.value.copyWith(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
    super.initState();
  }

  int maxTurnsInSeed(int seed) {
    game = CauldronQuest(Random(seed));
    while (!game.isComplete) {
      game.takeTurn();
    }
    return game.turnsTaken;
  }

  void createNewGame() {
    seed = Random().nextInt(1000000);
    maxTurns = maxTurnsInSeed(seed).toDouble();
    game = CauldronQuest(Random(seed));
    _textController.value = TextEditingValue(text: game.board.saveString());
  }

  void takeTurn() {
    game.takeTurn();
    _textController.value = TextEditingValue(text: game.board.saveString());
  }

  double get currentTurn {
    return game.turnsTaken.toDouble();
  }

  set currentTurn(double newTurnDouble) {
    int newTurn = newTurnDouble.toInt();
    if (game.turnsTaken == newTurn) return;

    game = CauldronQuest(Random(seed));
    for (int i = 0; i < newTurn; i++) {
      game.takeTurn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cauldron Quest"),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        focusNode: _textFocusNode,
                        decoration: InputDecoration(hintText: "Save String"),
                        controller: _textController,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(
                          new ClipboardData(text: _textController.text));
                    },
                    child: Icon(Icons.copy),
                  )
                ],
              ),
            ),
            SizedBox(
              width: 600,
              height: 600,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: BoardPainter())),
                  Positioned.fill(
                      child: CustomPaint(painter: PiecesPainter(game.board))),
                ],
              ),
            ),
            Slider(
              value: currentTurn,
              min: 0,
              max: maxTurns,
              divisions: maxTurns.toInt(),
              label: currentTurn.round().toString(),
              onChanged: (double value) {
                setState(() {
                  currentTurn = value;
                });
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (game.isComplete) {
              createNewGame();
            } else {
              takeTurn();
            }
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

  static Color tokenColor(Token token, Set<int> neededIngredients) {
    if (token is Wizard) return Colors.deepPurple.shade300;
    if (token is Blocker) return Colors.black87;
    if (token is Bottle) {
      if (token.isRevealed) {
        bool isNeeded = neededIngredients.contains(token.ingredient);
        return isNeeded ? Colors.orange.shade100 : Colors.white70;
      }
      return Colors.green.shade300;
    }
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

  double radiusWithOffset(double offset) => radius - (offset * radiusStep);

  Offset offsetFromPolar(
      {required double angle, required double radiusOffset}) {
    // Convert from board coords to actual polar coords.
    angle *= angleStep;
    var radius = radiusWithOffset(radiusOffset);
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
    canvas.drawCircle(metrics.center,
        metrics.radiusWithOffset(offset.toDouble()), pathBackground);
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
              center: metrics.center,
              radius: metrics.radiusWithOffset(offset.toDouble())),
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

  void paintTokenAt(
      Canvas canvas, Token token, Offset tokenCenter, BoardMetrics metrics) {
    var paint = Paint();
    paint.color = Palette.tokenColor(token, board.neededIngredients);
    canvas.drawCircle(tokenCenter, metrics.tokenRadius, paint);
  }

  void paintTokensInCauldron(
      Canvas canvas, BoardMetrics metrics, Space cauldron) {
    var tokens = cauldron.tokens;
    if (tokens.length == 1) {
      paintTokenAt(canvas, tokens[0], metrics.center, metrics);
      return;
    }

    double tokenAngleSpacing = 12 / tokens.length;
    Offset tokenOffset(double angle) =>
        metrics.offsetFromPolar(angle: angle, radiusOffset: 11);
    for (int i = 0; i < tokens.length; i++) {
      var tokenCenter = tokenOffset(i * tokenAngleSpacing);
      paintTokenAt(canvas, tokens[i], tokenCenter, metrics);
    }
  }

  void paintTokens(Canvas canvas, BoardMetrics metrics, List<Token> tokens) {
    double tokenAngleSpacing = 1 / (tokens.length + 1);
    for (int i = 0; i < tokens.length; i++) {
      var token = tokens[i];
      Coords coords = token.location!.coords!;
      var tokenCenter = metrics.offsetFromPolar(
          angle: (coords.angle + (i + 1) * tokenAngleSpacing),
          radiusOffset: coords.radius + .5);
      paintTokenAt(canvas, token, tokenCenter, metrics);
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
      } else {
        paintTokens(canvas, metrics, space.tokens);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PiecesPainter oldDelegate) {
    // Should check if the board change (e.g. turn number maybe?)
    return true;
  }
}
