import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nguyen_thanh_loi/config/current_member.dart';
import 'package:nguyen_thanh_loi/config/team_members.dart';
import 'package:nguyen_thanh_loi/main.dart';

void main() {
  testWidgets('Có đủ các tab và tab Cá nhân đọc từ currentMember', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    for (final label in [
      'Cá nhân',
      'Báo thức',
      'Dịch',
      'Nhóm',
      'Nhiệt độ',
      'Đơn vị',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text(currentMember.hoTen), findsOneWidget);
    expect(find.text(currentMember.mssv), findsOneWidget);
  });

  testWidgets('Tab Nhóm hiện thành viên đầu tiên và giữ state khi chuyển tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byIcon(Icons.groups));
    await tester.pumpAndSettle();
    expect(find.text('1 / ${teamMembers.length}'), findsOneWidget);

    if (teamMembers.length > 1) {
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2 / ${teamMembers.length}'), findsOneWidget);

      // Sang tab khác rồi quay lại: vẫn ở trang 2 (IndexedStack giữ state).
      await tester.tap(find.byIcon(Icons.thermostat));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.groups));
      await tester.pumpAndSettle();
      expect(find.text('2 / ${teamMembers.length}'), findsOneWidget);
    }
  });
}
