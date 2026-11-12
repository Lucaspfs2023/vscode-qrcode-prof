import 'dart:js_interop';

import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

import 'pdf_report_builder.dart';

Future<void> exportPdf(
  List<Map<String, dynamic>> rows,
  String filename, {
  String title = 'Relatório de desempenho',
  String subtitle = 'QRCODE PROF',
  Map<String, String> summary = const <String, String>{},
}) async {
  final pw.Document pdf = await buildPdfReport(
    rows,
    title: title,
    subtitle: subtitle,
    summary: summary,
  );
  final bytes = await pdf.save();
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
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
