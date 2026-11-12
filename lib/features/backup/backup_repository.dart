import 'dart:convert';

import '../correcao/correcao_repository.dart';
import '../provas/provas_page.dart';
import '../turmas/turmas_page.dart';

class BackupRepository {
  static const _schema = 'qrcode-prof-local-backup';
  static const _version = 1;

  static Future<String> createBackup() async {
    final values = await Future.wait<Object>([
      TurmasRepository.load(),
      ProvasRepository.load(),
      QuestoesRepository.load(),
      CorrecoesRepository.load(),
    ]);
    return const JsonEncoder.withIndent('  ').convert({
      'schema': _schema,
      'version': _version,
      'createdAt': DateTime.now().toIso8601String(),
      'turmas':
          (values[0] as List<Turma>).map((item) => item.toJson()).toList(),
      'provas':
          (values[1] as List<Prova>).map((item) => item.toJson()).toList(),
      'questoes':
          (values[2] as List<Questao>).map((item) => item.toJson()).toList(),
      'correcoes': (values[3] as List<CorrecaoRegistro>)
          .map((item) => item.toJson())
          .toList(),
    });
  }

  static Future<void> restoreBackup(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['schema'] != _schema ||
        decoded['version'] != _version) {
      throw const FormatException('Arquivo de backup não reconhecido.');
    }

    final turmas = _readList<Turma>(
      decoded,
      'turmas',
      (json) => Turma.fromJson(json),
    );
    final provas = _readList<Prova>(
      decoded,
      'provas',
      (json) => Prova.fromJson(json),
    );
    final questoes = _readList<Questao>(
      decoded,
      'questoes',
      (json) => Questao.fromJson(json),
    );
    final correcoes = _readList<CorrecaoRegistro>(
      decoded,
      'correcoes',
      (json) => CorrecaoRegistro.fromJson(json),
    );

    final previous = await Future.wait<Object>([
      TurmasRepository.load(),
      ProvasRepository.load(),
      QuestoesRepository.load(),
      CorrecoesRepository.load(),
    ]);
    try {
      await TurmasRepository.save(turmas);
      await ProvasRepository.save(provas);
      await QuestoesRepository.save(questoes);
      await CorrecoesRepository.save(correcoes);
    } catch (error) {
      try {
        await TurmasRepository.save(previous[0] as List<Turma>);
        await ProvasRepository.save(previous[1] as List<Prova>);
        await QuestoesRepository.save(previous[2] as List<Questao>);
        await CorrecoesRepository.save(previous[3] as List<CorrecaoRegistro>);
      } catch (rollbackError) {
        throw StateError(
          'A restauração falhou ($error) e o retorno aos dados anteriores também falhou ($rollbackError).',
        );
      }
      rethrow;
    }
  }

  static List<T> _readList<T>(
    Map<String, dynamic> source,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = source[key];
    if (raw is! List) {
      throw FormatException('A lista "$key" está ausente ou inválida.');
    }
    return raw
        .map((item) => parse(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }
}
