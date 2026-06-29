import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../../models/mind_node.dart';
import '../../models/note.dart';
import '../../services/llm/api_key_store.dart';
import '../../services/llm/gemini_client.dart';
import '../../services/llm/mind_map_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/duration_format.dart';

/// 重點樹狀圖（心智圖）：雲端 LLM 語意大綱 + 圖形節點連線。
///
/// ⚠️ 此功能需連網、會將逐字稿上傳至 LLM，與「完全離線」的辨識分開。
/// 點選帶時間點的節點會回傳該毫秒給詳情頁跳轉播放。
class MindMapScreen extends StatefulWidget {
  final Note note;
  const MindMapScreen({super.key, required this.note});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  final _service = const MindMapService();
  final _keyStore = ApiKeyStore();

  MindNode? _tree;
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final id = widget.note.id;
    final cached = id == null ? null : await _service.loadCached(id);
    if (!mounted) return;
    setState(() {
      _tree = cached;
      _loading = false;
    });
  }

  Future<void> _generate() async {
    var apiKey = await _keyStore.read();
    if (apiKey == null) {
      apiKey = await _promptForKey();
      if (apiKey == null) return; // 使用者取消
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final tree = await _service.generate(widget.note, apiKey: apiKey);
      if (!mounted) return;
      setState(() {
        _tree = tree;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e is LlmException ? e.message : '產生失敗：$e';
      });
    }
  }

  /// 由使用者自行輸入 Gemini API 金鑰（App 不內建金鑰）。存於 App 私有目錄。
  Future<String?> _promptForKey() async {
    final key = await showDialog<String>(
      context: context,
      builder: (_) => const _ApiKeyDialog(),
    );
    if (key != null && key.isNotEmpty) {
      await _keyStore.save(key);
      return key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('重點心智圖',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        actions: [
          if (_tree != null && !_generating)
            IconButton(
              tooltip: '重新產生',
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_generating) {
      return const _Centered(
        icon: Icons.auto_awesome,
        title: '正在進行語意分析…',
        subtitle: '雲端 LLM 整理中，請稍候',
        showSpinner: true,
      );
    }
    if (_tree == null) {
      return _IntroView(error: _error, onGenerate: _generate);
    }
    return _GraphView(
      tree: _tree!,
      onNodeTap: (startMs) {
        if (startMs != null) Navigator.of(context).pop(startMs);
      },
    );
  }
}

/// 尚未產生時的引導畫面 + 離線提醒。
class _IntroView extends StatelessWidget {
  final String? error;
  final VoidCallback onGenerate;
  const _IntroView({required this.error, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('將筆記整理成重點樹狀圖',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              '對逐字稿做語意邏輯分析，產生主題→子主題→重點的心智圖。',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 18, color: AppColors.tertiary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '此功能需連網、會將逐字稿上傳至雲端 LLM；'
                      '語音辨識本身仍完全離線。',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              Text(error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('產生心智圖'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showSpinner;
  const _Centered({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            const CircularProgressIndicator()
          else
            Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// graphview 樹狀佈局 + InteractiveViewer 縮放/平移。
class _GraphView extends StatefulWidget {
  final MindNode tree;
  final void Function(int? startMs) onNodeTap;
  const _GraphView({required this.tree, required this.onNodeTap});

  @override
  State<_GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<_GraphView> {
  final Graph _graph = Graph()..isTree = true;
  final Map<int, _NodeMeta> _meta = {};
  late final BuchheimWalkerConfiguration _builder;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 18
      ..levelSeparation = 48
      ..subtreeSeparation = 18
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;
    _build(widget.tree, null, 0);
  }

  void _build(MindNode node, Node? parent, int level) {
    final id = _nextId++;
    _meta[id] = _NodeMeta(node.title, node.startMs, level);
    final gNode = Node.Id(id);
    if (parent == null) {
      _graph.addNode(gNode);
    } else {
      _graph.addEdge(parent, gNode);
    }
    for (final child in node.children) {
      _build(child, gNode, level + 1);
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
            ..color = AppColors.outlineVariant
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            final id = node.key!.value as int;
            return _NodeChip(meta: _meta[id]!, onTap: widget.onNodeTap);
          },
        ),
      ),
    );
  }
}

class _NodeMeta {
  final String title;
  final int? startMs;
  final int level;
  const _NodeMeta(this.title, this.startMs, this.level);
}

class _NodeChip extends StatelessWidget {
  final _NodeMeta meta;
  final void Function(int? startMs) onTap;
  const _NodeChip({required this.meta, required this.onTap});

  static const List<(Color, Color)> _palette = [
    (AppColors.primary, AppColors.onPrimary),
    (AppColors.primaryContainer, AppColors.onPrimaryContainer),
    (AppColors.secondaryContainer, AppColors.onSecondaryContainer),
    (AppColors.tertiaryContainer, AppColors.onSurface),
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette[meta.level.clamp(0, _palette.length - 1)];
    final isRoot = meta.level == 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(meta.startMs),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 168, minWidth: 56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant, width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: TextStyle(
                    fontSize: isRoot ? 14 : 12.5,
                    height: 1.25,
                    fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (meta.startMs != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow,
                          size: 12, color: fg.withValues(alpha: 0.7)),
                      const SizedBox(width: 2),
                      Text(
                        DurationFormat.hms(meta.startMs!),
                        style: TextStyle(
                            fontSize: 10.5,
                            color: fg.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// API 金鑰輸入對話框：自有 StatefulWidget 持有並在 dispose() 釋放 controller，
/// 避免對話框關閉動畫期間 controller 被提前 dispose（A TextEditingController was
/// used after being disposed → 連鎖觸發 framework 的 _dependents 斷言）。
class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog();
  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('輸入 Gemini API 金鑰（免費）'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '心智圖由雲端 LLM 產生，需要你自己的 Gemini API 金鑰。\n'
            '到 Google AI Studio (aistudio.google.com/apikey) 免費申請；\n'
            '金鑰只存在此裝置，不會內建於 App。',
            style: TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'AIza...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('儲存'),
        ),
      ],
    );
  }
}