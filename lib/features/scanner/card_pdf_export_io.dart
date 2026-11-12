import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> exportCardPdf({
  required String titulo,
  required String disciplina,
  required String aluno,
  required String turma,
  required List<String> respostas,
  required int quantidadeQuestoes,
  required String payload,
  required String filename,
}) async {
  final pdf = pw.Document();
  final letras = ['A', 'B', 'C', 'D', 'E'];
  final linhas = List.generate(quantidadeQuestoes, (index) {
    final resposta = index < respostas.length ? respostas[index] : '';
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 22,
          child:
              pw.Text('${index + 1}', style: const pw.TextStyle(fontSize: 8)),
        ),
        ...letras.map((opcao) {
          final ativada = resposta == opcao;
          return pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              height: 15,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: ativada ? PdfColors.blue700 : PdfColors.grey400,
                  width: ativada ? 1.2 : 0.8,
                ),
                color: ativada ? PdfColors.blue50 : PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                opcao,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight:
                      ativada ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: PdfColors.black,
                ),
              ),
            ),
          );
        }),
      ],
    );
  });

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      build: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          titulo.isNotEmpty ? titulo : 'Prova',
                          style: const pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          disciplina.isNotEmpty ? disciplina : 'Disciplina',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${aluno.isNotEmpty ? aluno : 'Aluno'} • ${turma.isNotEmpty ? turma : 'Turma'}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 72,
                        height: 72,
                        color: PdfColors.grey200,
                        child: pw.Center(
                          child: pw.Text(
                            'QR',
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Código do cartão',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                width: double.infinity,
                color: PdfColors.black,
                child: pw.Text(
                  'Cartão-resposta',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 22,
                          child: pw.Text(
                            'Nº',
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'A',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'B',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'C',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'D',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            'E',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...linhas,
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'Assinatura do aluno',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'Data',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  final bytes = await pdf.save();

  final downloadsDirectory = await getDownloadsDirectory();
  final targetDirectory = downloadsDirectory ?? await getTemporaryDirectory();
  final normalizedFilename =
      filename.trim().isEmpty ? 'cartao_resposta.pdf' : filename;
  final file = File(
      '${targetDirectory.path}${Platform.pathSeparator}$normalizedFilename');
  await file.writeAsBytes(bytes, flush: true);
}
