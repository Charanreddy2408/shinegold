import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/repository_providers.dart';

/// Tappable avatar with camera overlay — uploads and saves profile photo.
class ProfilePhotoEditor extends ConsumerStatefulWidget {
  const ProfilePhotoEditor({
    super.key,
    required this.photoUrl,
    required this.fallbackSeed,
    this.radius = 32,
    this.showLabel = true,
  });

  final String photoUrl;
  final String fallbackSeed;
  final double radius;
  final bool showLabel;

  @override
  ConsumerState<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends ConsumerState<ProfilePhotoEditor> {
  bool _uploading = false;
  String? _localPreview;

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() {
      _uploading = true;
      _localPreview = image.path;
    });

    try {
      final url = await ref.read(uploadServiceProvider).uploadFile(
            localPath: image.path,
            context: 'profile_photo',
          );
      await ref.read(authRepositoryProvider).updateProfile(
            profilePhotoUrl: url,
          );
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formatApiError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _localPreview = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = widget.photoUrl.isNotEmpty
        ? widget.photoUrl
        : 'https://i.pravatar.cc/150?u=${widget.fallbackSeed}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _uploading ? null : _pickPhoto,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: widget.radius,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: _localPreview != null
                      ? FileImage(File(_localPreview!)) as ImageProvider
                      : CachedNetworkImageProvider(displayUrl),
                  child: _uploading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _uploading ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: widget.radius * 0.38,
                ),
              ),
            ],
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 8),
          Text(
            'Tap to update photo',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}
