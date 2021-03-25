import 'dart:math';
import 'stats.dart';

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

class Bottle {
  // TODO(eseidel): Make blockers an enum?
  final int ingredient;
  bool visible = false;

  // 0-6 are normal paths, 7 is the wizard's path.
  int? path;
  // 0-indexed:
// 10 slots, start on 0, wizard path crosses 4, blocker on 7.
  int? pathOffset;

  Bottle(this.ingredient);
}

class Board {
  static int ingredientCount = 6;
  static int pathCount = 6;
  static int pathLength = 10;
  static int wizardPathLength = 12;

  List<int>? winningIngredients;
  List<bool> _pathIsBlocked = List.filled(6, false);
  int wizardLocation = 0;
  // Wizard path has 12 locations, 6 of which are on potion paths.

  bool haveUsedSpellBreaker = false;

  Board() {
    var shuffledIngredients =
        List.generate(ingredientCount, (index) => Bottle(index))..shuffle();
    for (int i = 0; i < pathCount; i++) {
      shuffledIngredients[i].path = i;
      shuffledIngredients[i].pathOffset = 0;
    }
  }

  void moveWizardOneSpace() {
    int newLocation = (wizardLocation + 1) % wizardPathLength;
    // if newLocation has a potion, move the potion to the nearest start location.
    wizardLocation = newLocation;
  }

  void moveWizard(int spacesToMove) {
    while (spacesToMove-- > 0) moveWizardOneSpace();
  }

  Iterable<int> collectBlockedPaths() sync* {
    for (int i = 0; i < _pathIsBlocked.length; i++) {
      if (pathIsBlocked(i)) yield i;
    }
  }

  Iterable<int> collectUnblockedPaths() sync* {
    for (int i = 0; i < _pathIsBlocked.length; i++) {
      if (!pathIsBlocked(i)) yield i;
    }
  }

  int get unblockedPathCount => collectUnblockedPaths().length;

  void blockRandomPath() {
    List<int> pathsToBlock = collectUnblockedPaths().toList()..shuffle();
    assert(pathsToBlock.isNotEmpty);
    blockPath(pathsToBlock.first);
  }

  // Mostly for testing.
  void blockPath(int path) {
    assert(!pathIsBlocked(path));
    _pathIsBlocked[path] = true;
  }

  bool pathIsBlocked(int path) => _pathIsBlocked[path];

  void unblockWithSpellBreaker(int path) {
    assert(!haveUsedSpellBreaker);
    assert(pathIsBlocked(path));
    haveUsedSpellBreaker = true;
    _pathIsBlocked[path] = false;
  }
}

bool threeTries(bool doTry(List<int?> dice)) {
  List<int?> dice = [null, null, null];
  return doTry(dice) || doTry(dice) || doTry(dice);
}

bool tryRevealCharm() {
  return threeTries(
    (List<int?> dice) {
      for (int i = 0; i < dice.length; i++) {
        int? lastValue = dice[i];
        if (lastValue == null || !lastValue.isEven) {
          dice[i] = numberDie.roll();
        }
      }
      return dice.every((int? value) => value!.isEven);
    },
  );
}

bool trySwapCharm() {
  return threeTries(
    (List<int?> dice) {
      for (int i = 0; i < dice.length; i++) {
        int? lastValue = dice[i];
        if (lastValue == null || !lastValue.isOdd) {
          dice[i] = numberDie.roll();
        }
      }
      return dice.every((int? value) => value!.isOdd);
    },
  );
}

enum RerollGroup {
  smallest,
  largest,
}

class Reroll {
  final int count;
  final RerollGroup group;
  Reroll(this.count, this.group);

  Reroll.all()
      : count = 3,
        group = RerollGroup.smallest;

  Reroll.none()
      : count = 0,
        group = RerollGroup.smallest;

  Reroll.smallest([this.count = 1]) : group = RerollGroup.smallest;
  Reroll.largest([this.count = 1]) : group = RerollGroup.largest;

  @override
  String toString() {
    return "$count, $group";
  }

  @override
  bool operator ==(Object o) =>
      o is Reroll && count == o.count && group == o.group;
}

Reroll planReroll(List<int?> dice) {
  if (dice.any((element) => element == null)) return Reroll.all();
  int sum = dice.fold(0, (sum, value) => sum + value!);
  assert(sum > 2);
  assert(dice.length == 3);
  if (sum < 7) {
    return Reroll.smallest(2);
  } else if (sum < 12) {
    return Reroll.smallest();
  } else if (sum == 12) {
    // Only not an assert for testing.
    return Reroll.none();
  } else if (sum < 18) {
    return Reroll.largest();
  } else if (sum == 18) {
    // Re-roll two largest (they're all 6s).
    return Reroll.largest(2);
  }
  assert(false);
  return Reroll.none();
}

void executeReroll(List<int?> dice, Reroll reroll) {
  bool hasNulls = dice.any((element) => element == null);
  if (!hasNulls) {
    if (reroll.group == RerollGroup.smallest)
      dice.sort((a, b) => a!.compareTo(b!));
    else
      dice.sort((a, b) => b!.compareTo(a!));
  }
  assert(!hasNulls || reroll == Reroll.all());
  for (int i = 0; i < reroll.count; i++) {
    dice[i] = numberDie.roll();
  }
}

bool trySuperPowerCharm() {
  return threeTries((List<int?> dice) {
    Reroll reroll = planReroll(dice);
    executeReroll(dice, reroll);
    return dice.fold(0, (dynamic sum, value) => sum + value) == 12;
  });
}

int moveCount(Action action) {
  if (action == Action.moveThree) return 3;
  if (action == Action.moveFour) return 4;
  assert(false);
  return 0;
}

class CauldronQuest {
  final GameStats stats = GameStats();
  final Board board = Board();
  final Planner planner = Planner();

  static int blocksUntilLoss = 7; // 6 paths, plus the one removal token.

  // TODO(eseidel): This should use board.unblockedPathCount once
  // we know how to use the spellbreaker token.
  bool get isComplete => stats.blockCount >= blocksUntilLoss;

  void handleRoll(Actor actor, Action action) {
    stats.turnCount++;
    if (actor == Actor.wizard && action == Action.magic) {
      stats.blockCount++;
      board.blockRandomPath();
      // TODO(eseidel): Hack until we know how to plan spell-breaker usage.
      if (!board.haveUsedSpellBreaker)
        board.unblockWithSpellBreaker(board.collectBlockedPaths().first);
      return;
    }
    if (actor == Actor.potion && action == Action.magic) {
      stats.magicCount++;
      if (tryRevealCharm()) {
        stats.potionsRevealed++;
        // Reveal reveal = planner.planPotionReveal();
        // executeReveal(reveal);
      }
      return;
    }
    if (actor == Actor.wizard) {
      stats.wizardMoveCount++;
      int spaces = moveCount(action);
      stats.wizardMoveDistance += spaces;
      board.moveWizard(spaces);
      return;
    }
    if (actor == Actor.potion) {
      stats.potionMoveCount++;
      int spaces = moveCount(action);
      stats.potionMoveDistance += spaces;
      // PotionMove move = planner.planPotionMove(spaces);
      // executeMove(move);
      return;
    }
    assert(false);
  }

  void takeTurn() {
    Actor actor = actorDie.roll();
    Action action = actionDie.roll();
    handleRoll(actor, action);
  }
}

class Planner {}
