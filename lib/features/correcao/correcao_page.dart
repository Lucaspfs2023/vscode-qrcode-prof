import 'dart:convert';

import 'package:flutter/material.dart';

import 'correcao_repository.dart';
import '../provas/provas_page.dart';

class CorrecaoPage extends StatefulWidget {
  const CorrecaoPage({required this.codigo, super.key});

  final String codigo;

  @override
  State<CorrecaoPage> createState() => _CorrecaoPageState();
}

class _CorrecaoPageState extends State<CorrecaoPage> {
  List<Prova> _provas = const <Prova>[];
  String? _provaIdSelecionada;
  String? _turmaSelecionada;
  String? _alunoSelecionado;
  final Set<String> _salvosNestaSessao = <String>{};
  final Set<String> _salvando = <String>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProvas();
  }

  Future<void> _carregarProvas() async {
    final provas = await ProvasRepository.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _provas = provas;
      final provaId = _payloadData?['provaId']?.toString();
      if (provaId != null && provas.any((prova) => prova.id == provaId)) {
        _provaIdSelecionada = provaId;
      } else if (provaId == null) {
        final titulo = _tituloDoCartao;
        final disciplina = _disciplinaDoCartao;
        if (titulo != null && disciplina != null) {
          final matches = provas
              .where((prova) =>
                  prova.titulo == titulo && prova.disciplina == disciplina)
              .toList();
          if (matches.length == 1) {
            _provaIdSelecionada = matches.single.id;
          }
        }
      }

      _turmaSelecionada = _turmaDoCartao;
      _alunoSelecionado = _alunoDoCartao;
      _isLoading = false;
    });
  }

  Map<String, dynamic>? get _payloadData {
    try {
      final decoded = jsonDecode(widget.codigo);
      if (decoded is Map<String, dynamic> &&
          decoded['schema'] == 'qrcode-prof.card') {
        return decoded;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  List<String> get _partesPayloadLegado => _payloadData == null
      ? widget.codigo.split('|').map((item) => item.trim()).toList()
      : const <String>[];

  String? get _tituloDoCartao {
    final value = _payloadData?['titulo']?.toString();
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    return _partesPayloadLegado.length >= 5 ? _partesPayloadLegado[0] : null;
  }

  String? get _disciplinaDoCartao {
    final value = _payloadData?['disciplina']?.toString();
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    return _partesPayloadLegado.length >= 5 ? _partesPayloadLegado[1] : null;
  }

  String? get _alunoDoCartao {
    final value = _payloadData?['aluno']?.toString();
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (_partesPayloadLegado.length >= 5 &&
        _partesPayloadLegado[2].isNotEmpty) {
      return _partesPayloadLegado[2];
    }
    return null;
  }

  String? get _turmaDoCartao {
    final value = _payloadData?['turma']?.toString();
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (_partesPayloadLegado.length >= 5 &&
        _partesPayloadLegado[3].isNotEmpty) {
      return _partesPayloadLegado[3];
    }
    return null;
  }

  bool get _identificacaoNecessaria =>
      _alunoDoCartao == null || _turmaDoCartao == null;

  String? get _alunoConfirmado => _alunoDoCartao ?? _alunoSelecionado;

  String? get _turmaConfirmada => _turmaDoCartao ?? _turmaSelecionada;

  List<String> _normalizarLista(String entrada) {
    final trecho = entrada
        .replaceAll(RegExp(r'\[|\]|\(|\)'), '')
        .replaceAll('|', ',')
        .replaceAll(';', ',')
        .replaceAll('\n', ',')
        .replaceAll(RegExp(r'\s*[,;]\s*'), ',')
        .replaceAll(RegExp(r'\s+'), ' ');

    return trecho
        .split(',')
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .expand((item) => item.split(' '))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _extrairAlternativasDeBloco(String bloco) {
    final valor = bloco.trim();
    if (valor.isEmpty) {
      return const <String>[];
    }

    final segment = valor.toUpperCase();
    final tokens = segment
        .replaceAll(RegExp(r'[^A-E,;\s]'), ' ')
        .split(RegExp(r'[\s,;]+'))
        .map((item) => item.trim())
        .where((item) => RegExp(r'^[A-E]$').hasMatch(item))
        .toList();

    if (tokens.isNotEmpty) {
      return tokens;
    }

    final letrasIsoladas = RegExp(r'[A-E]')
        .allMatches(segment)
        .map((match) => match.group(0)!)
        .toList();

    if (letrasIsoladas.isNotEmpty &&
        !segment.contains(',') &&
        !segment.contains(';') &&
        !segment.contains('|') &&
        !segment.contains('\n') &&
        !segment.contains('\r')) {
      return letrasIsoladas;
    }

    return const <String>[];
  }

  List<String> _respostasCartaoParaProva(String codigo) {
    final respostasDoQr = _payloadData?['respostas'];
    if (respostasDoQr is List) {
      return respostasDoQr
          .map((item) => item.toString().trim().toUpperCase())
          .toList(growable: false);
    }

    final raw = codigo.trim();
    if (raw.isEmpty) {
      return const <String>[];
    }

    final blocos = raw.replaceAll(RegExp(r'\r?\n'), '|').split(RegExp(r'\||;'));

    if (blocos.length > 1) {
      for (final bloco in blocos.reversed) {
        final respostas = _extrairAlternativasDeBloco(bloco);
        if (respostas.isNotEmpty && respostas.length >= 2) {
          return respostas;
        }
      }

      final ultimaParte = blocos.last.trim();
      final respostasUltimaParte = _extrairAlternativasDeBloco(ultimaParte);
      if (respostasUltimaParte.isNotEmpty) {
        return respostasUltimaParte;
      }
    }

    final respostasDiretas = _extrairAlternativasDeBloco(raw);
    if (respostasDiretas.isNotEmpty) {
      return respostasDiretas;
    }

    final respostasPorTokens = _normalizarLista(raw);
    if (respostasPorTokens.isNotEmpty) {
      final somenteAlternativas = respostasPorTokens
          .where((item) => RegExp(r'^[A-E]$').hasMatch(item))
          .toList();
      if (somenteAlternativas.isNotEmpty) {
        return somenteAlternativas;
      }
    }

    final padraoQuestoes = RegExp(
      r'(?:Q|QUESTAO|ITEM)?\s*\d*\s*[:.=\-]?\s*([A-E])',
      caseSensitive: false,
    );
    final respostasPorQuestao = <String>[];
    for (final match in padraoQuestoes.allMatches(raw)) {
      final valor = match.group(1)?.trim().toUpperCase();
      if (valor != null && valor.isNotEmpty) {
        respostasPorQuestao.add(valor);
      }
    }
    if (respostasPorQuestao.isNotEmpty) {
      return respostasPorQuestao;
    }

    return _normalizarLista(raw);
  }

  List<String> _gabaritoDaProva(Prova prova) {
    if (prova.gabaritoPorQuestao.isNotEmpty) {
      return prova.gabaritoPorQuestao
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .map((item) =>
              item.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase())
          .toList(growable: false);
    }

    return _normalizarLista(prova.gabarito);
  }

  String _chaveResultado(_ResultadoCorrecao resultado) => resultado.prova.id;

  Future<void> _salvarResultado(_ResultadoCorrecao resultado) async {
    final chave = _chaveResultado(resultado);
    if (_salvosNestaSessao.contains(chave) || _salvando.contains(chave)) {
      return;
    }

    if (_alunoConfirmado == null || _turmaConfirmada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione o aluno e a turma antes de salvar.')),
      );
      return;
    }

    setState(() => _salvando.add(chave));
    try {
      final existentes = await CorrecoesRepository.load();
      final registro = CorrecaoRegistro.criar(
        provaId: resultado.prova.id,
        aluno: _alunoConfirmado!,
        turma: _turmaConfirmada!,
        prova: resultado.prova.titulo,
        disciplina: resultado.prova.disciplina,
        dataProva: resultado.prova.data,
        acertos: resultado.acertos,
        erros: resultado.erros,
        totalQuestoes: resultado.gabarito.length,
        respostas: resultado.detalhesQuestoes
            .map((item) => item.respostaAluno)
            .toList(growable: false),
        gabarito: resultado.gabarito,
      );
      final duplicada = existentes.any(
        (item) => item.chaveDuplicidade == registro.chaveDuplicidade,
      );
      if (duplicada) {
        if (!mounted) {
          return;
        }
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Possível cartão duplicado'),
            content: const Text(
              'Já existe uma correção com a mesma prova, aluno, turma e respostas. Deseja salvar outra tentativa mesmo assim?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salvar mesmo assim'),
              ),
            ],
          ),
        );
        if (confirmar != true) {
          return;
        }
      }
      await CorrecoesRepository.add(registro);

      if (!mounted) {
        return;
      }
      setState(() => _salvosNestaSessao.add(chave));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correção salva no histórico real.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a correção: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando.remove(chave));
      }
    }
  }

  _ResultadoCorrecao? _resultadoPara(Prova prova) {
    final respostasCartao = _respostasCartaoParaProva(widget.codigo);
    final gabarito = _gabaritoDaProva(prova);
    final totalQuestoes = gabarito.length;
    if (totalQuestoes == 0) {
      return null;
    }

    final itensParaComparar = respostasCartao.length > totalQuestoes
        ? respostasCartao.sublist(0, totalQuestoes)
        : respostasCartao;

    final detalhesQuestoes = <_DetalheQuestao>[];
    var acertos = 0;
    for (var i = 0; i < gabarito.length; i++) {
      final resposta = i < itensParaComparar.length ? itensParaComparar[i] : '';
      final esperado = gabarito[i];
      final acertou = resposta == esperado;
      if (acertou) {
        acertos++;
      }
      detalhesQuestoes.add(
        _DetalheQuestao(
          numero: i + 1,
          respostaAluno: resposta,
          respostaEsperada: esperado,
          acertou: acertou,
        ),
      );
    }

    final erros = totalQuestoes - acertos;
    final percentual = (acertos / totalQuestoes) * 100;

    final base = itensParaComparar.isEmpty ? 0 : itensParaComparar.length;

    return _ResultadoCorrecao(
      prova: prova,
      acertos: acertos,
      erros: erros,
      percentual: percentual,
      respostasCartao: itensParaComparar,
      gabarito: gabarito,
      quantidadeLida: base,
      detalhesQuestoes: detalhesQuestoes,
    );
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

    Prova? provaSelecionada;
    for (final prova in _provas) {
      if (prova.id == _provaIdSelecionada) {
        provaSelecionada = prova;
        break;
      }
    }
    final resultado =
        provaSelecionada == null ? null : _resultadoPara(provaSelecionada);
    final resultados =
        resultado == null ? const <_ResultadoCorrecao>[] : [resultado];
    final melhorResultado = resultado;
    final provaQrId = _payloadData?['provaId']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Correção do cartão'),
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
                      Text(
                        'Cartão lido',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.codigo,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
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
                        'Vincular à prova',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _provaIdSelecionada,
                        decoration:
                            const InputDecoration(labelText: 'Prova correta'),
                        items: _provas
                            .map((prova) => DropdownMenuItem(
                                  value: prova.id,
                                  child: Text(
                                    '${prova.titulo} • ${prova.disciplina}',
                                  ),
                                ))
                            .toList(),
                        onChanged: (id) {
                          setState(() => _provaIdSelecionada = id);
                        },
                      ),
                      if (provaQrId != null &&
                          !_provas.any((prova) => prova.id == provaQrId)) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'O identificador do QR não corresponde a uma prova cadastrada. Selecione a prova correta para continuar.',
                          style: TextStyle(color: Color(0xFFB45309)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_identificacaoNecessaria)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirmar identificação',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'O QR não informa aluno ou turma. Preencha os dados antes de salvar a correção.',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _turmaDoCartao ?? _turmaSelecionada,
                          decoration: const InputDecoration(labelText: 'Turma'),
                          onChanged: (value) => setState(
                            () => _turmaSelecionada = value.trim(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _alunoDoCartao ?? _alunoSelecionado,
                          decoration: const InputDecoration(labelText: 'Aluno'),
                          onChanged: (value) => setState(
                            () => _alunoSelecionado = value.trim(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF16A34A),
                    ),
                    title: Text(_alunoDoCartao!),
                    subtitle: Text(_turmaDoCartao!),
                    trailing: const Text('Dados do QR'),
                  ),
                ),
              const SizedBox(height: 12),
              if (melhorResultado == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Selecione a prova correta para calcular o resultado.',
                    ),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resultado da prova selecionada',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Prova: ${melhorResultado.prova.titulo}'),
                        Text('Disciplina: ${melhorResultado.prova.disciplina}'),
                        Text(
                            'Questoes lidas: ${melhorResultado.quantidadeLida}'),
                        Text('Acertos: ${melhorResultado.acertos}'),
                        Text('Erros: ${melhorResultado.erros}'),
                        Text(
                          'Percentual: ${melhorResultado.percentual.toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Detalhamento da correção',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...resultados.map((resultado) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resultado.prova.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Questoes lidas: ${resultado.quantidadeLida}'),
                          Text('Acertos: ${resultado.acertos}'),
                          Text('Erros: ${resultado.erros}'),
                          Text(
                            'Percentual: ${resultado.percentual.toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Detalhamento por questão',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...resultado.detalhesQuestoes.map((detalhe) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: detalhe.acertou
                                    ? const Color(0xFFE8F7EE)
                                    : const Color(0xFFFDECEC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q${detalhe.numero}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Aluno: ${detalhe.respostaAluno.isEmpty ? '—' : detalhe.respostaAluno} | Esperado: ${detalhe.respostaEsperada}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    detalhe.acertou
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 18,
                                    color: detalhe.acertou
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _alunoConfirmado == null ||
                                      _turmaConfirmada == null ||
                                      _salvosNestaSessao.contains(
                                          _chaveResultado(resultado)) ||
                                      _salvando.contains(
                                        _chaveResultado(resultado),
                                      )
                                  ? null
                                  : () => _salvarResultado(resultado),
                              icon: Icon(
                                _salvosNestaSessao
                                        .contains(_chaveResultado(resultado))
                                    ? Icons.check_rounded
                                    : _salvando.contains(
                                        _chaveResultado(resultado),
                                      )
                                        ? Icons.hourglass_top_rounded
                                        : Icons.save_rounded,
                              ),
                              label: Text(
                                _salvosNestaSessao
                                        .contains(_chaveResultado(resultado))
                                    ? 'Salvo no histórico'
                                    : _salvando.contains(
                                        _chaveResultado(resultado),
                                      )
                                        ? 'Salvando...'
                                        : 'Salvar correção',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalheQuestao {
  _DetalheQuestao({
    required this.numero,
    required this.respostaAluno,
    required this.respostaEsperada,
    required this.acertou,
  });

  final int numero;
  final String respostaAluno;
  final String respostaEsperada;
  final bool acertou;
}

class _ResultadoCorrecao {
  _ResultadoCorrecao({
    required this.prova,
    required this.acertos,
    required this.erros,
    required this.percentual,
    required this.respostasCartao,
    required this.gabarito,
    required this.quantidadeLida,
    required this.detalhesQuestoes,
  });

  final Prova prova;
  final int acertos;
  final int erros;
  final double percentual;
  final List<String> respostasCartao;
  final List<String> gabarito;
  final int quantidadeLida;
  final List<_DetalheQuestao> detalhesQuestoes;
}
