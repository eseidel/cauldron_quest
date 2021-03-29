import 'package:cauldron_quest/planner.dart';
import 'package:cauldron_quest/rules.dart';

void printCharmPercentages(Planner planner) {
  int tries = 100000;
  int revealCharm = 0;
  int swapCharm = 0;
  int superPowerCharm = 0;
  for (int x = 0; x < tries; x++) {
    if (tryRevealCharm()) revealCharm += 1;
    if (trySwapCharm()) swapCharm += 1;
    if (trySuperPowerCharm(planner)) superPowerCharm += 1;
  }
  String toPercent(int value) {
    double percent = value / tries * 100;
    return percent.toStringAsFixed(1) + "%";
  }

  print("Reveal: ${toPercent(revealCharm)}");
  print("Swap: ${toPercent(swapCharm)}");
  print("Super Power: ${toPercent(superPowerCharm)}");
}

void main() {
  print("Charm % chance of success:");
  printCharmPercentages(Planner());
}
