import 'csv_export_io.dart'
    if (dart.library.html) 'csv_export_web.dart' as export_impl;

Future<void> exportCsv(String csv, String filename) async {
  await export_impl.exportCsv(csv, filename);
}
