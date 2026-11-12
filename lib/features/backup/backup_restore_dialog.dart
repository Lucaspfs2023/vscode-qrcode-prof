import 'package:flutter/material.dart';

import 'backup_repository.dart';
import 'text_export.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key});

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  final TextEditingController _backupController = TextEditingController();
  bool _isExporting = false;
  bool _isRestoring = false;

  @override
  void dispose() {
    _backupController.dispose();
    super.dispose();
  }

  Future<void> _exportar() async {
    setState(() => _isExporting = true);
    try {
      final backup = await BackupRepository.createBackup();
      final now = DateTime.now();
      final filename =
          'qrcode-prof-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      await exportText(
        backup,
        filename,
        contentType: 'application/json;charset=utf-8',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup exportado: $filename')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar o backup: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _restaurar() async {
    if (_backupController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cole o conteúdo do arquivo de backup.')),
      );
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Substituir dados locais?'),
        content: const Text(
          'A restauração substitui turmas, alunos, provas, questões e histórico atuais. Exporte um backup antes de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) {
      return;
    }

    setState(() => _isRestoring = true);
    try {
      await BackupRepository.restoreBackup(_backupController.text);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Não foi possível restaurar o backup: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isExporting || _isRestoring;
    return AlertDialog(
      title: const Text('Backup e restauração'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exporte um arquivo JSON com todos os dados locais. Para restaurar, abra um backup anterior, copie o conteúdo e cole abaixo.',
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: busy ? null : _exportar,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: const Text('Exportar backup JSON'),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _backupController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo do backup',
                  hintText: '{"schema":"qrcode-prof-local-backup", ...}',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: busy ? null : _restaurar,
          icon: _isRestoring
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.restore_rounded),
          label: const Text('Restaurar dados'),
        ),
      ],
    );
  }
}
