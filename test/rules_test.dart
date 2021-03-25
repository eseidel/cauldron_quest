import 'package:test/test.dart';
import 'package:cauldron_quest/rules.dart';

void main() {
  test('super power charm planReroll', () {
    expect(planReroll([2, 4, 6]), equals(Reroll.none()));
    expect(planReroll([null, null, null]), equals(Reroll.all()));

    expect(planReroll([1, 1, 1]), equals(Reroll.smallest(2)));
    expect(planReroll([1, 1, 2]), equals(Reroll.smallest(2)));
    expect(planReroll([1, 1, 3]), equals(Reroll.smallest(2)));
    expect(planReroll([1, 2, 3]), equals(Reroll.smallest(2)));
    expect(planReroll([3, 3, 1]), equals(Reroll.smallest()));
    expect(planReroll([2, 3, 3]), equals(Reroll.smallest()));
    expect(planReroll([3, 3, 3]), equals(Reroll.smallest()));
    expect(planReroll([1, 3, 6]), equals(Reroll.smallest()));
    expect(planReroll([1, 5, 5]), equals(Reroll.smallest()));
    expect(planReroll([5, 5, 2]), equals(Reroll.none()));
    expect(planReroll([3, 5, 5]), equals(Reroll.largest()));
    expect(planReroll([3, 6, 5]), equals(Reroll.largest()));
    expect(planReroll([5, 6, 4]), equals(Reroll.largest()));
    expect(planReroll([5, 5, 5]), equals(Reroll.largest()));
    expect(planReroll([6, 6, 4]), equals(Reroll.largest()));
    expect(planReroll([6, 5, 6]), equals(Reroll.largest()));
    expect(planReroll([6, 6, 6]), equals(Reroll.largest(2)));
  });
  test('super power charm executeReroll smallest', () {
    var dice = [1, 2, 3];
    executeReroll(dice, Reroll.smallest(1));
    expect(dice.contains(2), equals(true));
    expect(dice.contains(3), equals(true));
  });

  test('path blocking', () {
    Board board = Board();
    expect(board.unblockedPathCount, 6);
    board.blockRandomPath();
    expect(board.unblockedPathCount, 5);
  });

  test('wizard moving', () {
    Board board = Board();
    expect(board.wizardLocation, 0);
    board.moveWizard(3);
    expect(board.wizardLocation, 3);
  });

  test('spellbreaker token', () {
    Board board = Board();
    expect(board.haveUsedSpellBreaker, false);
    board.blockPath(0);
    expect(board.pathIsBlocked(0), true);
    board.unblockWithSpellBreaker(0);
    expect(board.pathIsBlocked(0), false);
    expect(board.haveUsedSpellBreaker, true);
  });
}
