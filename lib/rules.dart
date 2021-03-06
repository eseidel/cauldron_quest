import 'dart:math';
import 'stats.dart';
import 'planner.dart';
import 'astar.dart';

class Die<T> {
  final Random random;
  final List<T> faces;

  Die(this.faces, this.random);

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

  void removeFromBoard() {
    assert(_location != null);
    if (_location == null) {
      return;
    }
    _location!.tokens.remove(this);
    _location = null;
  }

  String debugString();
}

class Bottle extends Token {
  final int ingredient;
  bool isRevealed;

  Bottle(this.ingredient, {this.isRevealed = false});

  String debugString() => "B$ingredient" + (isRevealed ? 'r' : 'h');
}

class Blocker extends Token {
  String debugString() => "X";
}

class Wizard extends Blocker {
  String debugString() => "W";
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
  Coords? coords;

  Space({
    Token? initialToken,
    this.onWizardPath = false,
    String? name,
    this.coords,
  }) {
    if (initialToken != null) {
      tokens.add(initialToken);
    }
    this.name = name ?? ((coords != null) ? nameForCoords(coords!) : '');
  }

  static String nameForCoords(Coords coords) {
    assert(coords.angle % 2 == 1 || coords.radius == 4);
    // We could re-name these to be more consistent. :/
    if (coords.radius == 4) {
      return 'w:${coords.angle}';
    }
    return '${coords.angle ~/ 2}:${coords.radius}';
  }

  bool isBlocked() => tokens.any((token) => token is Blocker);
  void addBlocker() => Blocker().moveTo(this);
  void removeBlocker() {
    var blockers = tokens.where((token) => token is Blocker).toList();
    assert(blockers.length <= 1);
    blockers.forEach((token) => token.removeFromBoard());
  }

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

class SaveState {
  // Example: 1,2,3/0.r.1:2,1.h.2:1/4:7/w:11/1
  Set<int> neededIngredients;
  List<Bottle> bottles;
  List<Space> blockerSpaces;
  Wizard wizard;
  bool haveUsedSpellBreaker;

  SaveState(
      {required this.neededIngredients,
      required this.bottles,
      required this.blockerSpaces,
      required this.wizard,
      required this.haveUsedSpellBreaker});

  factory SaveState.fromString(
      String saveString, Space spaceForName(String name)) {
    Bottle parseBottle(String bottleString) {
      List<String> parts = bottleString.split('.');
      var bottle = Bottle(int.parse(parts[0]), isRevealed: parts[1] == 'r');
      bottle.moveTo(spaceForName(parts[2]));
      return bottle;
    }

    List<String> parts = saveString.split('/');
    return SaveState(
      neededIngredients: parts[0].split(',').map(int.parse).toSet(),
      bottles: parts[1].split(',').map(parseBottle).toList(),
      blockerSpaces: parts[2].split(',').map(spaceForName).toList(),
      wizard: Wizard()..moveTo(spaceForName(parts[3])),
      haveUsedSpellBreaker: int.parse(parts[4]) != 1,
    );
  }

  String toSaveString() {
    String sortAndJoin<T>(Iterable<T> iterable) {
      List<T> list = iterable.toList();
      list.sort();
      return list.join(',');
    }

    String ingredients = sortAndJoin(neededIngredients);
    String bottlesString = sortAndJoin(bottles.map((bottle) {
      var revealed = bottle.isRevealed ? 'r' : 'h';
      return '${bottle.ingredient}.$revealed.${bottle.location!.name}';
    }));
    String blockers = sortAndJoin(blockerSpaces
        .where((space) => space.isBlocked())
        .map((space) => space.name));
    String wizardString = wizard.location!.name;
    String spellbreaker = haveUsedSpellBreaker ? '0' : '1';

    return [ingredients, bottlesString, blockers, wizardString, spellbreaker]
        .join('/');
  }
}

class Coords {
  final int angle, radius;
  Coords(this.angle, this.radius);
}

class Board {
  static const int ingredientCount = 6;

  int distanceVersion = 0;
  late Wizard wizard;
  late List<Bottle> bottles;
  late Space cauldron;
  late List<Space> startSpaces;
  late List<Space> wizardPath;
  late List<Space> blockerSpaces;
  late Set<int> neededIngredients;

  bool haveUsedSpellBreaker = false;

  Map<String, Space>? nameToSpace;

  Board({String? saveString, Random? random}) {
    buildBoardGraph();
    if (saveString != null) {
      placePiecesFromSave(saveString);
    } else if (random != null) {
      placePiecesFromRandom(random);
    } else {
      throw ArgumentError("Either random or saveString required.");
    }
    updateDistances();
  }

  List<Space> connectPath(
      {required Space from,
      required Space to,
      required int spacesBetween,
      bool onWizardPath = false,
      Coords coordsForIndex(int)?}) {
    List<Space> path = [from];
    Space previous = from;
    for (int i = 0; i < spacesBetween; i++) {
      Coords? coords = coordsForIndex == null ? null : coordsForIndex(i);
      Space next = Space(onWizardPath: onWizardPath, coords: coords);
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
    startSpaces = List.generate(startSpacesCount,
        (index) => Space(coords: Coords(2 * index + 1, 0))).toList();
    var wizardStart = Space(onWizardPath: true, coords: Coords(0, 4));
    wizardPath = connectPath(
      from: wizardStart,
      to: wizardStart,
      spacesBetween: wizardPathLength - 1,
      onWizardPath: true,
      coordsForIndex: (index) => Coords(index + 1, 4),
    );
    blockerSpaces = List.generate(
        startSpacesCount, (index) => Space(coords: Coords(2 * index + 1, 7)));

    for (int i = 0; i < wizardPath.length; i++) {
      Space wizardSpace = wizardPath[i];
      if (i % 2 == 1) {
        int pathIndex = i ~/ 2;
        connectPath(
          from: startSpaces[pathIndex],
          to: wizardSpace,
          spacesBetween: 3,
          coordsForIndex: (index) => Coords(i, index + 1),
        );
        connectPath(
          from: wizardSpace,
          to: blockerSpaces[pathIndex],
          spacesBetween: 2,
          coordsForIndex: (index) => Coords(i, index + 5),
        );
        connectPath(
          from: blockerSpaces[pathIndex],
          to: cauldron,
          spacesBetween: 2,
          coordsForIndex: (index) => Coords(i, index + 8),
        );
      }
    }
  }

  Iterable<Space> allSpaces() sync* {
    List<Space> toWalk = [cauldron];
    List<Space> seenNodes = [];

    while (toWalk.isNotEmpty) {
      Space current = toWalk.removeLast();
      yield current;
      seenNodes.add(current);
      for (Space neighbor in current.adjacentSpaces) {
        if (!seenNodes.contains(neighbor)) {
          toWalk.add(neighbor);
        }
      }
    }
  }

  // Belongs on "Graph" class.
  Space spaceForName(String name) {
    if (nameToSpace == null) {
      nameToSpace = Map.fromIterable(allSpaces(),
          key: (space) => space.name, value: (space) => space);
    }
    return nameToSpace![name]!;
  }

  void placePiecesFromSave(String saveString) {
    SaveState? save;
    save = SaveState.fromString(saveString, spaceForName);
    neededIngredients = save.neededIngredients;
    bottles = save.bottles;
    wizard = save.wizard;
    for (var blocker in save.blockerSpaces) {
      blocker.addBlocker();
    }
    haveUsedSpellBreaker = save.haveUsedSpellBreaker;
  }

  void placePiecesFromRandom(Random random) {
    List<int> ingredients = List.generate(ingredientCount, (index) => index);
    ingredients.shuffle(random);
    neededIngredients = ingredients.take(3).toSet();

    bottles = List.generate(ingredientCount, (index) => Bottle(index));
    bottles.shuffle(random);
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
    // copy the list (with toList) to avoid modificiation during iteration.
    var bottlesToRemove =
        location.tokens.where((token) => token is Bottle).toList();

    for (var bottle in bottlesToRemove) {
      // TODO(eseidel): Should be nearest open start location.
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

  void blockRandomPath(Random random) {
    List<int> pathsToBlock = collectUnblockedPaths().toList()..shuffle(random);
    assert(pathsToBlock.isNotEmpty);
    blockPath(pathsToBlock.first);
  }

  // Mostly for testing.
  void blockPath(int path) {
    assert(!pathIsBlocked(path));
    _moveBottlesBackToStart(blockerSpaces[path]);
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
    Set<int> revealedIngredients = bottles
        .where((bottle) => bottle.isRevealed)
        .map((bottle) => bottle.ingredient)
        .toSet();
    Set<int> intersection = revealedIngredients.intersection(neededIngredients);
    return intersection.length;
  }

  int completedRequiredIngredientCount() {
    var tokens = cauldron.tokens;
    Set<int> completedIngredients =
        tokens.map((token) => (token as Bottle).ingredient).toSet();
    Set<int> intersection =
        completedIngredients.intersection(neededIngredients);
    return intersection.length;
  }

  bool isLegalBoardMove(Action action, PlannedMove plan) {
    // Use a passed in action to catch cheats. :)
    assert(action == plan.action);
    return isLegalMove(plan.bottle, plan.toSpace, action, this);
  }

  // These could be extension methods?
  // For testing, these do not respect bottle visibility!
  bool isBottleNeeded(Bottle bottle) =>
      neededIngredients.contains(bottle.ingredient);
  List<Bottle> get neededBottles => bottles.where(isBottleNeeded).toList();
  List<Bottle> get unneededBottles =>
      bottles.where((bottle) => !isBottleNeeded(bottle)).toList();

  String saveString() {
    return SaveState(
      neededIngredients: neededIngredients,
      bottles: bottles,
      blockerSpaces: blockerSpaces,
      wizard: wizard,
      haveUsedSpellBreaker: haveUsedSpellBreaker,
    ).toSaveString();
  }

  String debugString() {
    String debug =
        cauldron.debugString() + " " + neededIngredients.join(",") + "\n";
    for (int i = 0; i < startSpaces.length; i++) {
      Space start = startSpaces[i];
      var path = shortestPathToGoal(start, ignoreBlocks: true);
      debug += " " + wizardPath[i * 2].debugString() + "\n";
      debug += stringForPath(path) + "\n";
    }
    return debug;
  }
}

class Roller {
  final Random random;

  late final Die<int> numberDie = Die<int>([1, 2, 3, 4, 5, 6], random);
  late final Die<Actor> actorDie = Die<Actor>([
    Actor.wizard,
    Actor.wizard,
    Actor.potion,
    Actor.potion,
    Actor.potion,
    Actor.potion,
  ], random);
  late final Die<Action> actionDie = Die<Action>([
    Action.magic,
    Action.magic,
    Action.magic,
    Action.moveThree,
    Action.moveThree,
    Action.moveFour,
  ], random);

  Roller(this.random);

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

  @override
  int get hashCode => count.hashCode + group.hashCode;
}

// TODO: Does this belong on a Rules object?
int maxSpacesMoved(Action action) {
  if (action == Action.moveThree) return 3;
  if (action == Action.moveFour) return 4;
  if (action == Action.magic) return 6;
  assert(false);
  return 0;
}

bool isLegalMove(Bottle bottle, Space toSpace, Action action, Board board) {
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
    // Should we assert explicit pass here?
    return true;
  }
  if (toSpace == board.cauldron && !bottle.isRevealed) {
    // Not allowed to move a non-revealed ingredient into the cauldron.
    return false;
  }
  if (toSpace == board.cauldron && !board.isBottleNeeded(bottle)) {
    // Although possibly legal, we should never plan this move.
    return false;
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
  int? seed;
  final Random _random;
  final GameStats stats = GameStats();
  late final Board board = Board(random: _random);
  final Planner planner = Planner();
  late final Roller roller = Roller(_random);

  bool isComplete = false;
  bool wizardWon = false;

  CauldronQuest([this.seed]) : _random = Random(seed);

  void handleRoll(Actor actor, Action action) {
    stats.turnCount++;
    if (actor == Actor.wizard && action == Action.magic) {
      stats.blockCount++;
      board.blockRandomPath(_random);
      // TODO(eseidel): Hack until we know how to plan spell-breaker usage.
      if (!board.haveUsedSpellBreaker)
        board.unblockWithSpellBreaker(board.collectBlockedPaths().first);
      return;
    }
    if (actor == Actor.potion && action == Action.magic) {
      stats.magicCount++;
      PlannedCharm plan = planner.planCharm(board);
      handleCharmRole(action, plan);
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

  void handleCharmRole(Action action, PlannedCharm plan) {
    bool magicSucess = false;
    switch (plan.charm) {
      case Charm.revealCharm:
        if (magicSucess = roller.tryRevealCharm()) {
          stats.potionsRevealed++;
          assert(!plan.bottle.isRevealed);
          plan.bottle.isRevealed = true;
        }
        break;
      case Charm.swapCharm:
        if (magicSucess = roller.trySwapCharm()) {
          stats.potionsSwapped++;
          handleBottleSwap(plan.bottle, plan.swapWith!);
        }
        break;
      case Charm.superPowerCharm:
        if (magicSucess = roller.trySuperPowerCharm(planner)) {
          stats.supercharmCount++;
          handleBottleMove(action, plan.superCharmMove!);
        }
        break;
    }
    if (!magicSucess) {
      stats.magicFailures++;
    }
  }

  void handleBottleSwap(Bottle a, Bottle b) {
    Space newBSpace = a.location!;
    Space newASpace = b.location!;
    a.moveTo(newASpace);
    b.moveTo(newBSpace);
  }

  void handleBottleMove(Action action, PlannedMove plan) {
    // TODO: Should not trust anything from PlannedMove in this function!
    stats.potionMoveDistance += plan.actualDistance;
    stats.wastedMoveDistance += plan.possibleDistance - plan.actualDistance;
    assert(board.isLegalBoardMove(action, plan));
    plan.bottle.moveTo(plan.toSpace);
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
    Actor actor = roller.actorDie.roll();
    Action action = roller.actionDie.roll();
    handleRoll(actor, action);
    checkForWin();
    if (isComplete) {
      return;
    }
    // TODO: Not sure this belongs here.
    board.updateDistances();
  }

  int get turnsTaken {
    return stats.turnCount;
  }
}
