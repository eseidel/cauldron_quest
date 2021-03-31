import 'package:cauldron_quest/rules.dart';
import 'package:cauldron_quest/stats.dart';
import 'package:stats/stats.dart';

void printAggregateStatistics(List<GameStats> gameStats) {
  void printStats(String label, Iterable<int> values) {
    var stats = Stats.fromData(values);
    print(label + ": " + stats.withPrecision(3).toString());
  }

  bool wasWin(GameStats stats) => stats.playerWon;
  bool wasLoss(GameStats stats) => !stats.playerWon;

  // Mean game length is expected to be 42 turns.  7 success are needed (r) and
  // each success has a 1/6th chance (p), so the mean of the negative binomial
  // distribution = r / p = 7 * 6 = 42.
  // https://stattrek.com/probability-distributions/negative-binomial.aspx
  printStats("Turns", gameStats.map((stats) => stats.turnCount));
  printStats("Turns for losses",
      gameStats.where(wasLoss).map((stats) => stats.turnCount));
  printStats("Turns for wins",
      gameStats.where(wasWin).map((stats) => stats.turnCount));
  printStats("Blocks", gameStats.map((stats) => stats.blockCount));
  printStats("Blocks for losses",
      gameStats.where(wasLoss).map((stats) => stats.blockCount));

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
  printStats(
      "Potion spaces lost", gameStats.map((stats) => stats.wastedMoveDistance));
  printStats("Wizard spaces moved",
      gameStats.map((stats) => stats.wizardMoveDistance));

  String toPercent(int value) {
    double percent = value / gameStats.length * 100;
    return percent.toStringAsFixed(1) + "%";
  }

  int actualWins =
      gameStats.fold(0, (int sum, stats) => sum + (stats.playerWon ? 1 : 0));
  print("${toPercent(actualWins)} actual wins, N=${gameStats.length}");

  int possibleWins =
      gameStats.fold(0, (int sum, stats) => sum + (stats.couldHaveWon ? 1 : 0));
  print("${toPercent(possibleWins)} max wins, N=${gameStats.length}");
}

List<GameStats> simulateGames(int gameCount) {
  List<GameStats> gameStats = <GameStats>[];
  for (int i = 0; i < gameCount; i++) {
    CauldronQuest game = CauldronQuest();
    while (!game.isComplete) {
      game.takeTurn();
    }
    gameStats.add(game.stats);
  }
  return gameStats;
}

void main() {
  const int numberOfGames = 10000;
  print("\nSimulating $numberOfGames games...");
  var start = DateTime.now();
  var gameStats = simulateGames(numberOfGames);
  var duration = DateTime.now().difference(start);
  print('Completed: $duration');
  printAggregateStatistics(gameStats);
}
