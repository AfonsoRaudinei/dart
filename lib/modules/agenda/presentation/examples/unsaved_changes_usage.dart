// ════════════════════════════════════════════════════════════════════════════
// EXEMPLO DE USO - MARCAÇÃO DE ALTERAÇÕES NÃO SALVAS
// ════════════════════════════════════════════════════════════════════════════
//
// Este arquivo demonstra como usar o sistema de confirmação de alterações
// não salvas nas views da agenda.
//
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/agenda_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 1: Marcar alteração ao editar campo
// ────────────────────────────────────────────────────────────────────────────

class ExemploEditarEvento extends ConsumerWidget {
  const ExemploEditarEvento({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (value) {
        // ✅ Marcar como alterado quando usuário digitar
        ref.read(agendaHasUnsavedChangesProvider.notifier).state = true;
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 2: Limpar flag ao salvar
// ────────────────────────────────────────────────────────────────────────────

class ExemploSalvarEvento extends ConsumerWidget {
  const ExemploSalvarEvento({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Salvar evento...
        await _salvarEvento();

        // ✅ Limpar flag após salvar com sucesso
        ref.read(agendaHasUnsavedChangesProvider.notifier).state = false;
      },
      child: const Text('Salvar'),
    );
  }

  Future<void> _salvarEvento() async {
    // Lógica de salvamento
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 3: Uso em formulário complexo
// ────────────────────────────────────────────────────────────────────────────

class ExemploFormularioComplexo extends ConsumerStatefulWidget {
  const ExemploFormularioComplexo({super.key});

  @override
  ConsumerState<ExemploFormularioComplexo> createState() =>
      _ExemploFormularioComplexoState();
}

class _ExemploFormularioComplexoState
    extends ConsumerState<ExemploFormularioComplexo> {
  final _formKey = GlobalKey<FormState>();

  void _markAsChanged() {
    // ✅ Centralizar marcação de alteração
    ref.read(agendaHasUnsavedChangesProvider.notifier).state = true;
  }

  void _clearChanges() {
    // ✅ Limpar após salvar
    ref.read(agendaHasUnsavedChangesProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Título'),
            onChanged: (value) {
              _markAsChanged(); // ✅
            },
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Descrição'),
            onChanged: (value) {
              _markAsChanged(); // ✅
            },
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _salvarFormulario();
                _clearChanges(); // ✅
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarFormulario() async {
    // Lógica de salvamento
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 4: Uso com drag & drop (planejamento)
// ────────────────────────────────────────────────────────────────────────────

class ExemploDragDrop extends ConsumerWidget {
  const ExemploDragDrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView(
      onReorder: (oldIndex, newIndex) {
        // Reordenar itens...

        // ✅ Marcar como alterado ao reordenar
        ref.read(agendaHasUnsavedChangesProvider.notifier).state = true;
      },
      children: [],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PADRÃO RECOMENDADO
// ════════════════════════════════════════════════════════════════════════════
//
// 1. MARCAR ALTERAÇÃO:
//    - Ao editar campo
//    - Ao reordenar lista
//    - Ao duplicar item
//    - Ao deletar item
//    - Ao modificar qualquer dado
//
// 2. LIMPAR FLAG:
//    - Após salvar com sucesso
//    - Após descartar alterações confirmadas
//    - Ao cancelar edição
//
// 3. NÃO MARCAR:
//    - Ao apenas visualizar
//    - Ao navegar sem editar
//    - Em views read-only (Calendário, Indicadores)
//
// ════════════════════════════════════════════════════════════════════════════
