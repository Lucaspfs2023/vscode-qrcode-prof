import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _correcoesStorageKey = 'qrcode_prof_historico_correcoes';

class CorrecaoRegistro {
  const CorrecaoRegistro({
    required this.id,
    this.provaId,
    required this.aluno,
    required this.turma,
    required this.prova,
    required this.disciplina,
    required this.dataProva,
    required this.dataCorrecao,
    required this.acertos,
    required this.erros,
    required this.totalQuestoes,
    required this.respostas,
    required this.gabarito,
  });

  final String id;
  final String? provaId;
  final String aluno;
  final String turma;
  final String prova;
  final String disciplina;
  final String dataProva;
  final DateTime dataCorrecao;
  final int acertos;
  final int erros;
  final int totalQuestoes;
  final List<String> respostas;
  final List<String> gabarito;

  double get percentual =>
      totalQuestoes == 0 ? 0 : (acertos / totalQuestoes) * 100;

  String get chaveDuplicidade => [
        provaId ?? '$prova|$disciplina',
        turma.trim().toLowerCase(),
        aluno.trim().toLowerCase(),
        respostas.map((resposta) => resposta.trim().toUpperCase()).join(','),
      ].join('|');

  CorrecaoRegistro copyWith({
    String? provaId,
    String? aluno,
    String? turma,
    String? prova,
    String? disciplina,
    String? dataProva,
    DateTime? dataCorrecao,
    int? acertos,
    int? erros,
    int? totalQuestoes,
    List<String>? respostas,
    List<String>? gabarito,
  }) {
    return CorrecaoRegistro(
      id: id,
      provaId: provaId ?? this.provaId,
      aluno: aluno ?? this.aluno,
      turma: turma ?? this.turma,
      prova: prova ?? this.prova,
      disciplina: disciplina ?? this.disciplina,
      dataProva: dataProva ?? this.dataProva,
      dataCorrecao: dataCorrecao ?? this.dataCorrecao,
      acertos: acertos ?? this.acertos,
      erros: erros ?? this.erros,
      totalQuestoes: totalQuestoes ?? this.totalQuestoes,
      respostas: List.unmodifiable(respostas ?? this.respostas),
      gabarito: List.unmodifiable(gabarito ?? this.gabarito),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (provaId != null) 'provaId': provaId,
        'aluno': aluno,
        'turma': turma,
        'prova': prova,
        'disciplina': disciplina,
        'dataProva': dataProva,
        'dataCorrecao': dataCorrecao.toIso8601String(),
        'acertos': acertos,
        'erros': erros,
        'totalQuestoes': totalQuestoes,
        'respostas': respostas,
        'gabarito': gabarito,
      };

  factory CorrecaoRegistro.fromJson(Map<String, dynamic> json) {
    return CorrecaoRegistro(
      id: json['id'] as String,
      provaId: json['provaId'] as String?,
      aluno: json['aluno'] as String,
      turma: json['turma'] as String,
      prova: json['prova'] as String,
      disciplina: json['disciplina'] as String,
      dataProva: json['dataProva'] as String? ?? 'Sem data',
      dataCorrecao: DateTime.parse(json['dataCorrecao'] as String),
      acertos: json['acertos'] as int,
      erros: json['erros'] as int,
      totalQuestoes: json['totalQuestoes'] as int,
      respostas: List<String>.from(json['respostas'] as List),
      gabarito: List<String>.from(json['gabarito'] as List),
    );
  }

  static CorrecaoRegistro criar({
    String? provaId,
    required String aluno,
    required String turma,
    required String prova,
    required String disciplina,
    required String dataProva,
    required int acertos,
    required int erros,
    required int totalQuestoes,
    required List<String> respostas,
    required List<String> gabarito,
  }) {
    final agora = DateTime.now();
    return CorrecaoRegistro(
      id: '${agora.microsecondsSinceEpoch}',
      provaId: provaId,
      aluno: aluno,
      turma: turma,
      prova: prova,
      disciplina: disciplina,
      dataProva: dataProva,
      dataCorrecao: agora,
      acertos: acertos,
      erros: erros,
      totalQuestoes: totalQuestoes,
      respostas: List.unmodifiable(respostas),
      gabarito: List.unmodifiable(gabarito),
    );
  }
}

class CorrecoesRepository {
  static Future<List<CorrecaoRegistro>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_correcoesStorageKey);
    if (raw == null || raw.isEmpty) {
      return const <CorrecaoRegistro>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Histórico de correções inválido.');
    }
    return decoded
        .map((item) => CorrecaoRegistro.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(growable: false);
  }

  static Future<void> add(CorrecaoRegistro registro) async {
    final correcoes = await load();
    final updated = [...correcoes, registro];
    await save(updated);
  }

  static Future<void> save(List<CorrecaoRegistro> correcoes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _correcoesStorageKey,
      jsonEncode(correcoes.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> update(CorrecaoRegistro registro) async {
    final correcoes = (await load()).toList();
    final index = correcoes.indexWhere((item) => item.id == registro.id);
    if (index < 0) {
      throw StateError('A correção ${registro.id} não foi encontrada.');
    }
    correcoes[index] = registro;
    await save(correcoes);
  }

  static Future<void> delete(String id) async {
    final correcoes = await load();
    await save(correcoes.where((item) => item.id != id).toList());
  }
}
