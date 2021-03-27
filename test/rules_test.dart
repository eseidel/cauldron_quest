import 'package:test/test.dart';
import 'package:cauldron_quest/rules.dart';

void main() {
  test('board setup', () {
    Board board = Board();
    expect(board.wizardPath.length, 12);
    expect(board.startSpaces.length, 6);
    expect(board.cauldron.adjacentSpaces.length, 6);
    expect(board.startSpaces.first.adjacentSpaces.length, 1);
    expect(
        board.startSpaces
            .every((space) => space.tokens.any((token) => token is Bottle)),
        true);

    // Wizard path is a loop.
    expect(board.wizardPath.last.wizardForward, board.wizardPath.first);
  });

  test('distance calculations', () {
    Board board = Board();
    board.updateDistances();
    expect(board.startSpaces.first.unblockedDistanceToGoal, 10);
    expect(board.startSpaces.first.distanceToGoal, 10);
    board.blockPath(0);
    board.updateDistances();
    expect(board.startSpaces.first.unblockedDistanceToGoal, 10);
    expect(board.startSpaces.first.distanceToGoal, 12);
  });

  test('simple board distance calculations', () {
    var start = Space();
    var blocked = Space();
    var end = Space();
    var side1 = Space();
    var side2 = Space();

    start.connectTo(blocked);
    blocked.connectTo(end);
    start.connectTo(side1);
    side1.connectTo(side2);
    side2.connectTo(end);

    Board.updateDistancesFromGoal(end, 1);

    expect(start.distanceToGoal, 2);
    expect(start.unblockedDistanceToGoal, 2);
    blocked.addBlocker();
    Board.updateDistancesFromGoal(end, 2);
    expect(start.unblockedDistanceToGoal, 2);
    expect(start.distanceToGoal, 3);
  });

  test('path blocking', () {
    Board board = Board();
    expect(board.unblockedPathCount, 6);
    board.blockRandomPath();
    expect(board.unblockedPathCount, 5);
  });

  test('wizard moving', () {
    Board board = Board();

    int wizardLocation() {
      return board.wizardPath
          .indexWhere((space) => space.tokens.contains(board.wizard));
    }

    expect(wizardLocation(), 0);
    board.moveWizard(3);
    expect(wizardLocation(), 3);
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
