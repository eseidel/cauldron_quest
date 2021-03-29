import 'package:cauldron_quest/rules.dart';
import 'package:cauldron_quest/stats.dart';
import 'package:stats/stats.dart';
import 'package:cauldron_quest/planner.dart';

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

void printAggregateStatistics(List<GameStats> gameStats) {
  void printStats(String label, Iterable<int> values) {
    var stats = Stats.fromData(values);
    print(label + ": " + stats.withPrecision(3).toString());
  }

  // Mean game length is expected to be 42 turns.  7 success are needed (r) and
  // each success has a 1/6th chance (p), so the mean of the negative binomial
  // distribution = r / p = 7 * 6 = 42.
  // https://stattrek.com/probability-distributions/negative-binomial.aspx
  printStats("Turns until blocked", gameStats.map((stats) => stats.turnCount));
  // Potion move roll is 1/3 chance.  1/3 * 42 = 14.
  printStats(
      "Potion move rolled", gameStats.map((stats) => stats.potionMoveCount));
  // Wizard move roll is 1/6 chance.  1/6 * 42 = 7.
  printStats(
      "Wizard move rolled", gameStats.map((stats) => stats.wizardMoveCount));
  // Magic roll is 1/3 chance.  1/3 * 42 = 14.
  printStats("Magics rolled", gameStats.map((stats) => stats.magicCount));
  printStats(
      "Potions revealed", gameStats.map((stats) => stats.potionsRevealed));
  printStats("Potions swapped", gameStats.map((stats) => stats.potionsSwapped));
  printStats("Supercharms", gameStats.map((stats) => stats.supercharmCount));
  printStats("Magics failed", gameStats.map((stats) => stats.magicFailures));

  printStats("Potion spaces moved",
      gameStats.map((stats) => stats.potionMoveDistance));
  printStats("Wizard spaces moved",
      gameStats.map((stats) => stats.wizardMoveDistance));

  String toPercent(int value) {
    double percent = value / gameStats.length * 100;
    return percent.toStringAsFixed(1) + "%";
  }

  int actualWins =
      gameStats.fold(0, (int sum, stats) => sum + (stats.playerWon ? 1 : 0));
  print("${toPercent(actualWins)} max wins, N=${gameStats.length}");

  int possibleWins =
      gameStats.fold(0, (int sum, stats) => sum + (stats.couldHaveWon ? 1 : 0));
  print("${toPercent(possibleWins)} max wins, N=${gameStats.length}");
}

void main() {
  print("Charm % chance of success:");
  printCharmPercentages(Planner());

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
