import 'package:flutter/material.dart';
import '../widgets/visit_form_dialog.dart';

/// Exemplo de uso do formulário de visita
///
/// Este arquivo demonstra como usar o VisitFormDialog para criar
/// visitas com horário, prioridade e validação de conflito.
///
/// INTEGRAÇÃO:
/// 1. Adicionar ao FAB de criar evento
/// 2. Adicionar ao menu de ações rápidas
/// 3. Adicionar ao calendário (toque longo em dia)

class ExemploUsoFormularioVisita {
  /// Exemplo 1: Abrir formulário do FAB
  static Future<void> abrirFormularioDoFAB(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => const VisitFormDialog(),
    );

    if (resultado == true) {
      // Visita criada com sucesso
      // A mensagem de sucesso já é exibida pelo próprio dialog
      debugPrint('✅ Visita criada com sucesso');
    }
  }

  /// Exemplo 2: Abrir formulário do calendário (toque longo)
  static Future<void> abrirFormularioDoCalendario(
    BuildContext context,
    DateTime dataSelecionada,
  ) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => const VisitFormDialog(),
    );

    if (resultado == true) {
      debugPrint('✅ Visita criada para ${dataSelecionada.toLocal()}');
    }
  }

  /// Exemplo 3: Widget de demonstração completo
  static Widget buildExemploCompleto() {
    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Exemplo: Criar Visita')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => abrirFormularioDoFAB(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Criar Nova Visita'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Funcionalidades do formulário:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ Seleção de data'),
                      Text('✅ Seleção de horário (início e fim)'),
                      Text('✅ Seleção de prioridade (baixa, normal, alta)'),
                      Text('✅ Validação de horário (fim > início)'),
                      Text('✅ Detecção automática de conflito'),
                      Text('✅ Mensagem de erro em caso de conflito'),
                      Text('✅ Bloqueio de múltiplas visitas em andamento'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// INTEGRAÇÃO NO AGENDA_MONTH_PAGE.DART
///
/// Substituir o FAB de criar evento:
///
/// ```dart
/// floatingActionButton: Column(
///   mainAxisSize: MainAxisSize.min,
///   children: [
///     FloatingActionButton(
///       heroTag: 'map_fab',
///       onPressed: () => context.go('/mapa'),
///       backgroundColor: const Color(0xFF4ADE80),
///       child: const Icon(Icons.map, color: Colors.white),
///     ),
///     const SizedBox(height: 16),
///     FloatingActionButton(
///       heroTag: 'create_fab',
///       onPressed: () async {
///         await showDialog(
///           context: context,
///           builder: (context) => const VisitFormDialog(),
///         );
///       },
///       backgroundColor: const Color(0xFF007AFF),
///       child: const Icon(Icons.add, color: Colors.white),
///     ),
///   ],
/// ),
/// ```

/// TRATAMENTO DE ERROS
///
/// O formulário já trata automaticamente:
///
/// 1. CONFLITO DE HORÁRIO:
///    - Detectado pelo checkVisitTimeConflict
///    - Mostra nome da visita conflitante e horário
///    - NÃO salva a visita
///
/// 2. VISITA JÁ EM ANDAMENTO:
///    - Detectado pelo hasActiveVisit
///    - Mostra mensagem "Finalize antes de iniciar outra"
///    - Bloqueia início de nova visita
///
/// 3. VALIDAÇÃO DE HORÁRIO:
///    - Fim deve ser maior que início
///    - Validado localmente antes de enviar
///
/// 4. VALIDAÇÃO DE TÍTULO:
///    - Obrigatório
///    - Mínimo 3 caracteres

/// FLUXO DE CRIAÇÃO
///
/// 1. Usuário clica no FAB azul (Criar Evento)
/// 2. Dialog abre com formulário
/// 3. Usuário preenche:
///    - Título
///    - Data (padrão: hoje)
///    - Horário início (opcional)
///    - Horário fim (opcional, auto-completado com +1h)
///    - Prioridade (padrão: normal)
///    - Tipo de evento
/// 4. Usuário clica em "Criar Visita"
/// 5. Validações:
///    - Campo título preenchido
///    - Horário fim > início
///    - Sem conflito de horário
///    - Sem visita em andamento
/// 6. Se tudo OK:
///    - Visita criada
///    - Dialog fecha
///    - SnackBar verde de sucesso
/// 7. Se erro:
///    - Mensagem vermelha no dialog
///    - Dialog permanece aberto
///    - Usuário pode corrigir
