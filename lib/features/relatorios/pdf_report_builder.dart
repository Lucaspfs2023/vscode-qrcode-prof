import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> buildPdfReport(
  List<Map<String, dynamic>> rows, {
  required String title,
  required String subtitle,
  Map<String, String> summary = const <String, String>{},
}) async {
  final regularFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/roboto-regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/roboto-bold.ttf'),
  );
  final pdf = pw.Document();
  final headers = rows.isEmpty ? <String>[] : rows.first.keys.toList();
  final landscape = headers.length > 7;
  final percentKey = headers.cast<String?>().firstWhere(
        (key) => key == 'Percentual' || key == 'Aproveitamento',
        orElse: () => null,
      );
  final percentages = percentKey == null
      ? <double>[]
      : rows
          .map((row) =>
              double.tryParse(row[percentKey].toString().replaceAll('%', '')))
          .whereType<double>()
          .toList();
  final calculatedSummary = <String, String>{
    'Registros': '${rows.length}',
    if (percentages.isNotEmpty) ...{
      'Média':
          '${(percentages.reduce((a, b) => a + b) / percentages.length).toStringAsFixed(1)}%',
      'Melhor':
          '${percentages.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%',
      'Menor':
          '${percentages.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}%',
    },
  };
  final summaryItems = summary.isEmpty ? calculatedSummary : summary;
  final generatedAt = DateTime.now();

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 34),
      header: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue700, width: 2),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'QRCODE PROF  /  RELATÓRIO EXECUTIVO',
                  style: const pw.TextStyle(
                    color: PdfColors.blue700,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: const pw.TextStyle(
                    color: PdfColors.blueGrey900,
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(
                      subtitle,
                      style: const pw.TextStyle(
                        color: PdfColors.blueGrey700,
                        fontSize: 8,
                      ),
                    ),
                  ),
              ],
            ),
            pw.Text(
              'Gerado em ${generatedAt.toLocal().toString().substring(0, 16)}',
              style: const pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: .5),
          ),
        ),
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
        ),
      ),
      build: (context) => [
        if (summaryItems.isNotEmpty)
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summaryItems.entries
                .map(
                  (entry) => pw.Container(
                    width: landscape ? 175 : 120,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColors.blue100),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          entry.key.toUpperCase(),
                          style: const pw.TextStyle(
                            color: PdfColors.blueGrey700,
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          entry.value,
                          style: const pw.TextStyle(
                            color: PdfColors.blueGrey900,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        if (headers.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey200, width: .5),
              verticalInside:
                  pw.BorderSide(color: PdfColors.grey200, width: .5),
              bottom: pw.BorderSide(color: PdfColors.grey300, width: .5),
            ),
            columnWidths: {
              for (var index = 0; index < headers.length; index++)
                index: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey900),
                children: headers
                    .map(
                      (header) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 7,
                        ),
                        child: pw.Text(
                          header,
                          maxLines: 2,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: landscape ? 7 : 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...rows.asMap().entries.map(
                    (entry) => pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: entry.key.isEven
                            ? PdfColors.white
                            : PdfColors.grey100,
                      ),
                      children: headers
                          .map(
                            (header) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 6,
                              ),
                              child: pw.Text(
                                entry.value[header]?.toString() ?? '',
                                maxLines: 2,
                                overflow: pw.TextOverflow.clip,
                                style: pw.TextStyle(
                                  color: PdfColors.blueGrey900,
                                  fontSize: landscape ? 6.5 : 8,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
            ],
          ),
        ],
      ],
    ),
  );
  return pdf;
}
