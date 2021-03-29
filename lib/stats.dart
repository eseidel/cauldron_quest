class GameStats {
  int turnCount = 0;
  int blockCount = 0;
  int magicCount = 0;
  int magicFailures = 0;
  int potionMoveCount = 0;
  int wizardMoveCount = 0;
  int potionMoveDistance = 0;
  int wizardMoveDistance = 0;
  int potionsRevealed = 0;
  int potionsSwapped = 0;
  int supercharmCount = 0;
  bool playerWon = false;

  bool get couldHaveWon => potionsRevealed > 3 && potionMoveDistance > 30;
}
