import 'dart:math';
import 'stats.dart';
import 'planner.dart';
import 'astar.dart';

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

enum Charm {
  revealCharm,
  swapCharm,
  superPowerCharm,
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

abstract class Token {
  Space? _location;

  // Intentionally no setter.
  Space? get location => _location;

  void moveTo(Space newLocation) {
    Space? oldLocation = location;
    if (oldLocation != null) {
      oldLocation.tokens.remove(this);
    }
    _location = newLocation;
    newLocation.tokens.add(this);
  }

  String debugString();
}

class Bottle extends Token {
  final int ingredient;
  bool isRevealed = false;

  Bottle(this.ingredient);

  String debugString() => "B$ingredient" + (isRevealed ? 'r' : 'h');
}

class Blocker extends Token {
  String debugString() => "X";
}

class Wizard extends Blocker {
  String debugString() => "W";
}

bool superCharmWouldHelp(Bottle bottle) {
  // When would you ever choose a supercharm?
  // When the path to get the bottle is longer than X?
  // When the chance of winning w/o the supercharm is < 37.7%?
  // If the chance is 37.7% and you can move 6, then you're expectd move is 2.26
  return false;
}

class VersionedMinimumDistance {
  int distance = 0;
  int version = 0;

  bool update(VersionedMinimumDistance other) {
    bool dirty = other.version != version;
    if (dirty || distance > other.distance + 1) {
      version = other.version;
      distance = other.distance + 1;
      return true;
    }
    return false;
  }
}

class Space {
  List<Token> tokens = [];
  bool onWizardPath;
  Space? wizardForward;
  late String name;

  Space({Token? initialToken, this.onWizardPath = false, String? name}) {
    if (initialToken != null) {
      tokens.add(initialToken);
    }
    this.name = name ?? "";
  }

  bool isBlocked() => tokens.any((token) => token is Blocker);
  void addBlocker() => tokens.add(Blocker());
  void removeBlocker() => tokens.removeWhere((token) => token is Blocker);

  void connectTo(Space next, {bool setWizardForward = false}) {
    adjacentSpaces.add(next);
    next.adjacentSpaces.add(this);
    if (setWizardForward) {
      wizardForward = next;
    }
  }

  bool adjacentTo(Space other) => adjacentSpaces.contains(other);

  bool updateDistancesFromNeighbor(Space neighbor) {
    bool dirty = false;
    // Can't have a distanceToGoal from a blocked neighbor, or from one
    // which is only partially updated (has an old version of distanceToGoal).
    if (!neighbor.isBlocked() &&
        neighbor._distanceToGoal.version ==
            neighbor._unblockedDistanceToGoal.version) {
      dirty |= _distanceToGoal.update(neighbor._distanceToGoal);
    }
    dirty |= _unblockedDistanceToGoal.update(neighbor._unblockedDistanceToGoal);
    return dirty;
  }

  void setDistanceVersion(int version) {
    _distanceToGoal.version = version;
    _unblockedDistanceToGoal.version = version;
  }

  VersionedMinimumDistance _distanceToGoal = VersionedMinimumDistance();
  VersionedMinimumDistance _unblockedDistanceToGoal =
      VersionedMinimumDistance();

  int get distanceToGoal =>
      _distanceToGoal.version == _unblockedDistanceToGoal.version
          ? _distanceToGoal.distance
          : -1;
  int get unblockedDistanceToGoal => _unblockedDistanceToGoal.distance;

  AStarNode? aStarNode;

  List<Space> adjacentSpaces = [];

  String debugString() {
    var tokensString = tokens.isEmpty
        ? ""
        : " " + tokens.map((token) => token.debugString()).join(' ');
    return "[$name$tokensString]";
  }
}

String stringForPath(Iterable<Space> path) {
  return path.map((space) => space.debugString()).join(" ");
}

class Board {
  int distanceVersion = 0;
  late Wizard wizard;
  late List<Bottle> bottles;
  late Space cauldron;
  late List<Space> startSpaces;
  late List<Space> wizardPath;
  late List<Space> blockerSpaces;
  late List<int> neededIngredients;

  bool haveUsedSpellBreaker = false;

  Board() {
    buildBoardGraph();
    placePieces();
    updateDistances();
  }

  List<Space> connectPath(
      {required Space from,
      required Space to,
      required int spacesBetween,
      bool onWizardPath = false,
      String generateName(int)?}) {
    List<Space> path = [from];
    Space previous = from;
    for (int i = 0; i < spacesBetween; i++) {
      String name = generateName == null ? '' : generateName(i);
      Space next = Space(onWizardPath: onWizardPath, name: name);
      previous.connectTo(next, setWizardForward: onWizardPath);
      previous = next;
      path.add(next);
    }
    previous.connectTo(to, setWizardForward: onWizardPath);
    if (from != to) path.add(to);
    return path;
  }

  void buildBoardGraph() {
    const int wizardPathLength = 12;
    const int startSpacesCount = 6;

    cauldron = Space(name: "goal");
    startSpaces =
        List.generate(startSpacesCount, (index) => Space(name: "$index:0"))
            .toList();
    var wizardStart = Space(onWizardPath: true, name: "5:0");
    wizardPath = connectPath(
      from: wizardStart,
      to: wizardStart,
      spacesBetween: wizardPathLength - 1,
      onWizardPath: true,
      generateName: (index) => "w:${index + 1}",
    );
    blockerSpaces =
        List.generate(startSpacesCount, (index) => Space(name: "$index:7"));

    for (int i = 0; i < wizardPath.length; i++) {
      Space wizardSpace = wizardPath[i];
      if (i % 2 == 1) {
        int pathIndex = i ~/ 2;
        connectPath(
          from: startSpaces[pathIndex],
          to: wizardSpace,
          spacesBetween: 3,
          generateName: (index) => "$pathIndex:${1 + index}",
        );
        connectPath(
          from: wizardSpace,
          to: blockerSpaces[pathIndex],
          spacesBetween: 2,
          generateName: (index) => "$pathIndex:${5 + index}",
        );
        connectPath(
          from: blockerSpaces[pathIndex],
          to: cauldron,
          spacesBetween: 2,
          generateName: (index) => "$pathIndex:${8 + index}",
        );
      }
    }
  }

  void placePieces() {
    const int ingredientCount = 6;

    List<int> ingredients = List.generate(ingredientCount, (index) => index);
    ingredients.shuffle();
    neededIngredients = ingredients.take(3).toList();

    bottles = List.generate(ingredientCount, (index) => Bottle(index));
    bottles.shuffle();
    for (int i = 0; i < bottles.length; i++) {
      bottles[i].moveTo(startSpaces[i]);
    }

    wizard = Wizard();
    wizard.moveTo(wizardPath.first);
  }

  static void updateDistancesFromGoal(Space goal, int version) {
    goal.setDistanceVersion(version);
    // Start at cauldron, walk all locations setting distance.
    List<Space> toVisit = <Space>[goal];
    while (toVisit.isNotEmpty) {
      Space current = toVisit.removeLast();
      for (Space neighbor in current.adjacentSpaces) {
        if (neighbor.updateDistancesFromNeighbor(current)) {
          toVisit.add(neighbor);
        }
      }
    }
  }

  void updateDistances() {
    distanceVersion += 1;
    updateDistancesFromGoal(cauldron, distanceVersion);
  }

  Iterable<Space> shortestPathToGoal(Space start,
      {bool ignoreBlocks = false}) sync* {
    var distance = ignoreBlocks
        ? (Space space) => space.unblockedDistanceToGoal
        : (Space space) => space.distanceToGoal;
    Space current = start;

    while (distance(current) > 0) {
      yield current;
      current = current.adjacentSpaces.reduce((cheapest, space) =>
          distance(space) < distance(cheapest) ? space : cheapest);
    }
  }

  void _moveBottlesBackToStart(Space location) {
    assert(location.onWizardPath);
    // copy the list (with toList) to avoid modificiation during iteration.
    var bottlesToRemove =
        location.tokens.where((token) => token is Bottle).toList();

    for (var bottle in bottlesToRemove) {
      // TODO(eseidel): Should be nearest start location.
      Space startLocation =
          startSpaces.firstWhere((space) => space.tokens.isEmpty);
      bottle.moveTo(startLocation);
    }
  }

  void moveWizardOneSpace() {
    Space newLocation = wizard.location!.wizardForward!;
    // if newLocation has a potion, move the potion to the nearest start location.
    _moveBottlesBackToStart(newLocation);
    wizard.moveTo(newLocation);
  }

  void moveWizard(int spacesToMove) {
    while (spacesToMove-- > 0) moveWizardOneSpace();
  }

  Iterable<int> collectBlockedPaths() sync* {
    for (int i = 0; i < blockerSpaces.length; i++) {
      if (blockerSpaces[i].isBlocked()) yield i;
    }
  }

  Iterable<int> collectUnblockedPaths() sync* {
    for (int i = 0; i < blockerSpaces.length; i++) {
      if (!blockerSpaces[i].isBlocked()) yield i;
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
    blockerSpaces[path].addBlocker();
  }

  bool pathIsBlocked(int path) => blockerSpaces[path].isBlocked();

  void unblockWithSpellBreaker(int path) {
    assert(!haveUsedSpellBreaker);
    assert(pathIsBlocked(path));
    haveUsedSpellBreaker = true;
    blockerSpaces[path].removeBlocker();
  }

  int revealedRequiredIngredientCount() {
    Set<int> revealedIngredients =
        bottles.map((bottle) => bottle.ingredient).toSet();
    Set<int> intersection =
        revealedIngredients.intersection(Set.from(neededIngredients));
    return intersection.length;
  }

  int completedRequiredIngredientCount() {
    var tokens = cauldron.tokens;
    Set<int> completedIngredients =
        tokens.map((token) => (token as Bottle).ingredient).toSet();
    Set<int> intersection =
        completedIngredients.intersection(Set.from(neededIngredients));
    return intersection.length;
  }

  String debugString() {
    String debug = cauldron.debugString() + "\n";
    for (int i = 0; i < startSpaces.length; i++) {
      Space start = startSpaces[i];
      var path = shortestPathToGoal(start, ignoreBlocks: true);
      debug += " " + wizardPath[i * 2].debugString() + "\n";
      debug += stringForPath(path) + "\n";
    }
    return debug;
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

bool trySuperPowerCharm(Planner planner) {
  return threeTries((List<int?> dice) {
    Reroll reroll = planner.planReroll(dice);
    executeReroll(dice, reroll);
    return dice.fold(0, (dynamic sum, value) => sum + value) == 12;
  });
}

// TODO: Does this belong on a Rules object?
int maxSpacesMoved(Action action) {
  if (action == Action.moveThree) return 3;
  if (action == Action.moveFour) return 4;
  if (action == Action.magic) return 6;
  assert(false);
  return 0;
}

bool isLegalMove(Bottle bottle, Space toSpace, Action action) {
  // It's never legal to move onto a blocker.
  if (toSpace.isBlocked()) {
    print("Illegal: toSpace is Blocked!");
    return false;
  }
  Space? fromSpace = bottle.location;
  if (fromSpace == null) {
    print("Illegal: bottle.location is null");
    // This does not handle placing pieces.
    return false;
  }
  if (fromSpace == toSpace) {
    // This must be allowed, in the case where we're up next to a blocker.
    // Or even in the case where we're caught between two blockers and have an
    // even role.
    return true;
  }
  int maxSpaces = maxSpacesMoved(action);
  var path = shortestPath(
      from: fromSpace, to: toSpace, ignoreBlockers: action == Action.magic);
  if (path == null) {
    print("Illegal: no path from bottle to toSpace!");
    return false;
  }
  // Path includes the starting space.
  assert(path.first == bottle.location);
  return path.length - 1 <= maxSpaces;
}

class CauldronQuest {
  final GameStats stats = GameStats();
  final Board board = Board();
  final Planner planner = Planner();

  bool isComplete = false;
  bool wizardWon = false;

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
      bool magicSucess = false;
      Charm charm = planner.planCharm(board);
      switch (charm) {
        case Charm.revealCharm:
          if (magicSucess = tryRevealCharm()) {
            stats.potionsRevealed++;
            PlannedReveal reveal = planner.planPotionReveal(board);
            handleReveal(reveal);
          }
          break;
        case Charm.swapCharm:
          if (magicSucess = trySwapCharm()) {
            stats.potionsSwapped++;
          }
          break;
        case Charm.superPowerCharm:
          if (magicSucess = trySuperPowerCharm(planner)) {
            PlannedMove move = planner.pickBottleToSuperCharm(board);
            stats.supercharmCount++;
            handleBottleMove(action, move);
          }
          break;
      }
      if (!magicSucess) {
        stats.magicFailures++;
      }

      return;
    }
    if (actor == Actor.wizard) {
      stats.wizardMoveCount++;
      int spaces = maxSpacesMoved(action);
      stats.wizardMoveDistance += spaces;
      board.moveWizard(spaces);
      return;
    }
    if (actor == Actor.potion) {
      stats.potionMoveCount++;
      PlannedMove move = planner.planBottleMove(board, action);
      handleBottleMove(action, move);
      return;
    }
    assert(false);
  }

  void handleBottleMove(Action action, PlannedMove plan) {
    // TODO: Should not trust anything from PlannedMove in this function!
    assert(plan.possibleDistance <= maxSpacesMoved(action));
    stats.potionMoveDistance += plan.possibleDistance;
    assert(isLegalMove(plan.bottle, plan.toSpace, action));
    plan.bottle.moveTo(plan.toSpace);
  }

  void handleReveal(PlannedReveal reveal) {
    assert(!reveal.bottle.isRevealed);
    reveal.bottle.isRevealed = true;
  }

  void checkForWin() {
    if (board.blockerSpaces.every((space) => space.isBlocked())) {
      isComplete = true;
      wizardWon = true;
      return;
    }
    if (board.cauldron.tokens.length < 2) {
      return;
    }
    if (board.completedRequiredIngredientCount() == 3) {
      isComplete = true;
      wizardWon = false;
      stats.playerWon = true;
    }
  }

  void takeTurn() {
    assert(!isComplete);
    Actor actor = actorDie.roll();
    Action action = actionDie.roll();
    handleRoll(actor, action);
    checkForWin();
    if (isComplete) {
      return;
    }
    // TODO: Not sure this belongs here.
    board.updateDistances();
  }
}
