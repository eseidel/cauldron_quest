import 'dart:math';

import 'package:cauldron_quest/astar.dart';

// This shouldn't import rules.dart directly, but rather some interface.
import 'rules.dart';

class PlannedMove {
  final Bottle bottle;
  final Space toSpace;
  final Action action;
  final int actualDistance;
  final bool explicitPass;

  PlannedMove({
    required this.bottle,
    required this.toSpace,
    required this.action,
    required this.actualDistance,
    this.explicitPass = false,
  });

  int get possibleDistance => maxSpacesMoved(action);
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
        actualDistance: actualDistance,
      ));
    }
    return possibleMoves.first;
  }

  List<Bottle> bottlesInPreferredMoveOrder(Board board) {
    bool notInGoal(Bottle bottle) => bottle.location != board.cauldron;
    bool isNeeded(Bottle bottle) =>
        board.neededIngredients.contains(bottle.ingredient);
    int distanceToGoal(Bottle bottle) => bottle.location!.distanceToGoal;

    // Can't even move ones in goal, no sense in sorting them.
    List<Bottle> bottles = board.bottles.where(notInGoal).toList();

    const int aFirst = -1;
    const int bFirst = 1;
    bottles.sort((a, b) {
      // Only time we wouldn't want to move an isNeeded bottle first is when
      // it's blocked and can't move otherwise.
      if (isNeeded(a) != isNeeded(b)) {
        return isNeeded(a) ? aFirst : bFirst;
      }
      // TODO: If we built plans for each first, we could prefer non-revealed
      // bottles with open moves in front of them over blocked ones.
      if (a.isRevealed != b.isRevealed) {
        return a.isRevealed ? aFirst : bFirst;
      }
      if (a.isRevealed) {
        // Revealed bottles: prefer closer-to-goal.
        return distanceToGoal(a).compareTo(distanceToGoal(b));
      } else {
        // Hidden bottles: prefer further-to-goal.
        return distanceToGoal(b).compareTo(distanceToGoal(a));
      }
    });

    return bottles;
  }

  List<Space> pathUpToBlocker(Board board, Space fromSpace) {
    List<Space> blockedPath =
        shortestPath(from: fromSpace, to: board.cauldron, ignoreBlockers: true)!
            .toList();
    int blockedIndex = blockedPath.indexWhere((space) => space.isBlocked());
    return blockedPath.sublist(0, blockedIndex - 1);
  }

  PlannedMove planFromPath(Bottle bottle, List<Space> path, Action action) {
    int maxDistance = maxSpacesMoved(action);
    Space fromSpace = bottle.location!;
    // path includes the start space.
    assert(fromSpace == path.first);
    int actualDistance = min(maxDistance, path.length - 1);
    return PlannedMove(
      bottle: bottle,
      // Path can be empty if you're up next to a blocker!
      toSpace: path.isEmpty ? fromSpace : path[actualDistance],
      action: action,
      actualDistance: actualDistance,
    );
  }

  PlannedMove planBottleMove(Board board, Action action) {
    late PlannedMove plan;
    // Move a needed potion, otherwise move a random non-reveleaed potion.
    List<Bottle> sortedBottles = bottlesInPreferredMoveOrder(board);
    for (Bottle bottle in sortedBottles) {
      var path = shortestPath(from: bottle.location!, to: board.cauldron);
      if (path == null) {
        // This can happen if our path is blocked by the wizard (or worse yet,
        // by the wizard on one side and a blocker on another).
        // This isn't quite right, but prevents crashing at least.
        continue;
      }
      plan = planFromPath(bottle, path, action);
      // A bit of a hack, to try a different bottle if we can't make a legal
      // move with this one.
      if (board.isLegalBoardMove(action, plan)) {
        return plan;
      }
    }
    // This can happen if all paths are blocked (5 from blockers and the last
    // temporarily by the wizard).  In this case, try again, this time
    // moving just as much as we can.
    for (Bottle bottle in sortedBottles) {
      var blockedPath = shortestPath(
              from: bottle.location!, to: board.cauldron, ignoreBlockers: true)!
          .toList();

      // The cauldron functions as a blocker for hidden bottles.
      int blockedIndex = blockedPath
          .indexWhere((space) => space.isBlocked() || space == board.cauldron);
      blockedPath = blockedPath.sublist(0, blockedIndex - 1);
      // Avoids the case of the picked bottle being right up against a blocker
      // this could be avoided better by pre-computing all bottle plans and
      // comparing the plans instead.
      if (blockedPath.isEmpty) continue;

      plan = planFromPath(bottle, blockedPath, action);
      // Still check for legality in case this is landing on a blocker, etc.
      if (board.isLegalBoardMove(action, plan)) {
        return plan;
      }
    }
    // This is never the right exit, but there do exist boards where we would
    // have to move backwards.  I'd rather just have the planner pass for now.
    return PlannedMove(
        bottle: sortedBottles.first,
        toSpace: sortedBottles.first.location!,
        action: action,
        actualDistance: 0,
        explicitPass: true);
  }
}
