import 'dart:math';

import 'package:cauldron_quest/astar.dart';

import 'rules.dart';

class PlannedMove {
  final Bottle bottle;
  final Space toSpace;
  final Action action;
  final int possibleDistance;
  final int actualDistance;

  PlannedMove({
    required this.bottle,
    required this.toSpace,
    required this.action,
    required this.possibleDistance,
    required this.actualDistance,
  });
}

class PlannedReveal {
  final Bottle bottle;
  PlannedReveal({required this.bottle});
}

class Planner {
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

  Charm planCharm(Board board) {
    // Can't yet check < 3, triggers crash.
    // if (board.revealedRequiredIngredientCount() < 3) {
    if (board.bottles.any((bottle) => !bottle.isRevealed)) {
      return Charm.revealCharm;
    }
    // }
    // Swap if swapping reduces total distance to win.
    // Otherwise supercharm?
    return Charm.superPowerCharm;
  }

  PlannedMove pickBottleToSuperCharm(Board board) {
    int superCharmMoveDistance = 6;
    // Try all the bottles, see what moving them would do, pick the best move?
    List<PlannedMove> possibleMoves = [];
    for (Bottle bottle in board.bottles) {
      List<Space> path = board
          .shortestPathToGoal(bottle.location!, ignoreBlocks: true)
          .toList();
      int maxMoveDistance = bottle.isRevealed ? path.length : path.length - 1;
      // Bottles not revealed, but just outside the cauldron don't need to move.
      if (maxMoveDistance < 1) continue;
      // path includes start, so a second -1 is needed.
      int actualDistance = min(superCharmMoveDistance, maxMoveDistance - 1);
      Space toSpace = path[actualDistance];
      // TODO: Handle the case of an ilegal move (moving onto a blocker?)
      possibleMoves.add(PlannedMove(
        bottle: bottle,
        toSpace: toSpace,
        action: Action.magic,
        possibleDistance: superCharmMoveDistance,
        actualDistance: actualDistance,
      ));
    }
    return possibleMoves.first;
  }

  PlannedReveal planPotionReveal(Board board) {
    Bottle bottle = board.bottles.firstWhere((bottle) => !bottle.isRevealed);
    // TODO: Could plan to reveal a bottle based on proximity to cauldron?
    return PlannedReveal(bottle: bottle);
  }

  PlannedMove planBottleMove(Board board, Action action) {
    int maxDistance = maxSpacesMoved(action);
    // Move a revealed potion.
    // Otherwise move a random non-revealed potion.
    Bottle? bottleToMove;
    List<Bottle> revealedBottles = board.bottles
        .where(
            (bottle) => bottle.isRevealed && bottle.location != board.cauldron)
        .toList();
    if (revealedBottles.isNotEmpty) {
      bottleToMove = revealedBottles.first;
    } else {
      bottleToMove = board.bottles
          .firstWhere((bottle) => bottle.location != board.cauldron);
    }
    Space fromSpace = bottleToMove.location!;
    // var path = board.shortestPathToGoal(fromSpace).toList();
    var path = shortestPath(from: fromSpace, to: board.cauldron);
    if (path == null) {
      // This can happen if our path is blocked by the wizard (or worse yet,
      // by the wizard on one side and a blocker on another).
      // This isn't quite right, but prevents crashing at least.
      List<Space> blockedPath = shortestPath(
              from: fromSpace, to: board.cauldron, ignoreBlockers: true)!
          .toList();
      int blockedIndex = blockedPath.indexWhere((space) => space.isBlocked());
      path = blockedPath.sublist(0, blockedIndex - 1);
    }

    int actualDistance = min(maxDistance, path.length - 1);
    return PlannedMove(
      bottle: bottleToMove,
      // Path can be empty if you're up next to a blocker!
      toSpace: path.isEmpty ? fromSpace : path[actualDistance],
      action: action,
      possibleDistance: maxDistance,
      actualDistance: actualDistance,
    );
  }
}
