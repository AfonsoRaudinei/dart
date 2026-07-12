import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';

import '../../../../core/router/app_routes.dart';
import '../models/relatorio_status.dart';
import '../models/relatorio_tecnico.dart';
import '../providers/relatorio_providers.dart';
import '../use_cases/publish_relatorio_use_case.dart';
import '../../../../core/constants/layout_constants.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

/// Tela de Listagem de Relatórios Técnicos — PASSO 3
///
/// Rota: [AppRoutes.relatorios] (/consultoria/relatorios) — L1
///
/// TabBar com 2 abas:
///   - "Meus" → relatórios do cliente autenticado
///   - "Compartilhados" → estrutura vazia (sem lógica)
///
/// Navegação: sem AppBar. SmartButton global cuida do retorno ao mapa.
class RelatoriosListScreen extends ConsumerStatefulWidget {
  const RelatoriosListScreen({super.key});

  @override
  ConsumerState<RelatoriosListScreen> createState() =>
      _RelatoriosListScreenState();
}

class _RelatoriosListScreenState extends ConsumerState<RelatoriosListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoloForteSheetTokens.sheetBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMeusTab(), _buildCompartilhadosTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Relatórios',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/consultoria/publicacoes/nova'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: SoloForteSheetTokens.inputBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFF1A56DB),
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          tabs: const [
            Tab(text: 'Meus'),
            Tab(text: 'Compartilhados'),
          ],
        ),
      ),
    );
  }

  Widget _buildMeusTab() {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final reportsAsync = ref.watch(relatoriosListProvider(clientId: userId));

    return reportsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            userFacingError(error, action: 'Erro ao carregar relatórios:\n'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      ),
      data: (relatorios) {
        if (relatorios.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum relatório encontrado.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, kFabSafeArea),
          itemCount: relatorios.length,
          itemBuilder: (context, index) {
            return _RelatorioCard(
              relatorio: relatorios[index],
              onLongPress: () => _showActionsSheet(context, relatorios[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildCompartilhadosTab() {
    return const Center(
      child: Text(
        'Nenhum relatório compartilhado.',
        style: TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }

  void _showActionsSheet(BuildContext context, RelatorioTecnico relatorio) {
    showSoloForteSheet(
      context: context,
      showDragHandle: false,
      builder: (context) => _ActionsSheet(relatorio: relatorio),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMPONENTES PRIVADOS
// ════════════════════════════════════════════════════════════════════════

class _RelatorioCard extends StatelessWidget {
  const _RelatorioCard({required this.relatorio, required this.onLongPress});

  final RelatorioTecnico relatorio;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SoloForteSheetTokens.inputBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    relatorio.title ?? relatorio.farmName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: relatorio.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              relatorio.farmName,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            Text(
              _formatPeriod(relatorio.periodStart, relatorio.periodEnd),
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(DateTime start, DateTime end) {
    final formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(start)} → ${formatter.format(end)}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RelatorioStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: config['fg'] as Color,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(RelatorioStatus status) {
    switch (status) {
      case RelatorioStatus.pendente_revisao:
        return {
          'bg': const Color(0xFFFFF3CD),
          'fg': const Color(0xFF92400E),
          'label': 'Pendente',
        };
      case RelatorioStatus.publicado:
        return {
          'bg': const Color(0xFFD1FAE5),
          'fg': const Color(0xFF065F46),
          'label': 'Publicado',
        };
      case RelatorioStatus.arquivado:
        return {
          'bg': const Color(0xFFF3F4F6),
          'fg': const Color(0xFF6B7280),
          'label': 'Arquivado',
        };
    }
  }
}

class _ActionsSheet extends ConsumerWidget {
  const _ActionsSheet({required this.relatorio});

  final RelatorioTecnico relatorio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                relatorio.title ?? relatorio.farmName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 32),
            // Ações
            _ActionTile(
              icon: Icons.visibility,
              label: 'Ver relatório',
              onTap: () {
                Navigator.pop(context);
                context.go('/consultoria/relatorios/${relatorio.id}');
              },
            ),
            if (relatorio.status == RelatorioStatus.pendente_revisao) ...[
              _ActionTile(
                icon: Icons.edit,
                label: 'Editar',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/consultoria/relatorios/${relatorio.id}');
                },
              ),
              _ActionTile(
                icon: Icons.publish,
                label: 'Publicar',
                color: const Color(0xFF059669),
                onTap: () {
                  Navigator.pop(context);
                  _showPublishDialog(context, ref, relatorio.id);
                },
              ),
            ],
            if (relatorio.status == RelatorioStatus.publicado)
              _ActionTile(
                icon: Icons.archive,
                label: 'Arquivar',
                color: const Color(0xFF6B7280),
                onTap: () {
                  Navigator.pop(context);
                  _showArchiveDialog(context, ref, relatorio.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPublishDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publicar relatório'),
        content: const Text(
          'O relatório será enviado ao produtor e ao agrônomo. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(publishRelatorioProvider(id).future);
                if (!context.mounted) return; // ← Guard obrigatório antes de usar ref
                ref.invalidate(relatoriosListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Relatório publicado com sucesso!'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userFacingError(e, action: 'Erro ao publicar')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar relatório'),
        content: const Text(
          'O relatório será arquivado. Você poderá restaurá-lo depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repository = ref.read(relatorioRepositoryProvider);
                final relatorio = await repository.getById(id);
                if (relatorio != null) {
                  await repository.update(
                    relatorio.copyWith(
                      status: RelatorioStatus.arquivado,
                      updatedAt: DateTime.now().toUtc(),
                    ),
                  );
                  ref.invalidate(relatoriosListProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Relatório arquivado com sucesso!'),
                        backgroundColor: Color(0xFF6B7280),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userFacingError(e, action: 'Erro ao arquivar')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF111827);

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
