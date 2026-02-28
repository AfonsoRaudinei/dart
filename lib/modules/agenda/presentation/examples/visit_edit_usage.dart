import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/visit.dart';
import '../../domain/enums/event_status.dart';
import '../widgets/visit_edit_dialog.dart';

/// Exemplo de uso do VisitEditDialog
///
/// Este arquivo demonstra como usar o dialog de edição de visitas
/// com validação completa de conflitos.

class ExemploUsoEdicaoVisita {
  /// Exemplo 1: Editar visita a partir de um card
  static Widget buildExampleCard(Event event) {
    return Consumer(
      builder: (context, ref, child) {
        return Card(
          child: ListTile(
            title: Text(event.titulo),
            subtitle: Text(event.formattedTimeRange),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                // Abre o dialog de edição
                final updated = await VisitEditDialog.show(context, event);

                if (updated == true) {
                  // Visita atualizada com sucesso
                  // O provider já atualizou o estado automaticamente
                  print('Visita atualizada!');
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// Exemplo 2: Editar com verificação de permissões
  static Future<void> editarComPermissoes(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    // Verifica se a visita pode ser editada
    if (event.status == EventStatus.emAndamento ||
        event.status == EventStatus.finalizando) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível editar visita em andamento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (event.status == EventStatus.concluido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível editar visita concluída'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Abre o dialog
    await VisitEditDialog.show(context, event);
  }

  /// Exemplo 3: Menu de contexto com opção de editar
  static Widget buildContextMenu(Event event) {
    return Consumer(
      builder: (context, ref, child) {
        return PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await VisitEditDialog.show(context, event);
                break;
              case 'delete':
                // Implementar exclusão
                break;
              case 'duplicate':
                // Implementar duplicação
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 20),
                  SizedBox(width: 8),
                  Text('Duplicar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ════════════════════════════════════════════════════════════════════
/// VALIDAÇÕES IMPLEMENTADAS
/// ════════════════════════════════════════════════════════════════════
///
/// ✅ Conflito de horário usando excludeEventId
///    - O próprio evento é excluído da validação
///    - Detecta conflitos com outros eventos do mesmo dia
///    - Bloqueia salvamento se houver conflito
///
/// ✅ Validação de status
///    - Não permite editar visita em andamento
///    - Não permite editar visita concluída
///    - Apenas visitas agendadas ou canceladas podem ser editadas
///
/// ✅ Alerta de distância (não bloqueante)
///    - Calcula distância com outros eventos do mesmo dia
///    - Mostra aviso se distância > 50km e intervalo < 1h
///    - Permite salvar mesmo com aviso
///
/// ✅ Validação de horário
///    - startTime < endTime
///    - Comparação numérica (minutos desde meia-noite)
///
/// ════════════════════════════════════════════════════════════════════
/// FLUXO DE EDIÇÃO
/// ════════════════════════════════════════════════════════════════════
///
/// 1. Usuário clica em "Editar" no evento
/// 2. VisitEditDialog.show(context, event)
/// 3. Dialog carrega valores atuais do evento
/// 4. Usuário altera campos
/// 5. Ao salvar:
///    a) Valida campos obrigatórios
///    b) Valida startTime < endTime
///    c) Verifica conflito de horário (excluindo próprio evento)
///    d) Mostra aviso de distância se necessário
///    e) Chama updateEvent() do provider
///    f) Provider atualiza banco e estado
///    g) Dialog fecha e mostra mensagem de sucesso
///
/// ════════════════════════════════════════════════════════════════════
/// DIFERENÇAS ENTRE CREATE E UPDATE
/// ════════════════════════════════════════════════════════════════════
///
/// VisitFormDialog (criar):
/// - Não tem excludeEventId
/// - Valida conflito com todos os eventos
/// - Campos vazios inicialmente
///
/// VisitEditDialog (editar):
/// - Usa excludeEventId = event.id
/// - Exclui próprio evento da validação de conflito
/// - Campos pré-preenchidos com valores atuais
/// - Validação de status (não permite editar em andamento/concluído)
///
