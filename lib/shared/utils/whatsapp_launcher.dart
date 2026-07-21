import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a WhatsApp chat for [rawPhone], normalizing common Indian formats.
Future<void> openWhatsAppChat(
  BuildContext context, {
  required String rawPhone,
  String? prefillMessage,
}) async {
  final digits = normalizeWhatsAppPhone(rawPhone);
  if (digits == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number for WhatsApp')),
      );
    }
    return;
  }

  final uri = Uri.parse(
    prefillMessage == null || prefillMessage.trim().isEmpty
        ? 'https://wa.me/$digits'
        : 'https://wa.me/$digits?text=${Uri.encodeComponent(prefillMessage)}',
  );

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (launched) return;
  } catch (_) {}

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (launched) return;
  } catch (_) {}

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open WhatsApp')),
    );
  }
}

/// Returns digits-only international number (e.g. `9198xxxxxxxx`), or null.
String? normalizeWhatsAppPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;

  if (digits.length == 10) return '91$digits';
  if (digits.length == 11 && digits.startsWith('0')) {
    return '91${digits.substring(1)}';
  }
  if (digits.length >= 11 && digits.length <= 15) return digits;
  return null;
}
