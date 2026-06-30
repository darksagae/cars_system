import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';

/// [flutter_pdfview] only supports Android and iOS.
bool get inAppPdfViewSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

Future<bool> openLocalPdfExternally(String path) async {
  final uri = Uri.file(path);
  try {
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    }
  } catch (_) {}

  if (kIsWeb) return false;

  try {
    if (Platform.isLinux) {
      final result = await Process.run('xdg-open', [path]);
      return result.exitCode == 0;
    }
    if (Platform.isMacOS) {
      final result = await Process.run('open', [path]);
      return result.exitCode == 0;
    }
    if (Platform.isWindows) {
      final result = await Process.run('cmd', ['/c', 'start', '', path]);
      return result.exitCode == 0;
    }
  } catch (_) {}

  return false;
}

void showInAppPdfSheet(
  BuildContext context, {
  required String title,
  required String filePath,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          Expanded(
            child: PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Opens PDF in-app on Android/iOS, or in the system viewer on desktop.
Future<void> viewLocalPdf(
  BuildContext context, {
  required String title,
  required String filePath,
}) async {
  if (inAppPdfViewSupported) {
    showInAppPdfSheet(context, title: title, filePath: filePath);
    return;
  }

  final ok = await openLocalPdfExternally(filePath);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'Opening PDF in your default viewer…' : 'Could not open PDF on this device',
      ),
    ),
  );
}
