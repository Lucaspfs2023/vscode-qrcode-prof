import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrcode_prof/features/correcao/correcao_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores a correction with its answers', () async {
    final registro = CorrecaoRegistro.criar(
      aluno: 'Ana Ribeiro',
      turma: '1º Ano A',
      prova: 'AV1',
      disciplina: 'Matemática',
      dataProva: '07/11/2026',
      acertos: 2,
      erros: 1,
      totalQuestoes: 3,
      respostas: const ['A', 'C', 'B'],
      gabarito: const ['A', 'B', 'B'],
    );

    await CorrecoesRepository.add(registro);
    final historico = await CorrecoesRepository.load();

    expect(historico, hasLength(1));
    expect(historico.single.aluno, 'Ana Ribeiro');
    expect(historico.single.turma, '1º Ano A');
    expect(historico.single.respostas, ['A', 'C', 'B']);
    expect(historico.single.gabarito, ['A', 'B', 'B']);
    expect(historico.single.percentual, closeTo(66.67, 0.01));
  });

  test('updates and deletes a saved correction', () async {
    final registro = CorrecaoRegistro.criar(
      aluno: 'Ana Ribeiro',
      turma: '1º Ano A',
      prova: 'AV1',
      disciplina: 'Matemática',
      dataProva: '07/11/2026',
      acertos: 2,
      erros: 1,
      totalQuestoes: 3,
      respostas: const ['A', 'C', 'B'],
      gabarito: const ['A', 'B', 'B'],
    );
    await CorrecoesRepository.add(registro);

    await CorrecoesRepository.update(
      registro.copyWith(aluno: 'Ana Silva', respostas: const ['A', 'B', 'B']),
    );
    expect((await CorrecoesRepository.load()).single.aluno, 'Ana Silva');
    expect(
        (await CorrecoesRepository.load()).single.respostas, ['A', 'B', 'B']);

    await CorrecoesRepository.delete(registro.id);
    expect(await CorrecoesRepository.load(), isEmpty);
  });

  test('duplicate key ignores case and whitespace in student identity', () {
    final original = CorrecaoRegistro.criar(
      provaId: 'exam-1',
      aluno: 'Ana Ribeiro',
      turma: '1º Ano A',
      prova: 'AV1',
      disciplina: 'Matemática',
      dataProva: '07/11/2026',
      acertos: 2,
      erros: 1,
      totalQuestoes: 3,
      respostas: const ['A', 'C', 'B'],
      gabarito: const ['A', 'B', 'B'],
    );
    final sameAttempt = original.copyWith(
      aluno: '  ANA RIBEIRO ',
      turma: '1º ano a ',
      respostas: const ['a', 'c', 'b'],
    );

    expect(sameAttempt.chaveDuplicidade, original.chaveDuplicidade);
  });
}
