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

class PlannedCharm {
  final Charm charm;
  final Bottle bottle;
  final Bottle? swapWith;
  final PlannedMove? superCharmMove;
  PlannedCharm(
      {required this.charm,
      required this.bottle,
      this.swapWith,
      this.superCharmMove});
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

  PlannedCharm planCharm(Board board) {
    // Reveal if we haven't found all 3 yet.
    if (board.revealedRequiredIngredientCount() < 3) {
      Bottle bottle = board.bottles.firstWhere((bottle) => !bottle.isRevealed);
      // TODO: Could plan to reveal a bottle based on proximity to cauldron?
      return PlannedCharm(charm: Charm.revealCharm, bottle: bottle);
    }

    // Otherwise attempt a swap if benificial?
    int revealedCount = board.bottles
        .fold(0, (count, bottle) => count + (bottle.isRevealed ? 1 : 0));
    if (revealedCount < board.bottles.length) {
      // Swap if swapping reduces total distance to win.
      Bottle furthestRevealed = board.bottles
          .where((bottle) => bottle.isRevealed)
          .reduce((a, b) =>
              a.location!.distanceToGoal > b.location!.distanceToGoal ? a : b);
      Bottle closestHidden = board.bottles
          .where((bottle) => !bottle.isRevealed)
          .reduce((a, b) =>
              a.location!.distanceToGoal < b.location!.distanceToGoal ? a : b);

      // SuperCharm chance is 37.7% and moves 6 so EV is 2.26.
      const int minimumGainWorthSwapping = 3;

      if (furthestRevealed.location!.distanceToGoal >=
          closestHidden.location!.distanceToGoal + minimumGainWorthSwapping) {
        return PlannedCharm(
            charm: Charm.swapCharm,
            bottle: closestHidden,
            swapWith: furthestRevealed);
      }
    }

    // Are there situations where SuperCharm should be higher priority?
    // When the path to get the bottle is longer than X?
    // When the chance of winning w/o the supercharm is < 37.7%?
    // When a bottle is in the way of the wizard (going to get reset)?
    PlannedMove superCharmMove = pickBottleToSuperCharm(board);
    return PlannedCharm(
        charm: Charm.superPowerCharm,
        bottle: superCharmMove.bottle,
        superCharmMove: superCharmMove);
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

  PlannedMove planBottleMove(Board board, Action action) {
    int maxDistance = maxSpacesMoved(action);
    // Move a needed potion, otherwise move a random non-reveleaed potion.
    Bottle? bottleToMove;
    List<Bottle> neededBottles = board.bottles
        .where((bottle) =>
            bottle.isRevealed &&
            bottle.location != board.cauldron &&
            board.neededIngredients.contains(bottle.ingredient))
        .toList();
    if (neededBottles.isNotEmpty) {
      bottleToMove = neededBottles.first;
    } else {
      bottleToMove = board.bottles.firstWhere(
          (bottle) => !bottle.isRevealed && bottle.location != board.cauldron);
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
