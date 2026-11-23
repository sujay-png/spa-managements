import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

class FileSaver {
  static Future<void> download({
    required List<int> bytes,
    required String fileName,
    String mimeType = 'application/pdf',
  }) async {
    await saveFileWeb(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  static Future<void> openInNewTab({
    required List<int> bytes,
    String mimeType = 'application/pdf',
  }) async {
    await openFileWeb(
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
