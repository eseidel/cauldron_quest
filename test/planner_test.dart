import 'package:cauldron_quest/astar.dart';
import 'package:test/test.dart';
import 'package:cauldron_quest/planner.dart';
import 'package:cauldron_quest/rules.dart';

extension BoardTest on Board {
  void moveToCauldron(Bottle bottle) {
    bottle.isRevealed = true;
    bottle.moveTo(cauldron);
  }
}

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

  test('bottlesInPreferredMoveOrder', () {
    Planner planner = Planner();

    Board board = Board();
    board.moveToCauldron(board.bottles.first);
    List<Bottle> bottles = planner.bottlesInPreferredMoveOrder(board);
    expect(bottles.length, 5);

    board = Board();
    board.neededBottles.first.isRevealed = true;
    bottles = planner.bottlesInPreferredMoveOrder(board);
    expect(bottles.first, board.neededBottles.first);
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
    expect(isLegalMove(plan.bottle, plan.toSpace, plan.action, board), true);
  });

  test('planMoveBottle order', () {
    Planner planner = Planner();
    Board board = Board();

    var unneededBottle = board.unneededBottles.first;
    unneededBottle.isRevealed = true;
    expect(planner.planBottleMove(board, Action.moveThree).bottle,
        isNot(unneededBottle));
    var neededBottle = board.neededBottles.first;
    neededBottle.isRevealed = true;
    expect(
        planner.planBottleMove(board, Action.moveThree).bottle, neededBottle);
  });

  test('planMoveBottle last unrevealed bottle', () {
    Board board = Board();
    var neededBottles = board.neededBottles;
    board.moveToCauldron(neededBottles[0]);
    board.moveToCauldron(neededBottles[1]);
    var lastHiddenBottle = neededBottles[2];
    for (var bottle in board.unneededBottles) {
      bottle.isRevealed = true;
    }

    // Move the last bottle so close it can't move a full set.
    var path =
        shortestPath(from: lastHiddenBottle.location!, to: board.cauldron)!;
    lastHiddenBottle.moveTo(path[path.length - 2]);

    Planner planner = Planner();
    var plan = planner.planBottleMove(board, Action.moveThree);
    expect(board.isLegalBoardMove(Action.moveThree, plan), true);
    expect(plan.bottle, isNot(lastHiddenBottle));
  });

  test('planCharm reveal until ingredients found', () {
    Planner planner = Planner();
    Board board = Board();
    var neededBottles = board.neededBottles;
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
    var neededBottles = board.neededBottles;

    // planCharm will always reveal until all 3 needed are revealed.
    expect(planner.planCharm(board).charm, Charm.revealCharm);
    neededBottles[0].isRevealed = true;
    neededBottles[1].isRevealed = true;
    neededBottles[2].isRevealed = true;

    // Move an unrevealed bottle closer to goal.
    var unneededBottle = board.unneededBottles.first;
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

  test('planBottleMove crash when blocked by wizard', () {
    Planner planner = Planner();
    Board board = Board(
        saveString:
            "2,4,5/5.r.goal,0.r.1:9,1.r.2:0,3.r.3:0,2.r.4:3,4.r.5:0/1:7/w:9");
    planner.planBottleMove(board, Action.moveThree);
  });

  test('planBottleMove all moves are blocked', () {
    // 5 paths are blocked and wizard is blocking the last one.
    Planner planner = Planner();
    Board board = Board(
        saveString:
            "1,4,5/0.r.goal,1.r.w:10,2.r.2:0,3.r.4:0,4.r.goal,5.r.goal/0:7,2:7,3:7,4:7,5:7/w:3");
    planner.planBottleMove(board, Action.moveThree);
  });

  test('planBottleMove avoids moving useless revealed', () {
    Board board = Board();
    for (var bottle in board.unneededBottles) {
      bottle.isRevealed = true;
    }
    var plan = Planner().planBottleMove(board, Action.moveThree);
    expect(plan.bottle.isRevealed, false);
  });
  test('planBottleMove shortens moves when necessary', () {
    // There is no legal 4-space move towards the goal on this board.
    // So we pick one and move it as many as possible.
    // That's not officially legal, but we're bending the rules here.
    Board board = Board(
        saveString:
            "3,4,5/0.h.5:6,1.h.5:6,2.h.5:8,3.r.goal,4.h.3:7,5.r.goal/0:7,1:7,4:7/w:5");
    var plan = Planner().planBottleMove(board, Action.moveFour);
    expect(plan.actualDistance, lessThan(4));
  });

  test('planBottleMove pick a further hidden bottle', () {
    // If all bottles are hidden, pick the furthest hidden bottle.
    Board board = Board(
        saveString:
            "0,1,3/0.h.3:6,1.h.5:9,2.h.4:0,3.h.1:6,4.h.2:0,5.h.0:0/0:7,1:7,2:7,3:7,4:7/w:11");
    var plan = Planner().planBottleMove(board, Action.moveThree);
    expect(plan.bottle.ingredient, isNot(1));
  });

  test('planBottleMove pick a bottle not adjacent to a blocker', () {
    // If all bottles are hidden, pick the furthest hidden bottle.
    Board board = Board(
        saveString:
            "0,2,4/0.r.goal,1.r.3:0,2.r.0:6,3.r.1:0,4.r.5:3,5.r.2:0/0:7,1:7,2:7,3:7,4:7/w:11");
    var plan = Planner().planBottleMove(board, Action.moveThree);
    // 2 is revealed and very close to the goal, but since all paths are
    // blocked and this one is adjacent to a blocker, we should pick another
    // bottle to maximize movement.
    expect(plan.bottle.ingredient, isNot(2));
  });

  test('planBottleMove how do we pass?', () {
    // Possibly unrealistic since this has unneeded ingredients in the cauldron.
    Board board = Board(
        saveString:
            "0,2,4/0.r.goal,1.r.goal,2.h.0:9,3.r.goal,4.r.goal,5.r.goal/1:7,3:7,4:7,5:7/w:7");
    var plan = Planner().planBottleMove(board, Action.moveThree);
    // Make an *explicit* pass (not legal) to avoid moving.
    expect(plan.explicitPass, true);
  });
}
