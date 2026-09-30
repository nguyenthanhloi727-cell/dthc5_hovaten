import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../config/current_member.dart';
import '../common/member_avatar.dart';
import '../common/ui_helpers.dart';
import 'avatar_store.dart';

/// Tab Cá nhân: thông tin lấy từ `currentMember` (file generated).
/// Ảnh đại diện do người dùng tự chọn (chụp / thư viện), lưu trong máy.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  File? _avatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AvatarStore.load().then((f) {
      if (mounted && f != null) setState(() => _avatar = f);
    });
  }

  // ------------------------------------------------------------- ảnh đại diện

  Future<void> _chooseAvatar() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_avatar != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xoá ảnh, dùng ảnh mặc định'),
                onTap: () => Navigator.pop(ctx, 'clear'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'clear') {
      await AvatarStore.clear();
      if (mounted) setState(() => _avatar = null);
      return;
    }
    final source = action == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('access_denied');
      showError(
        context,
        denied
            ? 'Chưa có quyền ${source == ImageSource.camera ? 'camera' : 'đọc ảnh'}. '
                  'Hãy cấp quyền trong Cài đặt.'
            : 'Không mở được ${source == ImageSource.camera ? 'camera' : 'thư viện ảnh'}: ${e.message}',
        openSettings: denied,
      );
      return;
    }
    if (picked == null) return; // người dùng huỷ
    setState(() => _saving = true);
    try {
      final saved = await AvatarStore.save(picked);
      if (mounted) {
        setState(() => _avatar = saved);
        showInfo(context, 'Đã cập nhật ảnh đại diện.');
      }
    } catch (e) {
      if (mounted) showError(context, 'Không lưu được ảnh: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------- liên hệ

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: currentMember.sdt.replaceAll(' ', ''));
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showError(context, 'Máy không có ứng dụng gọi điện.');
      }
    } catch (e) {
      if (mounted) showError(context, 'Không mở được trình gọi điện: $e');
    }
  }

  Future<void> _email() async {
    final uri = Uri(scheme: 'mailto', path: currentMember.email);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) showError(context, 'Máy không có ứng dụng email.');
    } catch (e) {
      if (mounted) showError(context, 'Không mở được email: $e');
    }
  }

  /// Ưu tiên app YouTube; không có app thì mở bằng trình duyệt.
  Future<void> _openYoutube() async {
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
      if (!ok && mounted) showError(context, 'Không mở được YouTube.');
    } catch (e) {
      if (mounted) showError(context, 'Không mở được YouTube: $e');
    }
  }

  // ------------------------------------------------------------- UI

  Widget _buildAvatar() {
    const radius = 64.0;
    final scheme = Theme.of(context).colorScheme;
    final image = _avatar == null
        ? MemberAvatar(member: currentMember, radius: radius)
        : ClipOval(
            child: Image.file(
              _avatar!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  MemberAvatar(member: currentMember, radius: radius),
            ),
          );
    return Center(
      child: Tooltip(
        message: 'Đổi ảnh đại diện',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _saving ? null : _chooseAvatar,
          child: Stack(
            children: [
              image,
              if (_saving)
                const Positioned.fill(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primary,
                  child: Icon(
                    Icons.photo_camera,
                    size: 20,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          _buildAvatar(),
          const SizedBox(height: 4),
          Text(
            'Chạm vào ảnh để đổi',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          Text(
            m.hoTen,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                  onTap: _call,
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(m.email),
                  onTap: _email,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _call,
            icon: const Icon(Icons.call),
            label: Text('Gọi điện ${m.sdt}'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _openYoutube,
            icon: const Icon(Icons.smart_display),
            label: const Text('Mở YouTube'),
          ),
        ],
      ),
    );
  }
}
