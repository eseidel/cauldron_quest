import 'package:cauldron_quest/rules.dart';

void main() {
  int remainingLossCount = 1;
  int startSeed = 0;

  while (remainingLossCount > 0) {
    CauldronQuest game = CauldronQuest(startSeed++);
    while (!game.isComplete) {
      game.takeTurn();
    }
    if (game.wizardWon) {
      remainingLossCount--;
      print(game.board.debugString());
      print(game.stats);
    }
  }
}
