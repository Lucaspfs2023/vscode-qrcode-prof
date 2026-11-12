import 'pdf_export_io.dart' if (dart.library.html) 'pdf_export_web.dart'
    as export_impl;

Future<void> exportPdf(
  List<Map<String, dynamic>> rows,
  String filename, {
  String title = 'Relatório de desempenho',
  String subtitle = 'QRCODE PROF',
  Map<String, String> summary = const <String, String>{},
}) async {
  await export_impl.exportPdf(
    rows,
    filename,
    title: title,
    subtitle: subtitle,
    summary: summary,
  );
}
