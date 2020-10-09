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

  test('super power charm executeReroll largest', () {
    var dice = [1, 2, 3];
    executeReroll(dice, Reroll.largest(1));
    expect(dice.contains(1), equals(true));
    expect(dice.contains(2), equals(true));
  });
}
