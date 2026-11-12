import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_prof/features/backup/backup_repository.dart';
import 'package:qrcode_prof/features/correcao/correcao_repository.dart';
import 'package:qrcode_prof/features/provas/provas_page.dart';
import 'package:qrcode_prof/features/turmas/turmas_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('backup restores classes, exams, question bank and corrections',
      () async {
    final prova = Prova(
      id: 'exam-1',
      titulo: 'Avaliação 1',
      disciplina: 'Matemática',
      data: '11/11/2026',
      gabarito: 'A,B',
    );
    final questao = Questao(
      enunciado: 'Quanto é 1 + 1?',
      respostaCorreta: 'B',
    );
    final correcao = CorrecaoRegistro.criar(
      provaId: prova.id,
      aluno: 'Ana',
      turma: '1º A',
      prova: prova.titulo,
      disciplina: prova.disciplina,
      dataProva: prova.data,
      acertos: 1,
      erros: 1,
      totalQuestoes: 2,
      respostas: const ['A', 'C'],
      gabarito: const ['A', 'B'],
    );
    await TurmasRepository.save([
      Turma(nome: '1º A', alunos: ['Ana'])
    ]);
    await ProvasRepository.save([prova]);
    await QuestoesRepository.save([questao]);
    await CorrecoesRepository.save([correcao]);

    final backup = await BackupRepository.createBackup();
    await TurmasRepository.save(const []);
    await ProvasRepository.save(const []);
    await QuestoesRepository.save(const []);
    await CorrecoesRepository.save(const []);

    await BackupRepository.restoreBackup(backup);

    expect((await TurmasRepository.load()).single.alunos, ['Ana']);
    expect((await ProvasRepository.load()).single.id, 'exam-1');
    expect(
        (await QuestoesRepository.load()).single.enunciado, 'Quanto é 1 + 1?');
    expect((await CorrecoesRepository.load()).single.provaId, 'exam-1');
  });

  test('invalid backup is rejected without changing existing data', () async {
    await TurmasRepository.save([Turma(nome: 'Preservada')]);

    expect(
      () => BackupRepository.restoreBackup('{"schema":"outro","version":1}'),
      throwsFormatException,
    );
    expect((await TurmasRepository.load()).single.nome, 'Preservada');
  });
}
