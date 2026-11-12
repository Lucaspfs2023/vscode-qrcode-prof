import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../provas/provas_page.dart';
import '../turmas/turmas_page.dart';
import 'card_pdf_export.dart';

class CartaoGeradorPage extends StatefulWidget {
  const CartaoGeradorPage({super.key});

  @override
  State<CartaoGeradorPage> createState() => _CartaoGeradorPageState();
}

class _CartaoGeradorPageState extends State<CartaoGeradorPage> {
  final TextEditingController _tituloController =
      TextEditingController(text: 'AV1 - Matemática');
  final TextEditingController _disciplinaController =
      TextEditingController(text: 'Matemática');
  final TextEditingController _respostasController =
      TextEditingController(text: 'A,B,C,D,E');

  List<Prova> _provas = const <Prova>[];
  List<Turma> _turmas = const <Turma>[];
  Prova? _provaSelecionada;
  String? _turmaSelecionada;
  String? _alunoSelecionado;
  String _payload = '';

  @override
  void initState() {
    super.initState();
    _carregarCadastros();
  }

  Future<void> _carregarCadastros() async {
    final provas = await ProvasRepository.load();
    final turmas = await TurmasRepository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _provas = provas;
      _turmas = turmas;
      _payload = '';
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _disciplinaController.dispose();
    _respostasController.dispose();
    super.dispose();
  }

  int get _numeroQuestoes => _provaSelecionada?.totalQuestoes ?? 0;

  List<String> _parseRespostas(String valor) {
    final lista = valor
        .replaceAll('|', ',')
        .replaceAll(';', ',')
        .replaceAll('\n', ',')
        .split(RegExp(r'[,\s]+'))
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .toList();

    final alternativas =
        lista.where((item) => RegExp(r'^[A-E]$').hasMatch(item)).toList();

    if (alternativas.isNotEmpty) {
      return alternativas;
    }

    return lista;
  }

  void _atualizarPayload() {
    final prova = _provaSelecionada;
    final turma = _turmaSelecionada;
    final aluno = _alunoSelecionado;
    if (prova == null || turma == null || aluno == null) {
      setState(() => _payload = '');
      return;
    }

    final respostas = _parseRespostas(_respostasController.text);
    final payload = jsonEncode({
      'schema': 'qrcode-prof.card',
      'version': 2,
      'provaId': prova.id,
      'titulo': prova.titulo,
      'disciplina': prova.disciplina,
      'data': prova.data,
      'aluno': aluno,
      'turma': turma,
      'respostas': respostas,
    });
    _tituloController.text = prova.titulo;
    _disciplinaController.text = prova.disciplina;
    setState(() => _payload = payload);
  }

  void _selecionarProva(Prova? prova) {
    if (prova == null) {
      return;
    }
    _provaSelecionada = prova;
    _tituloController.text = prova.titulo;
    _disciplinaController.text = prova.disciplina;
    _respostasController.text = prova.gabaritoPorQuestao.join(', ');
    setState(() {});
    _atualizarPayload();
  }

  void _selecionarTurma(String? turma) {
    setState(() {
      _turmaSelecionada = turma;
      _alunoSelecionado = null;
      _payload = '';
    });
  }

  void _selecionarAluno(String? aluno) {
    _alunoSelecionado = aluno;
    _atualizarPayload();
  }

  Future<void> _copiarPayload() async {
    await Clipboard.setData(ClipboardData(text: _payload));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payload do QRCode copiado.')),
      );
    }
  }

  Future<void> _exportarPdf() async {
    if (_payload.isEmpty) {
      return;
    }

    final nomeArquivo =
        ('${(_tituloController.text.trim().isEmpty ? 'cartao_resposta' : _tituloController.text.trim()).replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase()}_cartao.pdf')
            .replaceAll(RegExp(r'_+'), '_');

    final respostas = _parseRespostas(_respostasController.text);

    try {
      await exportCardPdf(
        titulo: _tituloController.text.trim(),
        disciplina: _disciplinaController.text.trim(),
        aluno: _alunoSelecionado!,
        turma: _turmaSelecionada!,
        respostas: respostas,
        quantidadeQuestoes: _numeroQuestoes,
        payload: _payload,
        filename: nomeArquivo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF salvo como $nomeArquivo')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar o PDF: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPayload = _payload.isNotEmpty;
    final respostas = _parseRespostas(_respostasController.text);
    final totalQuestoes = _numeroQuestoes;
    final linhas = List.generate(
      totalQuestoes,
      (index) {
        final resposta = index < respostas.length ? respostas[index] : '';
        return Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
            ),
            ...['A', 'B', 'C', 'D', 'E'].map((opcao) {
              final ativa = resposta == opcao;
              return Expanded(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ativa
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD1D5DB),
                      width: ativa ? 1.5 : 1,
                    ),
                    color: ativa ? const Color(0xFFE0F2FE) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      opcao,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: ativa ? FontWeight.bold : FontWeight.w500,
                        color: ativa
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar cartão-resposta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monte um cartão de prova com visual pronto para impressão e leitura por QRCode.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFormPanel()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildPreviewCard(linhas)),
                      ],
                    )
                  else ...[
                    _buildFormPanel(),
                    const SizedBox(height: 20),
                    _buildPreviewCard(linhas),
                  ],
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payload gerado',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: SelectableText(
                              _payload,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Escaneie esse QRCode no scanner do aplicativo para corrigir automaticamente.',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: _copiarPayload,
                                    icon: const Icon(Icons.copy_rounded),
                                    label: const Text('Copiar'),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: _exportarPdf,
                                    icon: const Icon(
                                        Icons.picture_as_pdf_rounded),
                                    label: const Text('Exportar PDF'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (hasPayload)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QR Code',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: QrImageView(
                                data: _payload,
                                version: QrVersions.auto,
                                size: 220,
                                gapless: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados da prova',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _provaSelecionada?.id,
              decoration: const InputDecoration(labelText: 'Prova cadastrada'),
              items: _provas
                  .map((prova) => DropdownMenuItem(
                        value: prova.id,
                        child: Text('${prova.titulo} • ${prova.disciplina}'),
                      ))
                  .toList(),
              onChanged: (id) {
                for (final prova in _provas) {
                  if (prova.id == id) {
                    _selecionarProva(prova);
                    break;
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _turmaSelecionada,
              decoration: const InputDecoration(labelText: 'Turma'),
              items: _turmas
                  .map((turma) => DropdownMenuItem(
                        value: turma.nome,
                        child: Text(turma.nome),
                      ))
                  .toList(),
              onChanged: _selecionarTurma,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_turmaSelecionada),
              initialValue: _alunoSelecionado,
              decoration: const InputDecoration(labelText: 'Aluno'),
              items: _turmas
                  .where((turma) => turma.nome == _turmaSelecionada)
                  .expand((turma) => turma.alunos)
                  .map((aluno) => DropdownMenuItem(
                        value: aluno,
                        child: Text(aluno),
                      ))
                  .toList(),
              onChanged: _selecionarAluno,
            ),
            const SizedBox(height: 12),
            if (_provaSelecionada == null)
              const Text('Cadastre ou selecione uma prova para continuar.')
            else
              Text(
                '${_provaSelecionada!.titulo} • ${_provaSelecionada!.disciplina}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            TextField(
              controller: _respostasController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Respostas',
                hintText: 'Ex.: A, B, C, D, E',
              ),
              onChanged: (_) => _atualizarPayload(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(List<Widget> linhas) {
    final titulo = _tituloController.text.trim().isNotEmpty
        ? _tituloController.text
        : 'Prova';
    final disciplina = _disciplinaController.text.trim().isNotEmpty
        ? _disciplinaController.text
        : 'Disciplina';
    final aluno = _alunoSelecionado ?? 'Selecione um aluno';
    final turma = _turmaSelecionada ?? 'Selecione uma turma';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 820),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          disciplina,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$aluno • $turma',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: QrImageView(
                      data: _payload,
                      version: QrVersions.auto,
                      size: 72,
                      gapless: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Cartão-resposta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            'Nº',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'A',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'B',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'C',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'D',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'E',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...linhas,
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Assinatura do aluno',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Data',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
