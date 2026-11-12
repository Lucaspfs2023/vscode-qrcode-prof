import 'text_export_io.dart' if (dart.library.html) 'text_export_web.dart'
    as export_impl;

Future<void> exportText(
  String content,
  String filename, {
  required String contentType,
}) =>
    export_impl.exportText(
      content,
      filename,
      contentType: contentType,
    );
