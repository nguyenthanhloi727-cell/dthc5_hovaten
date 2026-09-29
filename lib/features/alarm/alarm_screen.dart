import 'package:flutter/material.dart';

import '../common/speech_service.dart';
import '../common/ui_helpers.dart';
import 'alarm_service.dart';
import 'parsers/time_parser.dart';

/// Tab Báo thức: nói giờ (nhiều ngôn ngữ) -> hiện giờ đã hiểu -> xác nhận ->
/// đặt báo thức trong app Đồng hồ.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final _speech = SpeechService.instance;
  final _textCtrl = TextEditingController();
  final _labelCtrl = TextEditingController(text: 'Báo thức');

  TimeParser _parser = TimeParser.all.first;
  bool _listening = false;
  ParsedTime? _parsed;
  String? _hint;

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    _textCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _parse(String text) {
    final t = _parser.parse(text);
    setState(() {
      _parsed = t;
      _hint = text.trim().isEmpty || t != null
          ? null
          : 'Chưa hiểu giờ trong câu "$text". Thử: ${_parser.examples.first}';
    });
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _parsed = null;
      _hint = null;
    });
    try {
      final supported = await _speech.supportsLocale(_parser.localeId);
      if (supported == false && mounted) {
        showInfo(
          context,
          'Máy chưa có gói nhận dạng ${_parser.displayName}, kết quả có thể sai.',
        );
      }
      await _speech.listen(
        localeId: _parser.localeId,
        onResult: (text, isFinal) {
          if (!mounted) return;
          _textCtrl.text = text;
          _parse(text);
        },
        onError: (msg) {
          if (mounted) showError(context, msg);
        },
        onDone: () {
          if (mounted) setState(() => _listening = false);
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

  Future<void> _confirm() async {
    final t = _parsed;
    if (t == null) return;
    try {
      await AlarmService.setAlarm(
        hour: t.hour,
        minute: t.minute,
        message: _labelCtrl.text.trim().isEmpty
            ? 'Báo thức'
            : _labelCtrl.text.trim(),
      );
      if (mounted) showInfo(context, 'Đã gửi báo thức $t sang app Đồng hồ.');
    } on UnsupportedError catch (e) {
      if (mounted) showError(context, e.message ?? 'Không đặt được báo thức.');
    } catch (e) {
      if (mounted) showError(context, 'Không đặt được báo thức: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Báo thức bằng giọng nói')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<TimeParser>(
            initialValue: _parser,
            decoration: const InputDecoration(
              labelText: 'Ngôn ngữ nói',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final p in TimeParser.all)
                DropdownMenuItem(
                  value: p,
                  child: Text('${p.displayName} (${p.localeId})'),
                ),
            ],
            onChanged: _listening
                ? null
                : (p) {
                    if (p == null) return;
                    setState(() => _parser = p);
                    _parse(_textCtrl.text);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            'Ví dụ: ${_parser.examples.join(' · ')}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Center(
            child: FloatingActionButton.large(
              heroTag: 'alarm_mic',
              onPressed: _toggleListen,
              backgroundColor: _listening ? Colors.red : null,
              child: Icon(_listening ? Icons.stop : Icons.mic),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(_listening ? 'Đang nghe...' : 'Nhấn micro rồi nói giờ'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textCtrl,
            decoration: const InputDecoration(
              labelText: 'Câu đã nhận dạng (có thể gõ tay)',
              border: OutlineInputBorder(),
            ),
            onChanged: _parse,
          ),
          if (_hint != null) ...[
            const SizedBox(height: 8),
            Text(_hint!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Giờ đã hiểu'),
                  Text(
                    _parsed?.toString() ?? '--:--',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nhãn báo thức',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _parsed == null ? null : _confirm,
                    icon: const Icon(Icons.alarm_add),
                    label: Text(
                      _parsed == null
                          ? 'Chưa có giờ'
                          : 'Xác nhận đặt báo thức $_parsed',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
