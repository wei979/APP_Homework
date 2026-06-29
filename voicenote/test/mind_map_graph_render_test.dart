import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';

import 'package:voicenote/models/mind_node.dart';

/// 重現 MindMapScreen._GraphView 的 graphview + InteractiveViewer 渲染，
/// 用以定位「產生後全白」。若 graphview 在受限視窗下拋例外或產生 0 尺寸，這裡會抓到。
class _GraphView extends StatefulWidget {
  final MindNode tree;
  const _GraphView(this.tree);
  @override
  State<_GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<_GraphView> {
  final Graph _graph = Graph()..isTree = true;
  final Map<int, String> _titles = {};
  late final BuchheimWalkerConfiguration _builder;
  int _next = 0;

  @override
  void initState() {
    super.initState();
    _builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 18
      ..levelSeparation = 48
      ..subtreeSeparation = 18
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
    _build(widget.tree, null);
  }

  void _build(MindNode node, Node? parent) {
    final id = _next++;
    _titles[id] = node.title;
    final g = Node.Id(id);
    if (parent == null) {
      _graph.addNode(g);
    } else {
      _graph.addEdge(parent, g);
    }
    for (final c in node.children) {
      _build(c, g);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.2,
      maxScale: 2.5,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: GraphView(
          graph: _graph,
          algorithm:
              BuchheimWalkerAlgorithm(_builder, TreeEdgeRenderer(_builder)),
          paint: Paint()
            ..color = const Color(0xFFC0C9C2)
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            final id = node.key!.value as int;
            return Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFB6F0D8),
              child: Text(_titles[id]!),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  testWidgets('graphview 樹渲染不應拋例外、且節點可見', (tester) async {
    const tree = MindNode(title: '資料結構', children: [
      MindNode(title: '陣列', startMs: 1000, children: [
        MindNode(title: '存取 O(1)', startMs: 1200),
        MindNode(title: '插入 O(n)', startMs: 1500),
      ]),
      MindNode(title: '鏈結串列', startMs: 5000, children: [
        MindNode(title: '單向'),
        MindNode(title: '雙向'),
      ]),
    ]);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _GraphView(tree))),
    );
    await tester.pumpAndSettle();

    expect(find.text('資料結構'), findsOneWidget);
    expect(find.text('單向'), findsOneWidget);
  });
}