import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回歸測試：API 金鑰對話框（StatefulWidget 持有 controller）關閉後立即切換子樹，
/// 不應觸發「TextEditingController used after disposed」/ framework _dependents 斷言。
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
          const Text('說明文字'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'AIza...'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool _generating = false;
  bool _done = false;

  Future<void> _go() async {
    final key = await showDialog<String>(
      context: context,
      builder: (_) => const _ApiKeyDialog(),
    );
    if (key == null || key.isEmpty) return;
    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (mounted) setState(() { _generating = false; _done = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _generating
          ? const Center(child: CircularProgressIndicator())
          : _done
              ? const Center(child: Text('done'))
              : Center(
                  child: FilledButton(onPressed: _go, child: const Text('產生心智圖')),
                ),
    );
  }
}

void main() {
  testWidgets('paste key + 儲存 不應觸發 controller/_dependents 斷言', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Harness()));
    await tester.tap(find.text('產生心智圖'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'AIzaSyDUMMYKEY1234567890');
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    expect(find.text('done'), findsOneWidget);
  });
}