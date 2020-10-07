import 'dart:math';
import 'package:stats/stats.dart';

var random = Random();

class Die<T> {
  final List<T> faces;

  Die(this.faces);

  T roll() => faces[random.nextInt(faces.length)];
}

enum Actor {
  potion,
  wizard,
}

enum Action {
  magic,
  moveThree,
  moveFour,
}

final Die<int> numberDie = Die<int>([1, 2, 3, 4, 5, 6]);
final Die<Actor> actorDie = Die<Actor>([
  Actor.wizard,
  Actor.wizard,
  Actor.potion,
  Actor.potion,
  Actor.potion,
  Actor.potion,
]);
final Die<Action> actionDie = Die<Action>([
  Action.magic,
  Action.magic,
  Action.magic,
  Action.moveThree,
  Action.moveThree,
  Action.moveFour,
]);

// 0-indexed:
// 10 slots, start on 0, wizard path crosses 4, blocker on 7.
class Path {
  // TODO(eseidel): Slots can hold multiple pieces?
  List<Bottle> slots;
}

int ingredientCount = 6;
List<int> blockers = List.generate(6, (index) => index);

class Bottle {
  final int ingredient;
  bool visible = false;

  Bottle(this.ingredient);
}

class Board {
  List<Path> paths;
  var wizardPath;

  Board() {
    var shuffledIngredients =
        List.generate(ingredientCount, (index) => Bottle(index))..shuffle();
    for (int i = 0; i < paths.length; i++) {
      paths[i].slots[0] = shuffledIngredients[i];
    }
  }
}

bool threeTries(bool doTry()) => doTry() || doTry() || doTry();

bool tryRevealCharm() => threeTries(() =>
    numberDie.roll().isEven &&
    numberDie.roll().isEven &&
    numberDie.roll().isEven);

bool trySwapCharm() => threeTries(() =>
    numberDie.roll().isOdd && numberDie.roll().isOdd && numberDie.roll().isOdd);

bool trySuperPowerCharm() => threeTries(
    () => (numberDie.roll() + numberDie.roll() + numberDie.roll()) == 12);

void charmPercentages() {
  int tries = 100000;
  int revealCharm = 0;
  int swapCharm = 0;
  int superPowerCharm = 0;
  for (int x = 0; x < tries; x++) {
    if (tryRevealCharm()) revealCharm += 1;
    if (trySwapCharm()) swapCharm += 1;
    if (trySuperPowerCharm()) superPowerCharm += 1;
  }
  print("$revealCharm");
  print("$swapCharm");
  print("$superPowerCharm");
}

int moveCount(Action action) {
  if (action == Action.moveThree) return 3;
  if (action == Action.moveFour) return 4;
  assert(false);
  return 0;
}

class GameStats {
  int turnCount = 0;
  int blockCount = 0;
  int magicCount = 0;
  int potionMoveCount = 0;
  int wizardMoveCount = 0;
  int potionMoveDistance = 0;
  int wizardMoveDistance = 0;
  int potionsRevealed = 0;

  bool get couldHaveWon => potionsRevealed > 3 && potionMoveDistance > 30;

  void countRoll(Actor actor, Action action) {
    turnCount++;
    if (actor == Actor.wizard && action == Action.magic) {
      blockCount++;
      return;
    }
    if (actor == Actor.potion && action == Action.magic) {
      magicCount++;
      if (tryRevealCharm()) potionsRevealed++;
      return;
    }
    if (actor == Actor.wizard) {
      wizardMoveCount++;
      wizardMoveDistance += moveCount(action);
      return;
    }
    if (actor == Actor.potion) {
      potionMoveCount++;
      potionMoveDistance += moveCount(action);
      return;
    }
    assert(false);
  }
}

void printAggregateStatistics(List<GameStats> gameStats) {
  void printStats(String label, Iterable<int> values) {
    var stats = Stats.fromData(values);
    print(label + ": " + stats.withPrecision(3).toString());
  }

  printStats("Turns until blocked", gameStats.map((stats) => stats.turnCount));
  printStats("Magics rolled", gameStats.map((stats) => stats.magicCount));
  printStats(
      "Potions revealed", gameStats.map((stats) => stats.potionsRevealed));
  printStats(
      "Potion move rolled", gameStats.map((stats) => stats.potionMoveCount));
  printStats(
      "Wizard move rolled", gameStats.map((stats) => stats.wizardMoveCount));
  printStats("Potion spaces moved",
      gameStats.map((stats) => stats.potionMoveDistance));
  printStats("Wizard spaces moved",
      gameStats.map((stats) => stats.wizardMoveDistance));

  int possibleWinCount = 0;
  gameStats.forEach((GameStats stats) {
    if (stats.couldHaveWon) possibleWinCount++;
  });
  print("$possibleWinCount max possible wins");
}

void main() {
  int tries = 10000;
  int blocksUntilLoss = 7; // 6 paths, plus the one removal token.
  List<GameStats> gameStats = <GameStats>[];
  for (int i = 0; i < tries; i++) {
    GameStats stats = GameStats();
    while (stats.blockCount < blocksUntilLoss) {
      Actor actor = actorDie.roll();
      Action action = actionDie.roll();
      stats.countRoll(actor, action);
    }
    gameStats.add(stats);
  }
  printAggregateStatistics(gameStats);
}
