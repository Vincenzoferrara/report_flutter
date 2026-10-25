import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Asks the user where to save [bytes] with the system save dialog, then
/// writes them there.
///
/// On Linux the dialog goes through the XDG desktop portal, so it also works
/// inside a Flatpak sandbox; on Android it is the system "create document"
/// picker. No initial folder is passed: Windows, macOS and the portals
/// remember the last folder by themselves.
///
/// Returns the name (or path, where there is one) of the saved file, or null
/// when the user cancels.
Future<String?> saveFileWithDialog({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
  String? dialogTitle,
}) async {
  final saved = await FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
  if (saved == null) return null;
  if (saved.scheme == 'file') return saved.toFilePath();
  // Content URIs (Android) only carry a document id such as
  // "primary:Download/labels.pdf": show its last part.
  final last = Uri.decodeComponent(
    saved.pathSegments.isEmpty ? '' : saved.pathSegments.last,
  );
  final name = last.split(RegExp(r'[/:]')).last;
  return name.isEmpty ? fileName : name;
}
