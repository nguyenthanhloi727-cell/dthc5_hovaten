import 'package:flutter/material.dart';

import '../../config/member.dart';

/// Ảnh thành viên từ assets/members/, thiếu ảnh thì hiện chữ cái đầu.
class MemberAvatar extends StatelessWidget {
  final Member member;
  final double radius;

  const MemberAvatar({super.key, required this.member, this.radius = 60});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
    final path = member.anh;
    if (path == null) return fallback;
    return ClipOval(
      child: Image.asset(
        path,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
