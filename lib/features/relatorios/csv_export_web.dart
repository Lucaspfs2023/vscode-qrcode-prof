import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> exportCsv(String csv, String filename) async {
  final blob = web.Blob(
    [utf8.encode(csv).toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );

  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
