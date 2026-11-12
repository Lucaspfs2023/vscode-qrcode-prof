import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<void> exportText(
  String content,
  String filename, {
  required String contentType,
}) async {
  try {
    final downloadsDirectory = await getDownloadsDirectory();
    final targetDirectory = downloadsDirectory ?? await getTemporaryDirectory();
    final file =
        File('${targetDirectory.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(content, flush: true);
  } catch (error) {
    debugPrint('Erro ao exportar arquivo: $error');
    rethrow;
  }
}
