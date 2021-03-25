import 'package:cauldron_quest/rules.dart';
import 'package:cauldron_quest/stats.dart';
import 'package:stats/stats.dart';

void printCharmPercentages() {
  int tries = 100000;
  int revealCharm = 0;
  int swapCharm = 0;
  int superPowerCharm = 0;
  for (int x = 0; x < tries; x++) {
    if (tryRevealCharm()) revealCharm += 1;
    if (trySwapCharm()) swapCharm += 1;
    if (trySuperPowerCharm()) superPowerCharm += 1;
  }
  String toPercent(int value) {
    double percent = value / tries * 100;
    return percent.toStringAsFixed(1) + "%";
  }

  print("Reveal: ${toPercent(revealCharm)}");
  print("Swap: ${toPercent(swapCharm)}");
  print("Super Power: ${toPercent(superPowerCharm)}");
}

void printAggregateStatistics(List<GameStats> gameStats) {
  void printStats(String label, Iterable<int> values) {
    var stats = Stats.fromData(values);
    print(label + ": " + stats.withPrecision(3).toString());
  }

  printStats("Turns until blocked", gameStats.map((stats) => stats.turnCount));
  printStats("Magics rolled", gameStats.map((stats) => stats.magicCount));
  printStats(
      "Potions revealed", gameStats.map((stats) => stats.potionsRevealed));
  printStats(
      "Potion move rolled", gameStats.map((stats) => stats.potionMoveCount));
  printStats(
      "Wizard move rolled", gameStats.map((stats) => stats.wizardMoveCount));
  printStats("Potion spaces moved",
      gameStats.map((stats) => stats.potionMoveDistance));
  printStats("Wizard spaces moved",
      gameStats.map((stats) => stats.wizardMoveDistance));

  String toPercent(int value) {
    double percent = value / gameStats.length * 100;
    return percent.toStringAsFixed(1) + "%";
  }

  int possibleWinCount = 0;
  gameStats.forEach((GameStats stats) {
    if (stats.couldHaveWon) possibleWinCount++;
  });
  print("${toPercent(possibleWinCount)} max wins, N=${gameStats.length}");
}

void main() {
  print("Charm % chance of success:");
  printCharmPercentages();

  int tries = 10000;
  print("\nSimulating $tries games:");
  List<GameStats> gameStats = <GameStats>[];
  for (int i = 0; i < tries; i++) {
    CauldronQuest game = CauldronQuest();
    while (!game.isComplete) {
      game.takeTurn();
    }
    gameStats.add(game.stats);
  }
  printAggregateStatistics(gameStats);
}
