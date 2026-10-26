import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';

/// "Thêm" tab — a hub of secondary destinations. Rendered inside the
/// [MainScreen] IndexedStack, seamlessly delegating to the unified
/// Liquid Glass [ProfileScreen] hub.
class MoreScreen extends StatelessWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String? userPhotoUrl;
  final VoidCallback onSignOut;

  const MoreScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhotoUrl,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      isRoot: true,
      onSignOut: onSignOut,
    );
  }
}
