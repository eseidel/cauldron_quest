import 'package:cauldron_quest/astar.dart';
import 'package:test/test.dart';
import 'package:cauldron_quest/planner.dart';
import 'package:cauldron_quest/rules.dart';

void main() {
  test('super power charm planReroll', () {
    Planner p = Planner();
    expect(p.planReroll([2, 4, 6]), equals(Reroll.none()));
    expect(p.planReroll([null, null, null]), equals(Reroll.all()));

    expect(p.planReroll([1, 1, 1]), equals(Reroll.smallest(2)));
    expect(p.planReroll([1, 1, 2]), equals(Reroll.smallest(2)));
    expect(p.planReroll([1, 1, 3]), equals(Reroll.smallest(2)));
    expect(p.planReroll([1, 2, 3]), equals(Reroll.smallest(2)));
    expect(p.planReroll([3, 3, 1]), equals(Reroll.smallest()));
    expect(p.planReroll([2, 3, 3]), equals(Reroll.smallest()));
    expect(p.planReroll([3, 3, 3]), equals(Reroll.smallest()));
    expect(p.planReroll([1, 3, 6]), equals(Reroll.smallest()));
    expect(p.planReroll([1, 5, 5]), equals(Reroll.smallest()));
    expect(p.planReroll([5, 5, 2]), equals(Reroll.none()));
    expect(p.planReroll([3, 5, 5]), equals(Reroll.largest()));
    expect(p.planReroll([3, 6, 5]), equals(Reroll.largest()));
    expect(p.planReroll([5, 6, 4]), equals(Reroll.largest()));
    expect(p.planReroll([5, 5, 5]), equals(Reroll.largest()));
    expect(p.planReroll([6, 6, 4]), equals(Reroll.largest()));
    expect(p.planReroll([6, 5, 6]), equals(Reroll.largest()));
    expect(p.planReroll([6, 6, 6]), equals(Reroll.largest(2)));
  });

  test('planMoveBottle', () {
    Planner planner = Planner();
    Board board = Board();
    var plan = planner.planBottleMove(board, Action.moveThree);
    expect(plan.action, Action.moveThree);
    expect(plan.actualDistance, 3);
    expect(plan.possibleDistance, 3);
    // shortestPath includes start.
    expect(
        shortestPath(from: plan.bottle.location!, to: plan.toSpace)!.length, 4);
    expect(isLegalMove(plan.bottle, plan.toSpace, plan.action), true);
  });

  test('planCharm reveal until ingredients found', () {
    Planner planner = Planner();
    Board board = Board();
    var neededBottles = board.bottles
        .where((bottle) => board.neededIngredients.contains(bottle.ingredient))
        .toList();
    expect(planner.planCharm(board).charm, Charm.revealCharm);
    neededBottles[0].isRevealed = true; // ignoring plan.
    expect(board.revealedRequiredIngredientCount(), 1);
    expect(planner.planCharm(board).charm, Charm.revealCharm);
    neededBottles[1].isRevealed = true; // ignoring plan.
    expect(board.revealedRequiredIngredientCount(), 2);
    expect(planner.planCharm(board).charm, Charm.revealCharm);
    neededBottles[2].isRevealed = true; // ignoring plan.
    expect(board.revealedRequiredIngredientCount(), 3);
    // Super Power Charm is the default (also no swaps would help here).
    expect(planner.planCharm(board).charm, Charm.superPowerCharm);
  });

  test('planCharm swap when helpful', () {
    Planner planner = Planner();
    Board board = Board();
    bool bottleNeeded(Bottle bottle) =>
        board.neededIngredients.contains(bottle.ingredient);
    var neededBottles = board.bottles.where(bottleNeeded).toList();

    // planCharm will always reveal until all 3 needed are revealed.
    expect(planner.planCharm(board).charm, Charm.revealCharm);
    neededBottles[0].isRevealed = true;
    neededBottles[1].isRevealed = true;
    neededBottles[2].isRevealed = true;

    // Move an unrevealed bottle closer to goal.
    var unneededBottle =
        board.bottles.firstWhere((bottle) => !bottleNeeded(bottle));
    var path =
        shortestPath(from: unneededBottle.location!, to: board.cauldron)!;
    // Don't bother swapping for less than a 3 space gain:
    var toSpace = path[3]; // 0 = start space, 3 moves 3 from start.
    unneededBottle.moveTo(toSpace);
    var plan = planner.planCharm(board);
    expect(plan.charm, Charm.swapCharm);
    // Which is revealed vs not is somewhat an implementation detail:
    expect(plan.bottle, unneededBottle);
    expect(plan.swapWith!.isRevealed, true);
  });
}
