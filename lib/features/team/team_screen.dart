import 'package:flutter/material.dart';

import '../../config/member.dart';
import '../../config/team_members.dart';
import '../common/member_avatar.dart';

/// Tab Nhóm: PageView lướt ngang, mỗi trang 1 thành viên + chấm chỉ trang.
/// Đọc `teamMembers` (toàn bộ members.json), không phụ thuộc currentMember.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _controller = PageController(viewportFraction: 0.88);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Thông tin nhóm (${teamMembers.length})')),
      body: teamMembers.isEmpty
          ? const Center(child: Text('Chưa có thành viên trong members.json'))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: teamMembers.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _MemberPage(member: teamMembers[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < teamMembers.length; i++)
                        GestureDetector(
                          onTap: () => _controller.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text('${_page + 1} / ${teamMembers.length}'),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

class _MemberPage extends StatelessWidget {
  final Member member;

  const _MemberPage({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Card(
        elevation: 3,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              MemberAvatar(member: member, radius: 72),
              const SizedBox(height: 16),
              Text(
                member.hoTen,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Chip(label: Text(member.vaiTro)),
              const Divider(height: 32),
              _row(Icons.badge, 'MSSV', member.mssv),
              _row(Icons.class_, 'Lớp', member.lop),
              _row(Icons.work_outline, 'Vai trò', member.vaiTro),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
    dense: true,
    leading: Icon(icon),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
