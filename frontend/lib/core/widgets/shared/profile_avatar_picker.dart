import 'package:first_try/core/utils/app_url.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:first_try/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Circular avatar with tap-to-change behavior. Reads/writes
/// `users.profile_picture` via [AuthCubit], so all 4 roles share one entry
/// point. Falls back to a colored initial when no picture is set.
class ProfileAvatarPicker extends StatefulWidget {
  final String displayName;
  final double radius;

  /// When false, the avatar is read-only (no tap-to-change). Useful in
  /// dense lists or read-only contexts.
  final bool editable;

  const ProfileAvatarPicker({
    super.key,
    required this.displayName,
    this.radius = 44,
    this.editable = true,
  });

  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final pic = state is AuthAuthenticated ? state.user.profilePicture : null;
        final hasPic = pic != null && pic.isNotEmpty;
        // Route through /api/media/... so CORS middleware applies (Flutter Web
        // canvas needs CORS headers; /storage/* is served by the dev server
        // without going through Laravel middleware).
        final url = hasPic ? '$baseUrl/api/media/$pic' : null;

        final avatar = CircleAvatar(
          radius: widget.radius,
          backgroundColor: cs.primaryContainer,
          backgroundImage: url == null ? null : NetworkImage(url),
          child: url != null
              ? null
              : Text(
                  widget.displayName.isEmpty
                      ? '?'
                      : widget.displayName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: widget.radius * 0.8,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
        );

        if (!widget.editable) return avatar;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: _busy ? null : () => _showActions(context, hasPic),
              child: avatar,
            ),
            if (_busy)
              Positioned.fill(
                child: CircleAvatar(
                  radius: widget.radius,
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: Icon(Icons.camera_alt_rounded,
                    size: 14, color: cs.onPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showActions(BuildContext context, bool hasPic) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(ctx, _AvatarAction.gallery),
            ),
            if (hasPic)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade600),
                title: Text('Remove photo',
                    style: TextStyle(color: Colors.red.shade600)),
                onTap: () => Navigator.pop(ctx, _AvatarAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case _AvatarAction.camera:
        await _pickAndUpload(context, ImageSource.camera);
        break;
      case _AvatarAction.gallery:
        await _pickAndUpload(context, ImageSource.gallery);
        break;
      case _AvatarAction.remove:
        await _remove(context);
        break;
    }
  }

  Future<void> _pickAndUpload(BuildContext context, ImageSource source) async {
    final authCubit = context.read<AuthCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final picker = ImagePicker();
    final XFile? file;
    try {
      file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open image picker: $e')),
      );
      return;
    }
    if (file == null) return;

    setState(() => _busy = true);
    final ok = await authCubit.updateProfilePicture(file);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile picture updated.' : 'Upload failed.'),
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final ok = await authCubit.deleteProfilePicture();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile picture removed.' : 'Could not remove.'),
      ),
    );
  }
}

enum _AvatarAction { camera, gallery, remove }
