import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens phone dialer / WhatsApp for farmer contact numbers.
class ContactLauncher {
  ContactLauncher._();

  static String digitsOnly(String raw) =>
      raw.replaceAll(RegExp(r'\D'), '');

  /// India-friendly WhatsApp target: keeps country code if present, else 91.
  static String whatsappNumber(String raw) {
    var digits = digitsOnly(raw);
    if (digits.isEmpty) return '';
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (digits.length == 10) return '91$digits';
    return digits;
  }

  static Future<bool> call(String mobile) async {
    final digits = digitsOnly(mobile);
    if (digits.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openWhatsApp(String mobile, {String? message}) async {
    final number = whatsappNumber(mobile);
    if (number.isEmpty) return false;
    final query = <String, String>{};
    if (message != null && message.trim().isNotEmpty) {
      query['text'] = message.trim();
    }
    final uri = Uri.https('wa.me', '/$number', query);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: try whatsapp:// scheme on some devices.
      final alt = Uri.parse(
        'whatsapp://send?phone=$number${message != null && message.trim().isNotEmpty ? '&text=${Uri.encodeComponent(message.trim())}' : ''}',
      );
      try {
        return await launchUrl(alt, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  static Future<void> callOrSnack(BuildContext context, String mobile) async {
    final ok = await call(mobile);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  static Future<void> whatsappOrSnack(
    BuildContext context,
    String mobile, {
    String? message,
  }) async {
    final ok = await openWhatsApp(mobile, message: message);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }
}

/// Compact Call + WhatsApp action row for farmer contact.
class FarmerContactActions extends StatelessWidget {
  const FarmerContactActions({
    super.key,
    required this.mobile,
    this.farmerName,
    this.dense = false,
  });

  final String mobile;
  final String? farmerName;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (mobile.trim().isEmpty) return const SizedBox.shrink();

    final message = farmerName != null && farmerName!.trim().isNotEmpty
        ? 'Hello ${farmerName!.trim()}, this is Shine Gold.'
        : null;

    if (dense) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Call',
            onPressed: () => ContactLauncher.callOrSnack(context, mobile),
            icon: const Icon(Icons.call_rounded),
            color: const Color(0xFF1B7A4E),
          ),
          IconButton(
            tooltip: 'WhatsApp',
            onPressed: () => ContactLauncher.whatsappOrSnack(
              context,
              mobile,
              message: message,
            ),
            icon: const Icon(Icons.chat_rounded),
            color: const Color(0xFF25D366),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ContactLauncher.callOrSnack(context, mobile),
            icon: const Icon(Icons.call_rounded, size: 20),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B7A4E),
              side: const BorderSide(color: Color(0xFF1B7A4E), width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 44),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => ContactLauncher.whatsappOrSnack(
              context,
              mobile,
              message: message,
            ),
            icon: const Icon(Icons.chat_rounded, size: 20),
            label: const Text('WhatsApp'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 44),
            ),
          ),
        ),
      ],
    );
  }
}
