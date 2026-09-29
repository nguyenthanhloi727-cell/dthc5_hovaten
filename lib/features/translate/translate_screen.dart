import 'package:flutter/material.dart';

import 'image_translate_tab.dart';
import 'realtime_translate_screen.dart';
import 'text_translate_tab.dart';
import 'translate_widgets.dart';
import 'translation_controller.dart';
import 'voice_translate_tab.dart';

/// Tab Dịch: chọn ngôn ngữ nguồn/đích, trạng thái model offline và 3 cách
/// nhập (văn bản / giọng nói / ảnh). Nút camera trên AppBar mở dịch realtime.
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _ctrl = TranslationController();

  @override
  void initState() {
    super.initState();
    // Lần đầu mở tab: tự kiểm tra và tải model offline.
    _ctrl.ensureModels();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dịch'),
          actions: [
            IconButton(
              tooltip: 'Dịch realtime bằng camera',
              icon: const Icon(Icons.camera),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RealtimeTranslateScreen(controller: _ctrl),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.keyboard), text: 'Văn bản'),
              Tab(icon: Icon(Icons.mic), text: 'Giọng nói'),
              Tab(icon: Icon(Icons.image), text: 'Ảnh'),
            ],
          ),
        ),
        body: Column(
          children: [
            LanguageBar(controller: _ctrl),
            ModelStatusBar(controller: _ctrl),
            Expanded(
              child: TabBarView(
                children: [
                  TextTranslateTab(controller: _ctrl),
                  VoiceTranslateTab(controller: _ctrl),
                  ImageTranslateTab(controller: _ctrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
