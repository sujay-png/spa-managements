import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

class FileSaver {
  static Future<void> download({
    required List<int> bytes,
    required String fileName,
    String mimeType = 'text/csv;charset=utf-8;',
  }) async {
    await saveFileWeb(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
