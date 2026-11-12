import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'pdf_report_builder.dart';

Future<void> exportPdf(
  List<Map<String, dynamic>> rows,
  String filename, {
  String title = 'Relatório de desempenho',
  String subtitle = 'QRCODE PROF',
  Map<String, String> summary = const <String, String>{},
}) async {
  final pdf = await buildPdfReport(
    rows,
    title: title,
    subtitle: subtitle,
    summary: summary,
  );
  final bytes = await pdf.save();

  try {
    final downloadsDirectory = await getDownloadsDirectory();
    final targetDirectory = downloadsDirectory ?? await getTemporaryDirectory();
    final file =
        File('${targetDirectory.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
  } catch (error) {
    debugPrint('Erro ao exportar PDF: $error');
    rethrow;
  }
}
