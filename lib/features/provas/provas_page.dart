import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _provasStorageKey = 'qrcode_prof_provas';
const String _questoesStorageKey = 'qrcode_prof_questoes';

class Questao {
  Questao({
    required this.enunciado,
    required this.respostaCorreta,
    this.disciplina = 'Geral',
    this.assunto = 'Geral',
    this.dificuldade = 'Média',
  }) : id = DateTime.now().microsecondsSinceEpoch.toString();

  Questao.withId({
    required this.id,
    required this.enunciado,
    required this.respostaCorreta,
    this.disciplina = 'Geral',
    this.assunto = 'Geral',
    this.dificuldade = 'Média',
  });

  final String id;
  final String enunciado;
  final String respostaCorreta;
  final String disciplina;
  final String assunto;
  final String dificuldade;

  String get respostaNormalizada =>
      respostaCorreta.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'enunciado': enunciado,
        'respostaCorreta': respostaCorreta,
        'disciplina': disciplina,
        'assunto': assunto,
        'dificuldade': dificuldade,
      };

  factory Questao.fromJson(Map<String, dynamic> json) {
    return Questao.withId(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      enunciado: json['enunciado'] as String? ?? 'Questão sem enunciado',
      respostaCorreta: json['respostaCorreta'] as String? ?? 'A',
      disciplina: json['disciplina'] as String? ?? 'Geral',
      assunto: json['assunto'] as String? ?? 'Geral',
      dificuldade: json['dificuldade'] as String? ?? 'Média',
    );
  }
}

class Prova {
  Prova({
    String? id,
    required this.titulo,
    required this.disciplina,
    required this.data,
    required this.gabarito,
    List<String>? gabaritoPorQuestao,
    List<Questao>? questoes,
  })  : id = id ?? 'prova_${DateTime.now().microsecondsSinceEpoch}',
        questoes = List.unmodifiable(questoes ?? const <Questao>[]),
        gabaritoPorQuestao = List.unmodifiable(
          gabaritoPorQuestao ??
              (questoes != null
                  ? questoes.map((q) => q.respostaNormalizada).toList()
                  : normalizarLista(gabarito)),
        );

  final String id;
  final String titulo;
  final String disciplina;
  final String data;
  final String gabarito;
  final List<String> gabaritoPorQuestao;
  final List<Questao> questoes;

  int get totalQuestoes =>
      questoes.isNotEmpty ? questoes.length : gabaritoPorQuestao.length;

  static List<String> normalizarLista(String valor) {
    final texto = valor.trim();
    if (texto.isEmpty || texto.toLowerCase() == 'não informado') {
      return const <String>[];
    }

    return texto
        .replaceAll(RegExp(r'[;]'), '\n')
        .replaceAll(',', '\n')
        .split(RegExp(r'\r?\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) {
          final match =
              RegExp(r'^(?:\d+\s*[:.-]?\s*)?([A-Ea-e0-9]+)$').firstMatch(item);
          final resposta = match != null ? match.group(1)! : item;
          return resposta.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'disciplina': disciplina,
        'data': data,
        'gabarito': gabarito,
        'gabaritoPorQuestao': gabaritoPorQuestao,
        'questoes': questoes.map((questao) => questao.toJson()).toList(),
      };

  factory Prova.fromJson(Map<String, dynamic> json) {
    final rawGabarito = json['gabarito'] as String? ?? '';
    final listaGabarito = (json['gabaritoPorQuestao'] is List)
        ? List<String>.from(
            (json['gabaritoPorQuestao'] as List).map((item) => item.toString()),
          )
        : normalizarLista(rawGabarito);

    final listaQuestoes = (json['questoes'] is List)
        ? (json['questoes'] as List)
            .map((item) => Questao.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : <Questao>[];

    final gabarito = listaQuestoes.isNotEmpty
        ? listaQuestoes.map((item) => item.respostaNormalizada).join(', ')
        : (listaGabarito.isNotEmpty ? listaGabarito.join(', ') : rawGabarito);

    final titulo = json['titulo'] as String? ?? 'Prova';
    final disciplina = json['disciplina'] as String? ?? 'Sem disciplina';
    final data = json['data'] as String? ?? 'Sem data';
    return Prova(
      id: json['id'] as String? ??
          'legacy_${base64Url.encode(utf8.encode('$titulo|$disciplina|$data'))}',
      titulo: titulo,
      disciplina: disciplina,
      data: data,
      gabarito: gabarito,
      gabaritoPorQuestao: listaQuestoes.isNotEmpty
          ? listaQuestoes.map((item) => item.respostaNormalizada).toList()
          : listaGabarito,
      questoes: listaQuestoes,
    );
  }
}

class ProvasRepository {
  static List<Prova> seedProvas() {
    return [
      Prova(
        id: 'seed-av1-matematica',
        titulo: 'AV1 - Matemática',
        disciplina: 'Matemática',
        data: '07/11/2026',
        gabarito: 'A, B, C, D, A',
        questoes: [
          Questao(
              enunciado: 'Questão 1',
              respostaCorreta: 'A',
              disciplina: 'Matemática'),
          Questao(
              enunciado: 'Questão 2',
              respostaCorreta: 'B',
              disciplina: 'Matemática'),
          Questao(
              enunciado: 'Questão 3',
              respostaCorreta: 'C',
              disciplina: 'Matemática'),
          Questao(
              enunciado: 'Questão 4',
              respostaCorreta: 'D',
              disciplina: 'Matemática'),
          Questao(
              enunciado: 'Questão 5',
              respostaCorreta: 'A',
              disciplina: 'Matemática'),
        ],
      ),
      Prova(
        id: 'seed-av2-historia',
        titulo: 'AV2 - História',
        disciplina: 'História',
        data: '12/11/2026',
        gabarito: 'B, C, A, D, B',
        questoes: [
          Questao(
              enunciado: 'Questão 1',
              respostaCorreta: 'B',
              disciplina: 'História'),
          Questao(
              enunciado: 'Questão 2',
              respostaCorreta: 'C',
              disciplina: 'História'),
          Questao(
              enunciado: 'Questão 3',
              respostaCorreta: 'A',
              disciplina: 'História'),
          Questao(
              enunciado: 'Questão 4',
              respostaCorreta: 'D',
              disciplina: 'História'),
          Questao(
              enunciado: 'Questão 5',
              respostaCorreta: 'B',
              disciplina: 'História'),
        ],
      ),
    ];
  }

  static Future<List<Prova>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_provasStorageKey);

    if (raw == null || raw.isEmpty) {
      return seedProvas();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return seedProvas();
      }

      return decoded
          .map<Prova>((item) => Prova.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return seedProvas();
    }
  }

  static Future<void> save(List<Prova> provas) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(
      provas.map((prova) => prova.toJson()).toList(),
    );
    await prefs.setString(_provasStorageKey, serialized);
  }
}

class QuestoesRepository {
  static Future<List<Questao>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_questoesStorageKey);
    if (raw == null || raw.isEmpty) {
      return const <Questao>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Questao>[];
      }

      return decoded
          .map((item) => Questao.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const <Questao>[];
    }
  }

  static Future<void> save(List<Questao> questoes) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(
      questoes.map((questao) => questao.toJson()).toList(),
    );
    await prefs.setString(_questoesStorageKey, serialized);
  }
}

class ProvasPage extends StatefulWidget {
  const ProvasPage({
    super.key,
    this.onChanged,
  });

  final VoidCallback? onChanged;

  @override
  State<ProvasPage> createState() => _ProvasPageState();
}

class _ProvasPageState extends State<ProvasPage> {
  final List<Prova> _provas = <Prova>[];
  final List<Questao> _bancoQuestoes = <Questao>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProvas();
    _carregarBancoQuestoes();
  }

  Future<void> _carregarProvas() async {
    final provas = await ProvasRepository.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _provas
        ..clear()
        ..addAll(provas);
      _isLoading = false;
    });
  }

  Future<void> _carregarBancoQuestoes() async {
    final questoes = await QuestoesRepository.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _bancoQuestoes
        ..clear()
        ..addAll(questoes);
    });
  }

  Future<void> _salvarProvas() async {
    await ProvasRepository.save(_provas);
  }

  Future<void> _salvarBancoQuestoes() async {
    await QuestoesRepository.save(_bancoQuestoes);
  }

  Future<void> _adicionarQuestaoAoBanco() async {
    final enunciadoController = TextEditingController();
    final disciplinaController = TextEditingController();
    final assuntoController = TextEditingController();
    final respostaController = TextEditingController();
    final nivelController = TextEditingController(text: 'Média');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova questão no banco'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: enunciadoController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Enunciado'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: disciplinaController,
                decoration: const InputDecoration(labelText: 'Disciplina'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: assuntoController,
                decoration: const InputDecoration(labelText: 'Assunto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: respostaController,
                textCapitalization: TextCapitalization.characters,
                decoration:
                    const InputDecoration(labelText: 'Resposta correta'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nivelController,
                decoration: const InputDecoration(labelText: 'Dificuldade'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop({
              'enunciado': enunciadoController.text.trim(),
              'disciplina': disciplinaController.text.trim(),
              'assunto': assuntoController.text.trim(),
              'resposta': respostaController.text.trim(),
              'dificuldade': nivelController.text.trim(),
            }),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == null) {
      return;
    }

    final enunciado = result['enunciado'] ?? '';
    final disciplina = result['disciplina'] ?? 'Geral';
    final assunto = result['assunto'] ?? 'Geral';
    final resposta = (result['resposta'] ?? '')
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final dificuldade = result['dificuldade'] ?? 'Média';

    if (enunciado.isEmpty || resposta.isEmpty) {
      return;
    }

    setState(() {
      _bancoQuestoes.add(
        Questao(
          enunciado: enunciado,
          respostaCorreta: resposta,
          disciplina: disciplina.isEmpty ? 'Geral' : disciplina,
          assunto: assunto.isEmpty ? 'Geral' : assunto,
          dificuldade: dificuldade.isEmpty ? 'Média' : dificuldade,
        ),
      );
    });
    await _salvarBancoQuestoes();
  }

  String _normalizarGabaritoEditor(String valor) {
    final linhas = valor
        .replaceAll(RegExp(r'[;]'), '\n')
        .replaceAll(',', '\n')
        .split(RegExp(r'\r?\n'));

    final respostas = <String>[];
    for (final linha in linhas) {
      final texto = linha.trim();
      if (texto.isEmpty) {
        continue;
      }

      final match =
          RegExp(r'^(?:\d+\s*[:.-]?\s*)?([A-Ea-e0-9]+)$').firstMatch(texto);
      final valorNormalizado = match != null ? match.group(1)! : texto;
      final resposta = valorNormalizado
          .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
          .toUpperCase();

      if (resposta.isNotEmpty) {
        respostas.add(resposta);
      }
    }

    return respostas.join('\n');
  }

  String _persistirGabarito(String valor) {
    final texto = _normalizarGabaritoEditor(valor);
    if (texto.trim().isEmpty) {
      return 'Não informado';
    }

    final respostas = texto
        .split(RegExp(r'\r?\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return respostas.join(', ');
  }

  List<String> _respostasParaLinhas(List<String> respostas) {
    final lista = respostas
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (lista.isEmpty) {
      return const [''];
    }

    return lista;
  }

  Future<void> _salvarOuAtualizarProva({Prova? provaAtual}) async {
    final tituloController = TextEditingController(
      text: provaAtual?.titulo ?? '',
    );
    final disciplinaController = TextEditingController(
      text: provaAtual?.disciplina ?? '',
    );
    final dataController = TextEditingController(
      text: provaAtual?.data ?? '',
    );

    final linhasIniciais = provaAtual == null
        ? <String>['']
        : _respostasParaLinhas(provaAtual.gabaritoPorQuestao.isNotEmpty
            ? provaAtual.gabaritoPorQuestao
            : Prova.normalizarLista(provaAtual.gabarito));
    final controllers = linhasIniciais
        .map((valor) => TextEditingController(text: valor))
        .toList(growable: true);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(provaAtual == null ? 'Nova prova' : 'Editar prova'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: tituloController,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'Título'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: disciplinaController,
                        decoration:
                            const InputDecoration(labelText: 'Disciplina'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dataController,
                        decoration: const InputDecoration(labelText: 'Data'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Gabarito por questão',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              controllers.add(TextEditingController());
                              setDialogState(() {});
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List<Widget>.generate(controllers.length, (index) {
                        final controller = controllers[index];
                        final numeroQuestao = index + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 70,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Questão',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Center(
                                    child: Text('$numeroQuestao'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    labelText: 'Resposta esperada',
                                    hintText: 'A',
                                  ),
                                ),
                              ),
                              if (controllers.length > 1)
                                IconButton(
                                  tooltip: 'Remover questão',
                                  onPressed: () {
                                    controllers.removeAt(index);
                                    setDialogState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final respostas = controllers
                        .map((item) => item.text.trim())
                        .where((item) => item.isNotEmpty)
                        .map((item) => item
                            .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                            .toUpperCase())
                        .toList();

                    final questoes = respostas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final resposta = entry.value;
                      return Questao(
                        enunciado: 'Questão ${index + 1}',
                        respostaCorreta: resposta,
                        disciplina: disciplinaController.text.trim().isEmpty
                            ? 'Geral'
                            : disciplinaController.text.trim(),
                        assunto: 'Prova',
                        dificuldade: 'Média',
                      );
                    }).toList(growable: false);

                    Navigator.of(context).pop({
                      'titulo': tituloController.text.trim(),
                      'disciplina': disciplinaController.text.trim(),
                      'data': dataController.text.trim(),
                      'gabarito': respostas.join(', '),
                      'questoes': questoes,
                    });
                  },
                  child: Text(provaAtual == null ? 'Salvar' : 'Atualizar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    final titulo = result['titulo'] ?? '';
    final disciplina = result['disciplina'] ?? '';
    final data = result['data'] ?? '';
    final gabarito = _persistirGabarito(result['gabarito'] ?? '');
    final questoes = ((result['questoes'] as List?) ?? <Questao>[])
        .map((item) => item is Questao
            ? item
            : Questao.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final gabaritoPorQuestao = questoes.isNotEmpty
        ? questoes
            .map((item) => item.respostaNormalizada)
            .toList(growable: false)
        : Prova.normalizarLista(gabarito);

    if (titulo.isEmpty || disciplina.isEmpty) {
      return;
    }

    setState(() {
      if (provaAtual == null) {
        _provas.add(
          Prova(
            id: 'prova_${DateTime.now().microsecondsSinceEpoch}',
            titulo: titulo,
            disciplina: disciplina,
            data: data.isEmpty ? 'Sem data' : data,
            gabarito: gabarito,
            gabaritoPorQuestao: gabaritoPorQuestao,
            questoes: questoes,
          ),
        );
        return;
      }

      final index = _provas.indexWhere((item) =>
          item.titulo == provaAtual.titulo &&
          item.disciplina == provaAtual.disciplina &&
          item.data == provaAtual.data &&
          item.gabarito == provaAtual.gabarito);

      if (index >= 0) {
        _provas[index] = Prova(
          id: provaAtual.id,
          titulo: titulo,
          disciplina: disciplina,
          data: data.isEmpty ? 'Sem data' : data,
          gabarito: gabarito,
          gabaritoPorQuestao: gabaritoPorQuestao,
          questoes: questoes,
        );
      }
    });
    await _salvarProvas();
    widget.onChanged?.call();
  }

  Future<void> _adicionarProva() async {
    await _salvarOuAtualizarProva();
  }

  Future<void> _editarProva(Prova prova) async {
    await _salvarOuAtualizarProva(provaAtual: prova);
  }

  Future<void> _removerProva(Prova prova) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover prova'),
        content: Text('Deseja remover a prova "${prova.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmado != true) {
      return;
    }

    setState(() {
      _provas.removeWhere((item) =>
          item.titulo == prova.titulo &&
          item.disciplina == prova.disciplina &&
          item.data == prova.data &&
          item.gabarito == prova.gabarito);
    });
    await _salvarProvas();
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Provas e gabaritos',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _adicionarQuestaoAoBanco,
                    icon: const Icon(Icons.quiz_rounded),
                    label: const Text('Nova questão'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _adicionarProva,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nova prova'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_bancoQuestoes.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Banco de questões',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._bancoQuestoes.take(3).map((questao) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.help_outline_rounded,
                                    size: 18, color: Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${questao.enunciado} • Resposta: ${questao.respostaNormalizada}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_bancoQuestoes.length > 3)
                          Text(
                            '... e ${_bancoQuestoes.length - 3} questões a mais',
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_bancoQuestoes.isNotEmpty) const SizedBox(height: 18),
              Expanded(
                child: _provas.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma prova cadastrada ainda.',
                          style: TextStyle(color: Color(0xFF667085)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _provas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final prova = _provas[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Color(0xFFEAF1FF),
                                        foregroundColor: Color(0xFF2563EB),
                                        child: Icon(Icons.assignment_rounded),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          prova.titulo,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'editar') {
                                            _editarProva(prova);
                                          } else if (value == 'excluir') {
                                            _removerProva(prova);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'editar',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded),
                                                SizedBox(width: 8),
                                                Text('Editar prova'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'excluir',
                                            child: Row(
                                              children: [
                                                Icon(Icons
                                                    .delete_outline_rounded),
                                                SizedBox(width: 8),
                                                Text('Excluir prova'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Disciplina: ${prova.disciplina}',
                                    style: const TextStyle(
                                      color: Color(0xFF475467),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Data: ${prova.data}',
                                    style: const TextStyle(
                                        color: Color(0xFF667085)),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FB),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gabarito (${prova.totalQuestoes} respostas)',
                                          style: const TextStyle(
                                            color: Color(0xFF1D4ED8),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          prova.gabarito,
                                          style: const TextStyle(
                                            color: Color(0xFF1D4ED8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
