import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _turmasStorageKey = 'qrcode_prof_turmas';

class Turma {
  Turma({required this.nome, List<String>? alunos, String? id})
      : id = id ?? 'turma_${DateTime.now().microsecondsSinceEpoch}',
        alunos = alunos ?? <String>[];

  final String id;
  final String nome;
  final List<String> alunos;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'alunos': alunos,
      };

  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      id: json['id'] as String? ??
          'turma_${DateTime.now().microsecondsSinceEpoch}',
      nome: json['nome'] as String? ?? 'Turma',
      alunos: (json['alunos'] as List<dynamic>? ?? const <dynamic>[])
          .map((aluno) => aluno.toString())
          .toList(),
    );
  }
}

class TurmasRepository {
  static List<Turma> seedTurmas() {
    return [
      Turma(
        nome: '1º Ano A',
        alunos: ['Ana Ribeiro', 'Bruno Costa', 'Carla Souza'],
      ),
      Turma(
        nome: '2º Ano B',
        alunos: ['Davi Silva', 'Eduarda Lima'],
      ),
      Turma(
        nome: '3º Ano C',
        alunos: ['Fernanda Rocha', 'Gabriel Moraes', 'Helena Pinto'],
      ),
    ];
  }

  static Future<List<Turma>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_turmasStorageKey);

    if (raw == null || raw.isEmpty) {
      return seedTurmas();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return seedTurmas();
      }

      return decoded
          .map<Turma>((item) => Turma.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return seedTurmas();
    }
  }

  static Future<void> save(List<Turma> turmas) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(
      turmas.map((turma) => turma.toJson()).toList(),
    );
    await prefs.setString(_turmasStorageKey, serialized);
  }
}

class TurmasPage extends StatefulWidget {
  const TurmasPage({
    super.key,
    this.onChanged,
  });

  final VoidCallback? onChanged;

  @override
  State<TurmasPage> createState() => _TurmasPageState();
}

class _TurmasPageState extends State<TurmasPage> {
  final List<Turma> _turmas = <Turma>[];
  final TextEditingController _buscaController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarTurmas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<Turma> get _turmasFiltradas {
    final termo = _buscaController.text.trim().toLowerCase();
    final turmasOrdenadas = [..._turmas]..sort((a, b) {
      final nomeComparacao = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      if (nomeComparacao != 0) {
        return nomeComparacao;
      }
      return b.alunos.length.compareTo(a.alunos.length);
    });

    if (termo.isEmpty) {
      return turmasOrdenadas;
    }

    return turmasOrdenadas.where((turma) {
      final nomeMatch = turma.nome.toLowerCase().contains(termo);
      final alunoMatch = turma.alunos.any(
        (aluno) => aluno.toLowerCase().contains(termo),
      );
      return nomeMatch || alunoMatch;
    }).toList();
  }

  int get _totalAlunos =>
      _turmas.fold<int>(0, (sum, turma) => sum + turma.alunos.length);

  Future<void> _carregarTurmas() async {
    final turmas = await TurmasRepository.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _turmas
        ..clear()
        ..addAll(turmas);
      _isLoading = false;
    });
  }

  Future<void> _persistTurmas() async {
    await TurmasRepository.save(_turmas);
  }

  Future<void> _adicionarTurma() async {
    final controller = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova turma'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da turma',
            hintText: 'Ex.: 1º Ano A',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (nome == null || nome.isEmpty) {
      return;
    }

    setState(() => _turmas.add(Turma(nome: nome, alunos: const <String>[])));
    await _persistTurmas();
    widget.onChanged?.call();
  }

  Future<void> _adicionarAluno(Turma turma) async {
    final controller = TextEditingController();
    final nomeAluno = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar aluno à turma ${turma.nome}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do aluno',
            hintText: 'Ex.: Julia Martins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (nomeAluno == null || nomeAluno.isEmpty) {
      return;
    }

    setState(() {
      final index = _turmas.indexWhere((item) => item.id == turma.id);
      if (index >= 0) {
        final alunosAtualizados = [..._turmas[index].alunos, nomeAluno];
        _turmas[index] = Turma(
          id: _turmas[index].id,
          nome: _turmas[index].nome,
          alunos: alunosAtualizados,
        );
      }
    });
    await _persistTurmas();
    widget.onChanged?.call();
  }

  Future<void> _editarAluno(Turma turma, String nomeAntigo) async {
    final controller = TextEditingController(text: nomeAntigo);
    final nomeAtualizado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar aluno'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do aluno',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (nomeAtualizado == null || nomeAtualizado.isEmpty) {
      return;
    }

    setState(() {
      final index = _turmas.indexWhere((item) => item.id == turma.id);
      if (index < 0) {
        return;
      }

      final alunos = [..._turmas[index].alunos];
      final posicao = alunos.indexOf(nomeAntigo);
      if (posicao >= 0) {
        alunos[posicao] = nomeAtualizado;
      }
      _turmas[index] = Turma(
        id: _turmas[index].id,
        nome: _turmas[index].nome,
        alunos: alunos,
      );
    });
    await _persistTurmas();
    widget.onChanged?.call();
  }

  Future<void> _removerAluno(Turma turma, String nomeAluno) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover aluno'),
        content: Text.rich(
          TextSpan(
            text: 'Deseja remover o aluno ',
            children: [
              TextSpan(
                text: nomeAluno,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' desta turma?'),
            ],
          ),
        ),
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
      final index = _turmas.indexWhere((item) => item.id == turma.id);
      if (index >= 0) {
        final alunos = [..._turmas[index].alunos]
          ..removeWhere((aluno) => aluno == nomeAluno);
        _turmas[index] = Turma(
          id: _turmas[index].id,
          nome: _turmas[index].nome,
          alunos: alunos,
        );
      }
    });
    await _persistTurmas();
    widget.onChanged?.call();
  }

  Future<void> _renomearTurma(Turma turma) async {
    final controller = TextEditingController(text: turma.nome);
    final nomeAtualizado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear turma'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da turma',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (nomeAtualizado == null || nomeAtualizado.isEmpty) {
      return;
    }

    setState(() {
      final index = _turmas.indexWhere((item) => item.id == turma.id);
      if (index >= 0) {
        _turmas[index] = Turma(
          id: _turmas[index].id,
          nome: nomeAtualizado,
          alunos: _turmas[index].alunos,
        );
      }
    });
    await _persistTurmas();
    widget.onChanged?.call();
  }

  Future<void> _excluirTurma(Turma turma) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir turma'),
        content: Text('Deseja remover a turma "${turma.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado != true) {
      return;
    }

    setState(() {
      _turmas.removeWhere((item) => item.id == turma.id);
    });
    await _persistTurmas();
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

    final turmasFiltradas = _turmasFiltradas;

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
                      'Turmas e alunos',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _adicionarTurma,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nova turma'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Turmas',
                      value: '${_turmas.length}',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Alunos',
                      value: '$_totalAlunos',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Filtradas',
                      value: '${turmasFiltradas.length}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _buscaController,
                decoration: InputDecoration(
                  hintText: 'Buscar turma ou aluno',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _buscaController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: turmasFiltradas.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma turma ou aluno encontrado para a busca atual.',
                          style: TextStyle(color: Color(0xFF667085)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: turmasFiltradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final turma = turmasFiltradas[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor:
                                            Color(0xFFEAF1FF),
                                        foregroundColor:
                                            Color(0xFF2563EB),
                                        child: Icon(Icons.groups_rounded),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          turma.nome,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Adicionar aluno',
                                        onPressed: () => _adicionarAluno(turma),
                                        icon: const Icon(
                                          Icons.person_add_alt_1_rounded,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Ações da turma',
                                        onSelected: (value) {
                                          if (value == 'renomear') {
                                            _renomearTurma(turma);
                                          } else if (value == 'excluir') {
                                            _excluirTurma(turma);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'renomear',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded),
                                                SizedBox(width: 8),
                                                Text('Renomear turma'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'excluir',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded),
                                                SizedBox(width: 8),
                                                Text('Excluir turma'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${turma.alunos.length} aluno(s) cadastrado(s)',
                                          style: const TextStyle(
                                            color: Color(0xFF667085),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (turma.alunos.isNotEmpty)
                                        Text(
                                          turma.alunos.first,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (turma.alunos.isEmpty)
                                    const Text(
                                      'Ainda não há alunos nesta turma.',
                                      style:
                                          TextStyle(color: Color(0xFF98A2B3)),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: turma.alunos
                                          .map(
                                            (nome) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.person_rounded,
                                                    size: 18,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(nome),
                                                  const SizedBox(width: 8),
                                                  InkWell(
                                                    onTap: () => _editarAluno(
                                                        turma, nome),
                                                    child: const Icon(
                                                      Icons.edit_outlined,
                                                      size: 18,
                                                      color: Color(0xFF475467),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  InkWell(
                                                    onTap: () => _removerAluno(
                                                        turma, nome),
                                                    child: const Icon(
                                                      Icons.delete_outline_rounded,
                                                      size: 18,
                                                      color: Color(0xFFD92D20),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
