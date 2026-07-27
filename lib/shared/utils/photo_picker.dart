import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_spacing.dart';

/// Single entry point for taking or choosing a photo.
///
/// Replaces four near-identical copies that all shared the same crash: the
/// manifest declares `android.permission.CAMERA`, and Android requires a
/// declared CAMERA permission to be *granted* before it will honour
/// ACTION_IMAGE_CAPTURE. Nothing ever requested it at runtime, so tapping
/// "Take photo" threw SecurityException and killed the app — the user landed
/// on their home screen with the form gone.
class PhotoPicker {
  PhotoPicker._();

  /// Shows the source sheet, handles permissions, and returns the photo.
  ///
  /// Returns null when the user cancels or the pick fails. Never throws — a
  /// failed pick reports itself in a snackbar and leaves the caller's state
  /// untouched.
  static Future<XFile?> pick(
    BuildContext context, {
    double maxWidth = 1600,
    int imageQuality = 85,
  }) async {
    final source = await _chooseSource(context);
    if (source == null || !context.mounted) return null;

    if (source == ImageSource.camera && !await _ensureCameraPermission(context)) {
      return null;
    }

    try {
      return await ImagePicker().pickImage(
        source: source,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
      );
    } on PlatformException catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          switch (e.code) {
            'camera_access_denied' =>
              'Camera access is blocked. Enable it in Settings → Apps → Shine Gold → Permissions.',
            'photo_access_denied' =>
              'Photo access is blocked. Enable it in Settings → Apps → Shine Gold → Permissions.',
            _ => 'Could not open the camera (${e.code}). Try again.',
          },
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Could not add the photo: $e');
      }
      return null;
    }
  }

  /// Recovers a photo Android threw away when it killed the app.
  ///
  /// The camera is memory-hungry, so on low-RAM phones Android often kills the
  /// host app while it is open. Without this the capture is lost silently and
  /// looks like the app "closed for no reason". Android-only; a no-op
  /// elsewhere.
  static Future<XFile?> recoverLostPhoto() async {
    if (kIsWeb) return null;
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty || response.file == null) return null;
      return response.file;
    } catch (_) {
      return null;
    }
  }

  static Future<ImageSource?> _chooseSource(BuildContext context) async {
    if (kIsWeb) return ImageSource.gallery;

    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
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
  }

  static Future<bool> _ensureCameraPermission(BuildContext context) async {
    if (kIsWeb) return true;

    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) return true;
    }

    if (!context.mounted) return false;

    if (status.isPermanentlyDenied) {
      _showMessage(
        context,
        'Camera permission is blocked for Shine Gold.',
        action: const SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
      );
    } else {
      _showMessage(
        context,
        'Camera permission is needed to take a photo. '
        'You can still choose one from the gallery.',
      );
    }
    return false;
  }

  static void _showMessage(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: action,
      ),
    );
  }
}
