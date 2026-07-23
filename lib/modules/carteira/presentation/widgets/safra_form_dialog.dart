import 'package:flutter/material.dart';
import '../../../../core/session/local_session_identity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/carteira_safra.dart';
import '../providers/carteira_providers.dart';

/// Dialog para criar uma nova safra.
/// Campos: nome, data início, data fim.
/// Ao salvar, ativa automaticamente a safra criada.
class SafraFormDialog extends ConsumerStatefulWidget {
  const SafraFormDialog({super.key});

  @override
  ConsumerState<SafraFormDialog> createState() => _SafraFormDialogState();
}

class _SafraFormDialogState extends ConsumerState<SafraFormDialog> {
  final _nomeController = TextEditingController();
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  String get _userId => LocalSessionIdentity.resolveUserId();

  Future<void> _pickData(bool isInicio) async {
    final initial = isInicio
        ? (_dataInicio ?? DateTime.now())
        : (_dataFim ?? DateTime.now().add(const Duration(days: 180)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) {
        _dataInicio = picked;
      } else {
        _dataFim = picked;
      }
    });
  }

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome deve ter pelo menos 3 caracteres')),
      );
      return;
    }
    if (_dataInicio == null || _dataFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina data de início e término')),
      );
      return;
    }
    if (!_dataFim!.isAfter(_dataInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data de término deve ser após a data de início'),
        ),
      );
      return;
    }
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuário não autenticado')));
      return;
    }

    setState(() => _salvando = true);
    try {
      final repo = ref.read(carteiraRepositoryProvider);
      final now = DateTime.now();
      final safra = CarteiraSafra(
        id: const Uuid().v4(),
        userId: _userId,
        nome: nome,
        dataInicio: _dataInicio!,
        dataFim: _dataFim!,
        ativa: true,
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveSafra(safra);
      await repo.ativarSafra(safra.id, _userId);

      ref.invalidate(safraAtivaProvider);
      ref.invalidate(safrasProvider);
      ref.invalidate(metasSafraAtivaProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar safra: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateFormat(DateTime? date) {
      if (date == null) return 'Selecionar';
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return AlertDialog(
      title: const Text('Nova Safra'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Nome (ex: Safra 24/25)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Início',
                  value: dateFormat(_dataInicio),
                  onTap: () => _pickData(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'Término',
                  value: dateFormat(_dataFim),
                  onTap: () => _pickData(false),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
