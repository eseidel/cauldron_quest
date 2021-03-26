import 'package:test/test.dart';
import 'package:cauldron_quest/rules.dart';

void main() {
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
