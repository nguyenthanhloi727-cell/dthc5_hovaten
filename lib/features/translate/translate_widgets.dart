import 'package:flutter/material.dart';

import 'translation_controller.dart';

/// Chọn ngôn ngữ nguồn ⇄ đích.
class LanguageBar extends StatelessWidget {
  final TranslationController controller;

  const LanguageBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        // Chừa chỗ cho nhãn nổi "Từ"/"Sang" không bị TabBar đè lên.
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: _picker('Từ', controller.source, controller.setSource),
            ),
            IconButton(
              tooltip: 'Đổi chiều',
              icon: const Icon(Icons.swap_horiz),
              onPressed: controller.swap,
            ),
            Expanded(
              child: _picker('Sang', controller.target, controller.setTarget),
            ),
          ],
        ),
      ),
    );
  }

  Widget _picker(
    String label,
    AppLanguage value,
    ValueChanged<AppLanguage> onChanged,
  ) {
    return DropdownButtonFormField<AppLanguage>(
      key: ValueKey('$label-${value.code}'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final l in AppLanguage.all)
          DropdownMenuItem(
            value: l,
            child: Text(l.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (l) {
        if (l != null) onChanged(l);
      },
    );
  }
}

/// Dòng trạng thái model: đang kiểm tra / đang tải (có tiến trình) / sẵn sàng / lỗi.
class ModelStatusBar extends StatelessWidget {
  final TranslationController controller;

  const ModelStatusBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final (icon, color) = switch (c.status) {
          ModelStatus.ready => (Icons.offline_pin, Colors.green),
          ModelStatus.error => (Icons.error_outline, scheme.error),
          ModelStatus.unknown => (Icons.help_outline, scheme.outline),
          _ => (Icons.downloading, scheme.primary),
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.statusText,
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ),
                  if (c.status == ModelStatus.error ||
                      c.status == ModelStatus.unknown)
                    TextButton(
                      onPressed: c.ensureModels,
                      child: const Text('Tải model'),
                    ),
                ],
              ),
              if (c.isBusy)
                LinearProgressIndicator(
                  // Tải model không báo byte nên hiện theo số model đã xong;
                  // chưa xong model nào thì chạy dạng không xác định.
                  value: c.stepTotal == 0 || c.stepDone == 0
                      ? null
                      : c.stepDone / c.stepTotal,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Khung hiện kết quả dịch dùng chung cho các tab.
class TranslationResultCard extends StatelessWidget {
  final String? result;
  final String? error;
  final bool loading;

  const TranslationResultCard({
    super.key,
    this.result,
    this.error,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;
    if (loading) {
      child = const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Đang dịch...'),
        ],
      );
    } else if (error != null) {
      child = Text(error!, style: TextStyle(color: theme.colorScheme.error));
    } else if (result == null || result!.isEmpty) {
      child = Text(
        'Bản dịch sẽ hiện ở đây',
        style: TextStyle(color: theme.hintColor),
      );
    } else {
      child = SelectableText(result!, style: theme.textTheme.titleMedium);
    }
    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// Mixin gom logic "dịch + loading + lỗi" cho các tab.
mixin TranslateRunner<T extends StatefulWidget> on State<T> {
  TranslationController get controller;

  String? result;
  String? error;
  bool translating = false;

  /// Ngôn ngữ phát hiện được khi khác với ngôn ngữ nguồn đang chọn.
  AppLanguage? mismatch;
  String _lastText = '';

  /// Nếu [autoSwitch] thì tự đổi ngôn ngữ nguồn khi phát hiện sai.
  Future<void> runTranslate(String text, {bool autoSwitch = false}) async {
    if (text.trim().isEmpty) {
      setState(() {
        result = null;
        error = 'Chưa có nội dung để dịch.';
      });
      return;
    }
    _lastText = text;
    setState(() {
      translating = true;
      error = null;
      mismatch = null;
    });
    final detected = await controller.detectLanguage(text);
    if (detected != null && detected != controller.source) {
      if (autoSwitch) {
        if (detected == controller.target) controller.swap();
        controller.setSource(detected);
        if (mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                'Phát hiện ${detected.name} → đã đổi ngôn ngữ nguồn.',
              ),
            ),
          );
        }
      } else if (mounted) {
        setState(() => mismatch = detected);
      }
    }
    try {
      final r = await controller.translate(text);
      if (mounted) setState(() => result = r);
    } on StateError catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = 'Dịch thất bại: $e');
    } finally {
      if (mounted) setState(() => translating = false);
    }
  }

  /// Gợi ý đổi ngôn ngữ nguồn khi văn bản không khớp (hiện ngay trên kết quả).
  Widget buildMismatchHint() {
    final lang = mismatch;
    if (lang == null) return const SizedBox.shrink();
    return Card(
      color: Colors.amber.shade100,
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: Colors.orange),
        title: Text(
          'Văn bản có vẻ là ${lang.name}, '
          'nhưng bạn đang dịch từ ${controller.source.name}.',
        ),
        subtitle: const Text('Chọn sai ngôn ngữ nguồn sẽ làm bản dịch sai.'),
        trailing: TextButton(
          onPressed: () {
            if (lang == controller.target) controller.swap();
            controller.setSource(lang);
            runTranslate(_lastText);
          },
          child: Text('Dịch từ\n${lang.name}', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
