import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../config/current_member.dart';
import '../common/member_avatar.dart';
import '../common/ui_helpers.dart';

/// Tab Cá nhân: toàn bộ thông tin lấy từ `currentMember` (file generated).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: currentMember.sdt.replaceAll(' ', ''));
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showError(context, 'Máy không có ứng dụng gọi điện.');
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Không mở được trình gọi điện: $e');
      }
    }
  }

  Future<void> _email(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: currentMember.email);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showError(context, 'Máy không có ứng dụng email.');
      }
    } catch (e) {
      if (context.mounted) showError(context, 'Không mở được email: $e');
    }
  }

  /// Ưu tiên app YouTube; không có app thì mở bằng trình duyệt.
  Future<void> _openYoutube(BuildContext context) async {
    final web = Uri.parse(AppConfig.youtubeUrl);
    try {
      final openedApp = await launchUrl(
        web,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (openedApp) return;
    } catch (_) {
      // Không có app YouTube -> rơi xuống mở trình duyệt.
    }
    try {
      final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) showError(context, 'Không mở được YouTube.');
    } catch (e) {
      if (context.mounted) showError(context, 'Không mở được YouTube: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = currentMember;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: MemberAvatar(member: m, radius: 64)),
          const SizedBox(height: 12),
          Text(
            m.hoTen,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            m.vaiTro,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('MSSV'),
                  subtitle: Text(m.mssv),
                ),
                ListTile(
                  leading: const Icon(Icons.class_),
                  title: const Text('Lớp'),
                  subtitle: Text(m.lop),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Số điện thoại'),
                  subtitle: Text(m.sdt),
                  onTap: () => _call(context),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(m.email),
                  onTap: () => _email(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _call(context),
            icon: const Icon(Icons.call),
            label: Text('Gọi điện ${m.sdt}'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => _openYoutube(context),
            icon: const Icon(Icons.smart_display),
            label: const Text('Mở YouTube'),
          ),
        ],
      ),
    );
  }
}
