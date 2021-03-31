class GameStats {
  int turnCount = 0;
  int blockCount = 0;
  int magicCount = 0;
  int magicFailures = 0;
  int potionMoveCount = 0;
  int wizardMoveCount = 0;
  int potionMoveDistance = 0;
  int wastedMoveDistance = 0;
  int wizardMoveDistance = 0;
  int potionsRevealed = 0;
  int potionsSwapped = 0;
  int supercharmCount = 0;
  bool playerWon = false;

  String toString() {
    return '''win: $playerWon in turns: $turnCount
    blocks: $blockCount
    magic: $magicCount (reveals: $potionsRevealed, swaps: $potionsSwapped, supers: $supercharmCount, fails: $magicFailures)
    potion moves: $potionMoveCount
    wizard moves: $wizardMoveCount
    potion move distance: $potionMoveDistance (wasted: $wastedMoveDistance)
    ''';
  }

  bool get couldHaveWon => potionsRevealed >= 3 && potionMoveDistance >= 30;
}
