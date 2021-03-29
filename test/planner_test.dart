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
}
