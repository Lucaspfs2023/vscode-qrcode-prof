import 'package:flutter/material.dart';

import '../correcao/correcao_repository.dart';
import '../relatorios/csv_export.dart';
import '../relatorios/pdf_export.dart';
import '../turmas/turmas_page.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final TextEditingController _buscaController = TextEditingController();
  List<CorrecaoRegistro> _correcoes = const <CorrecaoRegistro>[];
  List<Turma> _turmas = const <Turma>[];
  bool _isLoading = true;
  String? _loadError;
  String _filtroTurma = 'Todas';
  String _filtroProva = 'Todas';
  String _filtroDisciplina = 'Todas';
  String _filtroPeriodo = 'Todo o período';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final corrections = await CorrecoesRepository.load();
      final classes = await TurmasRepository.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _correcoes = corrections;
        _turmas = classes;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  List<String> _opcoes(List<String> values) =>
      ['Todas', ...values.toSet().toList()..sort()];

  List<CorrecaoRegistro> get _filtradas {
    final termo = _buscaController.text.trim().toLowerCase();
    final agora = DateTime.now();
    return _correcoes.where((registro) {
      final buscaOk = termo.isEmpty ||
          registro.aluno.toLowerCase().contains(termo) ||
          registro.turma.toLowerCase().contains(termo) ||
          registro.prova.toLowerCase().contains(termo) ||
          registro.disciplina.toLowerCase().contains(termo);
      final turmaOk = _filtroTurma == 'Todas' || registro.turma == _filtroTurma;
      final provaOk = _filtroProva == 'Todas' || registro.prova == _filtroProva;
      final disciplinaOk = _filtroDisciplina == 'Todas' ||
          registro.disciplina == _filtroDisciplina;
      final dias = agora.difference(registro.dataCorrecao).inDays;
      final periodoOk = switch (_filtroPeriodo) {
        'Últimos 30 dias' => dias <= 30,
        'Últimos 90 dias' => dias <= 90,
        'Este ano' => registro.dataCorrecao.year == agora.year,
        _ => true,
      };
      return buscaOk && turmaOk && provaOk && disciplinaOk && periodoOk;
    }).toList()
      ..sort((a, b) => b.dataCorrecao.compareTo(a.dataCorrecao));
  }

  Set<String> get _duplicadas {
    final counts = <String, int>{};
    for (final registro in _filtradas) {
      counts.update(
        registro.chaveDuplicidade,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return counts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toSet();
  }

  String _dataHora(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _csv(List<CorrecaoRegistro> registros) {
    final rows = <List<String>>[
      const [
        'Data da correção',
        'Aluno',
        'Turma',
        'Disciplina',
        'Prova',
        'Acertos',
        'Erros',
        'Total de questões',
        'Aproveitamento',
        'Respostas',
        'Gabarito',
      ],
      ...registros.map((registro) => [
            _dataHora(registro.dataCorrecao),
            registro.aluno,
            registro.turma,
            registro.disciplina,
            registro.prova,
            '${registro.acertos}',
            '${registro.erros}',
            '${registro.totalQuestoes}',
            '${registro.percentual.toStringAsFixed(1)}%',
            registro.respostas.join(' '),
            registro.gabarito.join(' '),
          ]),
    ];
    return '\uFEFF${rows.map((row) {
      return row.map((value) => '"${value.replaceAll('"', '""')}"').join(',');
    }).join('\n')}';
  }

  List<Map<String, dynamic>> _pdfRows(List<CorrecaoRegistro> registros) =>
      registros
          .map((registro) => <String, dynamic>{
                'Data da correção': _dataHora(registro.dataCorrecao),
                'Aluno': registro.aluno,
                'Turma': registro.turma,
                'Disciplina': registro.disciplina,
                'Prova': registro.prova,
                'Acertos': registro.acertos,
                'Erros': registro.erros,
                'Questões': registro.totalQuestoes,
                'Aproveitamento': '${registro.percentual.toStringAsFixed(1)}%',
              })
          .toList(growable: false);

  String _filename(String extension) {
    final now = DateTime.now();
    return 'qrcode-prof-historico-correcoes-'
        '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}.$extension';
  }

  Future<void> _exportarCsv() async {
    final registros = _filtradas;
    if (registros.isEmpty) {
      _notificar('Não há correções para exportar com os filtros atuais.');
      return;
    }
    final filename = _filename('csv');
    try {
      await exportCsv(_csv(registros), filename);
      _notificar('CSV exportado: $filename');
    } catch (error) {
      _notificar('Não foi possível exportar o CSV: $error');
    }
  }

  Future<void> _exportarPdf() async {
    final registros = _filtradas;
    if (registros.isEmpty) {
      _notificar('Não há correções para exportar com os filtros atuais.');
      return;
    }
    final filename = _filename('pdf');
    final media = registros.fold<double>(
          0,
          (sum, registro) => sum + registro.percentual,
        ) /
        registros.length;
    try {
      await exportPdf(
        _pdfRows(registros),
        filename,
        title: 'Histórico real de correções',
        subtitle:
            'Filtros: $_filtroDisciplina / $_filtroTurma / $_filtroPeriodo',
        summary: {
          'Correções': '${registros.length}',
          'Alunos':
              '${registros.map((r) => '${r.turma}|${r.aluno}').toSet().length}',
          'Média': '${media.toStringAsFixed(1)}%',
        },
      );
      _notificar('PDF exportado: $filename');
    } catch (error) {
      _notificar('Não foi possível exportar o PDF: $error');
    }
  }

  void _notificar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _editar(CorrecaoRegistro registro) async {
    final alunoController = TextEditingController(text: registro.aluno);
    final turmaController = TextEditingController(text: registro.turma);
    final respostasController =
        TextEditingController(text: registro.respostas.join(', '));
    final respostasNovas = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar correção'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: alunoController,
                decoration: const InputDecoration(labelText: 'Aluno'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: turmaController,
                decoration: const InputDecoration(labelText: 'Turma'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: respostasController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Respostas',
                  hintText: 'A, B, C...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, [
                alunoController.text.trim(),
                turmaController.text.trim(),
                respostasController.text,
              ]);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    alunoController.dispose();
    turmaController.dispose();
    respostasController.dispose();
    if (respostasNovas == null) {
      return;
    }
    if (respostasNovas[0].isEmpty || respostasNovas[1].isEmpty) {
      _notificar('Informe aluno e turma para salvar a correção.');
      return;
    }

    final respostas = respostasNovas[2]
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-E0-9]'), ' ')
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .take(registro.totalQuestoes)
        .toList(growable: false);
    var acertos = 0;
    for (var index = 0; index < registro.totalQuestoes; index++) {
      if (index < respostas.length &&
          index < registro.gabarito.length &&
          respostas[index] == registro.gabarito[index]) {
        acertos++;
      }
    }
    final updated = registro.copyWith(
      aluno: respostasNovas[0],
      turma: respostasNovas[1],
      respostas: List<String>.generate(
        registro.totalQuestoes,
        (index) => index < respostas.length ? respostas[index] : '',
      ),
      acertos: acertos,
      erros: registro.totalQuestoes - acertos,
    );
    try {
      await CorrecoesRepository.update(updated);
      await _carregarDados();
      _notificar('Correção atualizada.');
    } catch (error) {
      _notificar('Não foi possível atualizar a correção: $error');
    }
  }

  Future<void> _excluir(CorrecaoRegistro registro) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir correção'),
        content: Text(
          'Excluir o resultado de ${registro.aluno} na prova "${registro.prova}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true) {
      return;
    }
    try {
      await CorrecoesRepository.delete(registro.id);
      await _carregarDados();
      _notificar('Correção excluída.');
    } catch (error) {
      _notificar('Não foi possível excluir a correção: $error');
    }
  }

  Widget _filtroDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar o histórico de correções.'),
              const SizedBox(height: 8),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _carregarDados();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final registros = _filtradas;
    final media = registros.isEmpty
        ? 0.0
        : registros.fold<double>(0, (sum, item) => sum + item.percentual) /
            registros.length;
    final melhor = registros.isEmpty
        ? 0.0
        : registros
            .map((item) => item.percentual)
            .reduce((a, b) => a > b ? a : b);
    final menor = registros.isEmpty
        ? 0.0
        : registros
            .map((item) => item.percentual)
            .reduce((a, b) => a < b ? a : b);
    final duplicadas = _duplicadas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e histórico'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: _exportarCsv,
            icon: const Icon(Icons.table_chart_rounded),
          ),
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: _exportarPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14213D), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Desempenho real',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  registros.isEmpty
                      ? 'Nenhuma correção registrada'
                      : 'Média ${media.toStringAsFixed(0)}% • Melhor ${melhor.toStringAsFixed(0)}% • Menor ${menor.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${registros.length} correção(ões) no filtro atual',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _buscaController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Buscar aluno, turma, prova ou disciplina',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _filtroDropdown(
                  label: 'Turma',
                  value: _filtroTurma,
                  values: _opcoes([
                    ..._turmas.map((item) => item.nome),
                    ..._correcoes.map((item) => item.turma),
                  ]),
                  onChanged: (value) {
                    if (value != null) setState(() => _filtroTurma = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filtroDropdown(
                  label: 'Prova',
                  value: _filtroProva,
                  values:
                      _opcoes(_correcoes.map((item) => item.prova).toList()),
                  onChanged: (value) {
                    if (value != null) setState(() => _filtroProva = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _filtroDropdown(
                  label: 'Disciplina',
                  value: _filtroDisciplina,
                  values: _opcoes(
                    _correcoes.map((item) => item.disciplina).toList(),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _filtroDisciplina = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filtroDropdown(
                  label: 'Período',
                  value: _filtroPeriodo,
                  values: const [
                    'Todo o período',
                    'Últimos 30 dias',
                    'Últimos 90 dias',
                    'Este ano',
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _filtroPeriodo = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (registros.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Não há resultados reais para exibir. Corrija e salve um cartão para iniciar o histórico.',
                ),
              ),
            )
          else
            ...registros.map((registro) {
              final duplicada = duplicadas.contains(registro.chaveDuplicidade);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          registro.aluno,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${registro.turma} • ${registro.prova} • ${registro.disciplina}\n'
                          '${registro.acertos}/${registro.totalQuestoes} acertos • ${_dataHora(registro.dataCorrecao)}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${registro.percentual.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (duplicada)
                              const Text(
                                'Possível duplicata',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Ver respostas e gabarito'),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Respostas: ${registro.respostas.join(' ')}\n'
                              'Gabarito: ${registro.gabarito.join(' ')}',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _editar(registro),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                          TextButton.icon(
                            onPressed: () => _excluir(registro),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Excluir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
