import 'package:flutter/material.dart';

import '../common/speech_service.dart';
import '../common/ui_helpers.dart';
import 'translate_widgets.dart';
import 'translation_controller.dart';

/// 4b. Nói (theo ngôn ngữ nguồn) -> speech_to_text -> dịch.
class VoiceTranslateTab extends StatefulWidget {
  final TranslationController controller;

  const VoiceTranslateTab({super.key, required this.controller});

  @override
  State<VoiceTranslateTab> createState() => _VoiceTranslateTabState();
}

class _VoiceTranslateTabState extends State<VoiceTranslateTab>
    with AutomaticKeepAliveClientMixin, TranslateRunner {
  final _speech = SpeechService.instance;
  final _heard = TextEditingController();
  bool _listening = false;

  @override
  TranslationController get controller => widget.controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    _heard.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    final lang = controller.source;
    setState(() {
      _listening = true;
      error = null;
    });
    var gotFinal = false;
    try {
      final supported = await _speech.supportsLocale(lang.speechLocale);
      if (supported == false && mounted) {
        showInfo(
          context,
          'Máy chưa có gói nhận dạng ${lang.name}, kết quả có thể sai.',
        );
      }
      await _speech.listen(
        localeId: lang.speechLocale,
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() => _heard.text = text);
          if (isFinal && !gotFinal) {
            gotFinal = true;
            runTranslate(text);
          }
        },
        onError: (msg) {
          if (mounted) showError(context, msg);
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _listening = false);
          if (!gotFinal && _heard.text.trim().isNotEmpty) {
            gotFinal = true;
            runTranslate(_heard.text);
          }
        },
      );
    } on SpeechException catch (e) {
      if (!mounted) return;
      setState(() => _listening = false);
      showError(context, e.message, openSettings: e.openSettings);
    } catch (e) {
      if (!mounted) return;
      setState(() => _listening = false);
      showError(context, 'Không bật được nhận dạng giọng nói: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 8),
          Center(
            child: FloatingActionButton.large(
              heroTag: 'translate_mic',
              onPressed: _toggle,
              backgroundColor: _listening ? Colors.red : null,
              child: Icon(_listening ? Icons.stop : Icons.mic),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _listening
                  ? 'Đang nghe ${controller.source.name}...'
                  : 'Nhấn micro và nói bằng ${controller.source.name}',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heard,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Câu đã nghe (có thể sửa)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: translating ? null : () => runTranslate(_heard.text),
            icon: const Icon(Icons.translate),
            label: const Text('Dịch lại'),
          ),
          const SizedBox(height: 8),
          TranslationResultCard(
            result: result,
            error: error,
            loading: translating,
          ),
        ],
      ),
    );
  }
}
