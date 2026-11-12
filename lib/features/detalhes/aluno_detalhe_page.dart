import 'package:flutter/material.dart';

import '../provas/provas_page.dart';

class AlunoDetalhePage extends StatelessWidget {
  const AlunoDetalhePage({
    required this.aluno,
    required this.turma,
    required this.provas,
    super.key,
  });

  final String aluno;
  final String turma;
  final List<Prova> provas;

  @override
  Widget build(BuildContext context) {
    final totalProvas = provas.length;
    final desempenho = totalProvas == 0
        ? 0.0
        : (provas
                    .map((p) => p.totalQuestoes)
                    .reduce((a, b) => a + b) /
                totalProvas)
            .toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do aluno'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        aluno,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Turma: $turma',
                        style: const TextStyle(color: Color(0xFF475467)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                          label: 'Provas cadastradas', value: '$totalProvas'),
                      _StatRow(
                        label: 'Média de itens',
                        value: desempenho.toStringAsFixed(1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Provas disponíveis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (provas.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Nenhuma prova cadastrada para este aluno.'),
                  ),
                )
              else
                ...provas.map(
                  (prova) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prova.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Disciplina: ${prova.disciplina}'),
                          Text('Data: ${prova.data}'),
                          Text('Gabarito: ${prova.gabarito}'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF475467))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
