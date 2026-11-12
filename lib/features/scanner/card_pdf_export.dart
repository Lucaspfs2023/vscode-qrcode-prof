import 'card_pdf_export_io.dart'
    if (dart.library.html) 'card_pdf_export_web.dart' as export_impl;

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
  await export_impl.exportCardPdf(
    titulo: titulo,
    disciplina: disciplina,
    aluno: aluno,
    turma: turma,
    respostas: respostas,
    quantidadeQuestoes: quantidadeQuestoes,
    payload: payload,
    filename: filename,
  );
}
