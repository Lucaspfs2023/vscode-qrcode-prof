import 'package:flutter/material.dart';

import '../backup/backup_restore_dialog.dart';
import '../correcao/correcao_repository.dart';
import '../provas/provas_page.dart';
import '../relatorios/csv_export.dart';
import '../relatorios/pdf_export.dart';
import '../relatorios/relatorios_page.dart';
import '../scanner/scanner_page.dart';
import '../turmas/turmas_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;
  int _adminRefreshToken = 0;
  int _reportsRefreshToken = 0;
  int turmasCount = 0;
  int alunosCount = 0;
  int provasCount = 0;
  int correcoesCount = 0;
  double mediaGeral = 0;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    final turmas = await TurmasRepository.load();
    final provas = await ProvasRepository.load();
    final correcoes = await CorrecoesRepository.load();

    if (!mounted) {
      return;
    }

    final mediaCalculada = correcoes.isEmpty
        ? 0.0
        : correcoes.fold<double>(
              0,
              (sum, registro) => sum + registro.percentual,
            ) /
            correcoes.length;

    setState(() {
      turmasCount = turmas.length;
      alunosCount =
          turmas.fold<int>(0, (total, turma) => total + turma.alunos.length);
      provasCount = provas.length;
      correcoesCount = correcoes.length;
      mediaGeral = mediaCalculada;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(
        turmasCount: turmasCount,
        alunosCount: alunosCount,
        provasCount: provasCount,
        correcoesCount: correcoesCount,
        mediaGeral: mediaGeral,
        onOpenScanner: () => setState(() => selectedIndex = 3),
        onOpenTurmas: () => setState(() => selectedIndex = 1),
        onOpenProvas: () => setState(() => selectedIndex = 2),
        onOpenAdmin: () => setState(() {
          selectedIndex = 5;
          _adminRefreshToken++;
        }),
      ),
      TurmasPage(onChanged: _carregarResumo),
      ProvasPage(onChanged: _carregarResumo),
      const ScannerPage(),
      RelatoriosPage(key: ValueKey(_reportsRefreshToken)),
      AdminPanelPage(
        key: ValueKey(_adminRefreshToken),
        onDataChanged: _carregarResumo,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text(
              'QRCODE PROF',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            selectedIndex = value;
            if (value == 4) {
              _reportsRefreshToken++;
            }
            if (value == 5) {
              _adminRefreshToken++;
            }
          });
          if (value == 0) {
            _carregarResumo();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Turmas',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Provas',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner_rounded),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.turmasCount,
    required this.alunosCount,
    required this.provasCount,
    required this.correcoesCount,
    required this.mediaGeral,
    required this.onOpenScanner,
    required this.onOpenTurmas,
    required this.onOpenProvas,
    required this.onOpenAdmin,
  });

  final int turmasCount;
  final int alunosCount;
  final int provasCount;
  final int correcoesCount;
  final double mediaGeral;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenTurmas;
  final VoidCallback onOpenProvas;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E2563EB),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Painel em destaque',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Olá, professor!',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                'Suas avaliações em um só lugar.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFFBBF7D0), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    correcoesCount == 0
                        ? 'Nenhuma correção registrada'
                        : 'Média real ${mediaGeral.toStringAsFixed(0)}% • $correcoesCount correção(ões)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'QRCODE PROF • Gestão e correção de avaliações',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Resumo operacional',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Média geral',
                value: correcoesCount == 0
                    ? '—'
                    : '${mediaGeral.toStringAsFixed(0)}%',
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Turmas',
                value: turmasCount.toString(),
                icon: Icons.groups_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Alunos',
                value: alunosCount.toString(),
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Provas',
                value: provasCount.toString(),
                icon: Icons.assignment_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Acesso rápido',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _QuickAction(
          icon: Icons.groups_rounded,
          title: 'Gerenciar turmas',
          subtitle: 'Organize escolas e alunos',
          accent: const Color(0xFFDBEAFE),
          onTap: onOpenTurmas,
        ),
        _QuickAction(
          icon: Icons.add_box_rounded,
          title: 'Criar avaliação',
          subtitle: 'Configure questões e gabarito',
          accent: const Color(0xFFDCFCE7),
          onTap: onOpenProvas,
        ),
        _QuickAction(
          icon: Icons.document_scanner_rounded,
          title: 'Ler cartão-resposta',
          subtitle: 'Inicie uma leitura pelo scanner',
          accent: const Color(0xFFFDE68A),
          onTap: onOpenScanner,
        ),
        _QuickAction(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Painel administrativo',
          subtitle: 'Filtros por disciplina e período',
          accent: const Color(0xFFE9D5FF),
          onTap: onOpenAdmin,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Color(0xFF667085))),
          ],
        ),
      ),
    );
  }
}

class _AlunoRendimento {
  const _AlunoRendimento({
    required this.nome,
    required this.turma,
    required this.percentual,
    required this.correcoes,
  });

  final String nome;
  final String turma;
  final double percentual;
  final int correcoes;
}

class _TurmaRendimento {
  const _TurmaRendimento({
    required this.nome,
    required this.percentual,
    required this.alunos,
    required this.correcoes,
  });

  final String nome;
  final double percentual;
  final int alunos;
  final int correcoes;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF0F172A),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({
    super.key,
    this.onDataChanged,
  });

  final VoidCallback? onDataChanged;

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  List<Turma> _turmas = const <Turma>[];
  List<Prova> _provas = const <Prova>[];
  List<CorrecaoRegistro> _historico = const <CorrecaoRegistro>[];
  String _filtroDisciplina = 'Todas';
  String _filtroTurma = 'Todas';
  String _filtroPeriodo = 'Todo o período';
  String _filtroStatus = 'Todos';
  String _termoBusca = '';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final turmas = await TurmasRepository.load();
      final provas = await ProvasRepository.load();
      final historico = await CorrecoesRepository.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _turmas = turmas;
        _provas = provas;
        _historico = historico;
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

  Future<void> _abrirBackup() async {
    final restaurado = await showDialog<bool>(
      context: context,
      builder: (context) => const BackupRestoreDialog(),
    );
    if (restaurado == true) {
      await _carregarDados();
      widget.onDataChanged?.call();
    }
  }

  DateTime? _parseData(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'Sem data') {
      return null;
    }

    final normalizado = raw.trim();
    final partes =
        normalizado.replaceAll('.', '-').replaceAll('/', '-').split('-');
    if (partes.length == 3 && partes[0].length == 2) {
      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final ano = int.tryParse(partes[2]);
      if (dia != null && mes != null && ano != null) {
        return DateTime(ano, mes, dia);
      }
    }

    try {
      final parsed = DateTime.parse(normalizado);
      if (parsed.year > 1900) {
        return parsed;
      }
    } catch (_) {}

    return null;
  }

  String _statusDaProva(Prova prova) {
    return _statusPorData(prova.data);
  }

  String _statusPorData(String rawData) {
    final dataProva = _parseData(rawData);
    if (dataProva == null) {
      return 'Sem data';
    }

    final diff = DateTime.now().difference(dataProva).inDays;
    if (diff <= 30) {
      return 'No prazo';
    }
    if (diff <= 90) {
      return 'Em revisão';
    }
    return 'Acompanhamento';
  }

  List<String> get _disciplinas {
    final disciplinas =
        _provas.map((prova) => prova.disciplina).toSet().toList();
    disciplinas.sort();
    return ['Todas', ...disciplinas];
  }

  List<String> get _turmasAtivas {
    final turmas = _turmas.map((turma) => turma.nome).toSet().toList();
    turmas.sort();
    return ['Todas', ...turmas];
  }

  List<_TurmaRendimento> get _rendimentoTurmas {
    final grupos = <String, List<CorrecaoRegistro>>{};
    for (final registro in _correcoesFiltradas) {
      grupos
          .putIfAbsent(registro.turma, () => <CorrecaoRegistro>[])
          .add(registro);
    }

    if (grupos.isEmpty) {
      return const <_TurmaRendimento>[];
    }

    final lista = grupos.entries.map((entry) {
      final registros = entry.value;
      final media = registros.fold<double>(
            0,
            (soma, registro) => soma + registro.percentual,
          ) /
          registros.length;
      final alunos = registros
          .where((registro) => registro.aluno != 'Não identificado')
          .map((registro) => registro.aluno)
          .toSet()
          .length;
      return _TurmaRendimento(
        nome: entry.key,
        percentual: media,
        alunos: alunos,
        correcoes: registros.length,
      );
    }).toList();

    lista.sort((a, b) => b.percentual.compareTo(a.percentual));
    return lista;
  }

  List<_AlunoRendimento> get _topAlunos {
    final grupos = <String, List<CorrecaoRegistro>>{};
    for (final registro in _correcoesFiltradas) {
      if (registro.aluno == 'Não identificado') {
        continue;
      }
      final chave = '${registro.turma}\u0000${registro.aluno}';
      grupos.putIfAbsent(chave, () => <CorrecaoRegistro>[]).add(registro);
    }

    final alunos = grupos.entries.map((entry) {
      final partes = entry.key.split('\u0000');
      final registros = entry.value;
      final media = registros.fold<double>(
            0,
            (soma, registro) => soma + registro.percentual,
          ) /
          registros.length;
      return _AlunoRendimento(
        nome: partes.last,
        turma: partes.first,
        percentual: media,
        correcoes: registros.length,
      );
    }).toList();

    alunos.sort((a, b) => b.percentual.compareTo(a.percentual));
    return alunos;
  }

  List<CorrecaoRegistro> get _correcoesFiltradas {
    final agora = DateTime.now();
    final termo = _termoBusca.trim().toLowerCase();
    return _historico.where((registro) {
      final turmaOk = _filtroTurma == 'Todas' || registro.turma == _filtroTurma;
      final disciplinaOk = _filtroDisciplina == 'Todas' ||
          registro.disciplina == _filtroDisciplina;
      final buscaOk = termo.isEmpty ||
          registro.prova.toLowerCase().contains(termo) ||
          registro.disciplina.toLowerCase().contains(termo);
      final dataProva = _parseData(registro.dataProva);
      var periodoOk = true;
      switch (_filtroPeriodo) {
        case 'Últimos 30 dias':
          periodoOk =
              dataProva == null || agora.difference(dataProva).inDays <= 30;
          break;
        case 'Últimos 90 dias':
          periodoOk =
              dataProva == null || agora.difference(dataProva).inDays <= 90;
          break;
        case 'Este ano':
          periodoOk = dataProva == null || dataProva.year == agora.year;
          break;
      }

      final status = _statusPorData(registro.dataProva);
      final statusOk = _filtroStatus == 'Todos' || _filtroStatus == status;
      return turmaOk && disciplinaOk && buscaOk && periodoOk && statusOk;
    }).toList()
      ..sort((a, b) => b.dataCorrecao.compareTo(a.dataCorrecao));
  }

  List<Prova> get _provasFiltradas {
    final agora = DateTime.now();
    final termo = _termoBusca.trim().toLowerCase();

    return _provas.where((prova) {
      final disciplinaOk =
          _filtroDisciplina == 'Todas' || prova.disciplina == _filtroDisciplina;
      final buscaOk = termo.isEmpty ||
          prova.titulo.toLowerCase().contains(termo) ||
          prova.disciplina.toLowerCase().contains(termo);

      bool periodoOk = true;
      final dataProva = _parseData(prova.data);
      switch (_filtroPeriodo) {
        case 'Últimos 30 dias':
          periodoOk =
              dataProva == null || agora.difference(dataProva).inDays <= 30;
          break;
        case 'Últimos 90 dias':
          periodoOk =
              dataProva == null || agora.difference(dataProva).inDays <= 90;
          break;
        case 'Este ano':
          periodoOk = dataProva == null || dataProva.year == agora.year;
          break;
        default:
          periodoOk = true;
      }

      bool statusOk = true;
      final statusProva = _statusDaProva(prova);
      switch (_filtroStatus) {
        case 'Sem data':
          statusOk = statusProva == 'Sem data';
          break;
        case 'No prazo':
          statusOk = statusProva == 'No prazo';
          break;
        case 'Em revisão':
          statusOk = statusProva == 'Em revisão';
          break;
        case 'Acompanhamento':
          statusOk = statusProva == 'Acompanhamento';
          break;
        default:
          statusOk = true;
      }

      return disciplinaOk && buscaOk && periodoOk && statusOk;
    }).toList();
  }

  List<Turma> get _turmasFiltradas => _filtroTurma == 'Todas'
      ? _turmas
      : _turmas.where((turma) => turma.nome == _filtroTurma).toList();

  int get _totalAlunos =>
      _turmasFiltradas.fold<int>(0, (sum, turma) => sum + turma.alunos.length);

  double _mediaDisciplina(String disciplina) {
    final registros = _correcoesFiltradas
        .where((registro) => registro.disciplina == disciplina)
        .toList();
    if (registros.isEmpty) {
      return 0;
    }
    return registros.fold<double>(
          0,
          (soma, registro) => soma + registro.percentual,
        ) /
        registros.length;
  }

  String _dataHora(DateTime data) {
    final local = data.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _csvAdministrativo(List<CorrecaoRegistro> registros) {
    final linhas = <List<String>>[
      const [
        'Data da correção',
        'Aluno',
        'Turma',
        'Disciplina',
        'Prova',
        'Data da prova',
        'Acertos',
        'Erros',
        'Total de questões',
        'Aproveitamento',
        'Respostas',
        'Gabarito',
      ],
      ...registros.map((registro) {
        return [
          _dataHora(registro.dataCorrecao),
          registro.aluno,
          registro.turma,
          registro.disciplina,
          registro.prova,
          registro.dataProva,
          '${registro.acertos}',
          '${registro.erros}',
          '${registro.totalQuestoes}',
          '${registro.percentual.toStringAsFixed(1)}%',
          registro.respostas.join(' '),
          registro.gabarito.join(' '),
        ];
      }),
    ];

    return '\uFEFF${linhas.map((linha) => linha.map((valor) => '"${valor.replaceAll('"', '""')}"').join(',')).join('\n')}';
  }

  List<Map<String, dynamic>> _linhasPdfAdministrativo(
      List<CorrecaoRegistro> registros) {
    return registros.map((registro) {
      return {
        'Data da correção': _dataHora(registro.dataCorrecao),
        'Aluno': registro.aluno,
        'Turma': registro.turma,
        'Disciplina': registro.disciplina,
        'Prova': registro.prova,
        'Data da prova': registro.dataProva,
        'Acertos': '${registro.acertos}',
        'Erros': '${registro.erros}',
        'Questões': '${registro.totalQuestoes}',
        'Aproveitamento': '${registro.percentual.toStringAsFixed(1)}%',
        'Respostas': registro.respostas.join(' '),
        'Gabarito': registro.gabarito.join(' '),
      };
    }).toList();
  }

  Map<String, String> _resumoPdfAdministrativo(
      List<CorrecaoRegistro> registros) {
    final percentuais =
        registros.map((registro) => registro.percentual).toList();
    final media = percentuais.isEmpty
        ? 0.0
        : percentuais.reduce((a, b) => a + b) / percentuais.length;
    final melhor =
        percentuais.isEmpty ? 0.0 : percentuais.reduce((a, b) => a > b ? a : b);
    final alunos = registros
        .where((registro) => registro.aluno != 'Não identificado')
        .map((registro) => '${registro.turma}\u0000${registro.aluno}')
        .toSet()
        .length;
    return {
      'Correções': '${registros.length}',
      'Alunos avaliados': '$alunos',
      'Média geral': '${media.toStringAsFixed(1)}%',
      'Melhor resultado': '${melhor.toStringAsFixed(1)}%',
    };
  }

  String _nomeArquivoExportacao(String tipoArquivo, {String? prefixo}) {
    final agora = DateTime.now();
    final disciplina = _filtroDisciplina == 'Todas'
        ? 'todas-disciplinas'
        : _filtroDisciplina
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'-+'), '-')
            .replaceAll(RegExp(r'^-|-$'), '');
    final turma = _filtroTurma == 'Todas'
        ? 'todas-turmas'
        : _filtroTurma
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'-+'), '-')
            .replaceAll(RegExp(r'^-|-$'), '');
    final data =
        '${agora.year.toString().padLeft(4, '0')}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}';
    final hora =
        '${agora.hour.toString().padLeft(2, '0')}-${agora.minute.toString().padLeft(2, '0')}';
    final base = prefixo ?? 'qrcode-prof';
    return '$base-$tipoArquivo-$disciplina-$turma-$data-$hora';
  }

  Future<void> _exportarAdminCsv() async {
    final registros = _correcoesFiltradas;
    if (registros.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Nenhuma correção no histórico para exportar em CSV.')),
      );
      return;
    }

    final csv = _csvAdministrativo(registros);
    final filename = '${_nomeArquivoExportacao('painel-admin')}.csv';
    try {
      await exportCsv(csv, filename);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar o CSV: $error')),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV do painel exportado: $filename')),
    );
  }

  Future<void> _exportarAdminPdf() async {
    final registros = _correcoesFiltradas;
    if (registros.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Nenhuma correção no histórico para exportar em PDF.')),
      );
      return;
    }

    final rows = _linhasPdfAdministrativo(registros);
    final filename = '${_nomeArquivoExportacao('painel-admin')}.pdf';
    try {
      await exportPdf(
        rows,
        filename,
        title: 'Painel executivo de desempenho',
        subtitle:
            'Resultados reais de correções salvas • Filtros: $_filtroDisciplina / $_filtroTurma / $_filtroPeriodo',
        summary: _resumoPdfAdministrativo(registros),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar o PDF: $error')),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF do painel exportado: $filename')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Não foi possível carregar o histórico de correções.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _loadError = null;
                    });
                    _carregarDados();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final provasFiltradas = _provasFiltradas;
    final totalProvas = provasFiltradas.length;
    final correcoesFiltradas = _correcoesFiltradas;
    final totalCorrecoes = correcoesFiltradas.length;
    final mediaGeral = correcoesFiltradas.isEmpty
        ? 0.0
        : correcoesFiltradas.fold<double>(
              0,
              (sum, registro) => sum + registro.percentual,
            ) /
            correcoesFiltradas.length;

    final disciplinasComResultados = correcoesFiltradas
        .map((registro) => registro.disciplina)
        .toSet()
        .toList()
      ..sort();
    final resumoDisciplinas = disciplinasComResultados.map((disciplina) {
      final correcoesDaDisciplina = correcoesFiltradas
          .where((registro) => registro.disciplina == disciplina)
          .length;
      return {
        'disciplina': disciplina,
        'media': _mediaDisciplina(disciplina),
        'correcoes': correcoesDaDisciplina,
      };
    }).toList();

    resumoDisciplinas.sort(
      (a, b) => (b['media'] as double).compareTo(a['media'] as double),
    );

    final provasRecentes = [...provasFiltradas]..sort((a, b) {
        final dataA = _parseData(a.data);
        final dataB = _parseData(b.data);
        if (dataA == null && dataB == null) {
          return a.titulo.compareTo(b.titulo);
        }
        if (dataA == null) return 1;
        if (dataB == null) return -1;
        return dataB.compareTo(dataA);
      });

    final turmasAtivas = _turmasFiltradas;
    final provasNoPrazo = provasFiltradas
        .where((prova) => _statusDaProva(prova) == 'No prazo')
        .length;
    final provasEmRevisao = provasFiltradas
        .where((prova) => _statusDaProva(prova) == 'Em revisão')
        .length;
    final disciplinaTop = resumoDisciplinas.isEmpty
        ? 'Sem dados'
        : resumoDisciplinas.first['disciplina'] as String;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Painel administrativo',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Exportar CSV do painel',
                    onPressed: _exportarAdminCsv,
                    icon: const Icon(Icons.table_chart_rounded),
                  ),
                  IconButton(
                    tooltip: 'Exportar PDF do painel',
                    onPressed: _exportarAdminPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                  ),
                  IconButton(
                    tooltip: 'Backup e restauração',
                    onPressed: _abrirBackup,
                    icon: const Icon(Icons.backup_rounded),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Operação',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo executivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      totalCorrecoes == 0
                          ? 'Sem correções registradas'
                          : '${mediaGeral.toStringAsFixed(0)}% de aproveitamento real',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalCorrecoes correção(ões) real(is) • $totalProvas provas cadastradas • $provasNoPrazo no prazo • $provasEmRevisao em revisão',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Top disciplina: $disciplinaTop',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Turmas',
                      value: '${turmasAtivas.length}',
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Alunos',
                      value: '$_totalAlunos',
                      icon: Icons.person_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Provas',
                      value: '${provasFiltradas.length}',
                      icon: Icons.assignment_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Média',
                      value: totalCorrecoes == 0
                          ? '—'
                          : '${mediaGeral.toStringAsFixed(0)}%',
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros operacionais',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => setState(() => _termoBusca = value),
                      decoration: const InputDecoration(
                        labelText: 'Buscar prova ou disciplina',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtroDisciplina,
                            decoration: const InputDecoration(
                              labelText: 'Disciplina',
                              border: OutlineInputBorder(),
                            ),
                            items: _disciplinas
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _filtroDisciplina = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtroTurma,
                            decoration: const InputDecoration(
                              labelText: 'Turma',
                              border: OutlineInputBorder(),
                            ),
                            items: _turmasAtivas
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _filtroTurma = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtroPeriodo,
                            decoration: const InputDecoration(
                              labelText: 'Período',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              'Todo o período',
                              'Últimos 30 dias',
                              'Últimos 90 dias',
                              'Este ano',
                            ]
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _filtroPeriodo = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _filtroStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Todos', child: Text('Todos')),
                              DropdownMenuItem(
                                  value: 'No prazo', child: Text('No prazo')),
                              DropdownMenuItem(
                                  value: 'Em revisão',
                                  child: Text('Em revisão')),
                              DropdownMenuItem(
                                  value: 'Sem data', child: Text('Sem data')),
                              DropdownMenuItem(
                                  value: 'Acompanhamento',
                                  child: Text('Acompanhamento')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _filtroStatus = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Desempenho por disciplina',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (resumoDisciplinas.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child:
                        Text('Nenhuma disciplina encontrada para os filtros.'),
                  ),
                )
              else
                ...resumoDisciplinas.take(5).map((item) {
                  final disciplina = item['disciplina'] as String;
                  final media = item['media'] as double;
                  final correcoes = item['correcoes'] as int;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  disciplina,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${media.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (media / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$correcoes correção(ões) salva(s) no histórico',
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              const Text(
                'Rendimento por turma',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_rendimentoTurmas.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Ainda não há correções salvas para as turmas e filtros selecionados.',
                    ),
                  ),
                )
              else
                ..._rendimentoTurmas.take(5).map((turma) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  turma.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${turma.percentual.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (turma.percentual / 100).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${turma.alunos} aluno(s) identificado(s) • ${turma.correcoes} correção(ões)',
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              const Text(
                'Top alunos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_topAlunos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Ainda não há resultados de alunos identificados no histórico.',
                    ),
                  ),
                )
              else
                ..._topAlunos.take(5).map((aluno) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFDBEAFE),
                        foregroundColor: const Color(0xFF1D4ED8),
                        child: Text('${_topAlunos.indexOf(aluno) + 1}'),
                      ),
                      title: Text(aluno.nome),
                      subtitle: Text(
                          '${aluno.turma} • ${aluno.correcoes} correção(ões)'),
                      trailing: Text(
                        '${aluno.percentual.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              const Text(
                'Provas recentes no filtro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (provasRecentes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child:
                        Text('Nenhuma prova encontrada com os filtros atuais.'),
                  ),
                )
              else
                ...provasRecentes.take(6).map((prova) {
                  final data = _parseData(prova.data);
                  final status = _statusDaProva(prova);
                  final statusColor = switch (status) {
                    'No prazo' => const Color(0xFFDCFCE7),
                    'Em revisão' => const Color(0xFFFEF3C7),
                    'Sem data' => const Color(0xFFF3F4F6),
                    _ => const Color(0xFFDBEAFE),
                  };
                  final statusTextColor = switch (status) {
                    'No prazo' => const Color(0xFF166534),
                    'Em revisão' => const Color(0xFF92400E),
                    'Sem data' => const Color(0xFF475467),
                    _ => const Color(0xFF1D4ED8),
                  };

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(prova.titulo),
                      subtitle: Text(
                          '${prova.disciplina} • ${data == null ? 'Sem data' : data.toIso8601String().substring(0, 10)}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
