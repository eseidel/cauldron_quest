import 'rules.dart';

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
}
