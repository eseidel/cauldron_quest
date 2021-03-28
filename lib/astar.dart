import 'package:a_star/a_star.dart';
import 'rules.dart'; // Should be graph.dart

// We can't mixin to Space, since Node<T> contains graph-dependent
// state.  If we did (which I tried) then that state will get retained
// between searches and cause future searchs to fail.
class AStarNode with Node<AStarNode> {
  final Space space;
  final int version;
  AStarNode(this.space, this.version);

  factory AStarNode.fromSpace(Space space, int version) {
    AStarNode? node = space.aStarNode;
    if (node != null && node.version == version) {
      return node;
    }
    space.aStarNode = node = AStarNode(space, version);
    return node;
  }
}

class _AStarAdaptor extends Graph<AStarNode> {
  static int lastVersion = 0;

  final bool ignoreBlockers;
  final int version;

  _AStarAdaptor(Space root, {this.ignoreBlockers = false})
      : version = lastVersion++ {
    allNodes = collectAllNodes(root);
  }

  AStarNode toNode(Space space) => AStarNode.fromSpace(space, version);

  Space toSpace(AStarNode node) => node.space;

  List<AStarNode> collectAllNodes(Space root) {
    List<Space> toWalk = [root];
    List<Space> seenNodes = [];

    while (toWalk.isNotEmpty) {
      Space current = toWalk.removeLast();
      seenNodes.add(current);
      for (Space neighbor in getNeighborSpacesOf(current)) {
        bool allowNeighbor = ignoreBlockers || !neighbor.isBlocked();
        if (allowNeighbor && !seenNodes.contains(neighbor)) {
          toWalk.add(neighbor);
        }
      }
    }
    return seenNodes.map(toNode).toList();
  }

  @override
  late Iterable<AStarNode> allNodes;

  @override
  num getDistance(AStarNode a, AStarNode b) {
    assert(a.space.adjacentTo(b.space));
    return 1;
  }

  @override
  num getHeuristicDistance(AStarNode a, AStarNode b) {
    // TODO: Could optimize this by naming/numbering nodes.
    return 1;
  }

  Iterable<Space> getNeighborSpacesOf(Space node) {
    return ignoreBlockers
        ? node.adjacentSpaces
        : node.adjacentSpaces.where((space) => !space.isBlocked());
  }

  @override
  Iterable<AStarNode> getNeighboursOf(AStarNode node) =>
      getNeighborSpacesOf(node.space).map(toNode);
}

List<Space>? shortestPath(
    {required Space from, required Space to, bool ignoreBlockers = false}) {
  var adaptor = _AStarAdaptor(from, ignoreBlockers: ignoreBlockers);
  var aStar = AStar(adaptor);
  var path = aStar.findPathSync(adaptor.toNode(from), adaptor.toNode(to));
  if (path == aStar.noValidPath) {
    return null;
  }
  return path.map(adaptor.toSpace).toList();
}
