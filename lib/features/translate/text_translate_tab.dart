import 'package:flutter/material.dart';

import 'translate_widgets.dart';
import 'translation_controller.dart';

/// 4a. Nhập văn bản -> dịch.
class TextTranslateTab extends StatefulWidget {
  final TranslationController controller;

  const TextTranslateTab({super.key, required this.controller});

  @override
  State<TextTranslateTab> createState() => _TextTranslateTabState();
}

class _TextTranslateTabState extends State<TextTranslateTab>
    with AutomaticKeepAliveClientMixin, TranslateRunner {
  final _input = TextEditingController();

  @override
  TranslationController get controller => widget.controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        TextField(
          controller: _input,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: 'Nhập văn bản',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _input.clear();
                result = null;
                error = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: translating ? null : () => runTranslate(_input.text),
          icon: const Icon(Icons.translate),
          label: const Text('Dịch'),
        ),
        const SizedBox(height: 12),
        TranslationResultCard(
          result: result,
          error: error,
          loading: translating,
        ),
      ],
    );
  }
}
