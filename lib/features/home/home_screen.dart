import 'package:flutter/material.dart';

import '../../TemperatureConverterScreen.dart';
import '../../UnitConverterScreen.dart';
import '../alarm/alarm_screen.dart';
import '../profile/profile_screen.dart';
import '../team/team_screen.dart';
import '../translate/translate_screen.dart';

class _TabItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _TabItem(this.label, this.icon, this.builder);
}

/// 1. BottomNavigationBar + IndexedStack: giữ nguyên state khi chuyển tab.
/// Mỗi tab chỉ được build lần đầu khi người dùng mở tới (tránh xin quyền /
/// tải model ngay lúc khởi động), sau đó được giữ lại trong IndexedStack.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final _tabs = <_TabItem>[
    _TabItem('Cá nhân', Icons.person, (_) => const ProfileScreen()),
    _TabItem('Báo thức', Icons.alarm, (_) => const AlarmScreen()),
    _TabItem('Dịch', Icons.translate, (_) => const TranslateScreen()),
    _TabItem('Nhóm', Icons.groups, (_) => const TeamScreen()),
    // Tab cũ của bài trước
    _TabItem('Nhiệt độ', Icons.thermostat, (_) => TemperatureConverterScreen()),
    _TabItem('Đơn vị', Icons.swap_horiz, (_) => const UnitConverterScreen()),
  ];

  int _index = 0;
  final _visited = <int>{0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _visited.contains(i)
                ? _tabs[i].builder(context)
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        onTap: (i) => setState(() {
          _index = i;
          _visited.add(i);
        }),
        items: [
          for (final t in _tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
