import 'package:cauldron_quest/rules.dart';

void printPath(Iterable<Space> path) {
  for (Space space in path) {
    print("${space.unblockedDistanceToGoal} ${space.distanceToGoal}");
  }
}

void main() {
  Board board = Board();
  board.blockPath(0);
  board.updateDistances();
  print(board.startSpaces.first.distanceToGoal);
  print(board.startSpaces.first.unblockedDistanceToGoal);
  for (Space start in board.startSpaces) {
    var path = board.shortestPathToGoal(start, ignoreBlocks: true);
    printPath(path);
  }

  // var start = Space();
  // var blocked = Space();
  // var end = Space();
  // var side1 = Space();
  // var side2 = Space();
  // var allSpaces = [start, blocked, end, side1, side2];

  // start.connectTo(blocked);
  // blocked.connectTo(end);
  // start.connectTo(side1);
  // side1.connectTo(side2);
  // side2.connectTo(end);

  // Board.updateDistancesFromGoal(end, 1);
  // blocked.addBlocker();
  // Board.updateDistancesFromGoal(end, 2);

  // printPath(allSpaces);
}
