import 'package:flutter_test/flutter_test.dart';
import 'package:qrcode_prof/features/relatorios/pdf_report_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a paginated report with executive summary and table rows',
      () async {
    final document = await buildPdfReport(
      const [
        {
          'Aluno': 'Ana Ribeiro',
          'Turma': '1º Ano A',
          'Aproveitamento': '80.0%',
        },
      ],
      title: 'Painel executivo de desempenho',
      subtitle: 'Resultados reais',
      summary: const {'Correções': '1', 'Média geral': '80.0%'},
    );

    final bytes = await document.save();
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
