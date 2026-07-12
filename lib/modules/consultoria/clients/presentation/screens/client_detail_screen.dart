import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_producer_invite_writer_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

import '../providers/clients_providers.dart';
import '../providers/field_providers.dart';
import '../../domain/agronomic_models.dart';
import '../../domain/client.dart';
import '../../domain/client_cultura.dart';
import '../widgets/client_avatar_widget.dart';
import '../widgets/cultura_item_widget.dart';
import '../widgets/client_hub_section.dart';
import '../widgets/client_detail_sub_widgets.dart';
import '../widgets/client_edit_form.dart';
import '../widgets/talhao_map_preview.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

Future<bool> showClientDeleteConfirmation(
  BuildContext context,
  String clientName,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Excluir cliente'),
          content: Text(
            'Deseja excluir "$clientName"?\nEsta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ??
      false;
}

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  bool _editando = false;
  bool _excluindo = false;
  Client? _clienteEditandoSnapshot;
  List<ClientCultura> _culturasEditandoSnapshot = [];

  void _iniciarEdicao(Client client, List<ClientCultura> culturas) {
    setState(() {
      _editando = true;
      _clienteEditandoSnapshot = client;
      _culturasEditandoSnapshot = List.from(culturas);
    });
  }

  Future<void> _salvarEdicao(
    Client clienteAtualizado,
    List<ClientCultura> culturasComId,
  ) async {
    await ref
        .read(clientsControllerProvider)
        .updateClient(clienteAtualizado, culturas: culturasComId);
    if (!mounted) return;
    setState(() => _editando = false);
  }

  Future<void> _confirmarExclusao(Client client) async {
    final confirmed = await showClientDeleteConfirmation(context, client.name);
    if (!confirmed || !mounted) return;

    setState(() => _excluindo = true);
    try {
      await ref.read(clientsControllerProvider).deleteClient(client.id);
      if (!mounted) return;
      context.go(AppRoutes.clients);
    } catch (_) {
      if (!mounted) return;
      setState(() => _excluindo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o cliente.')),
      );
    }
  }

  // 🆕 SPRINT 3: Modal iOS Premium — escolha de ação para nova fazenda/talhão
  void _showNovaFazendaModal(BuildContext context, client) =>
      showNovaFazendaModal(context, client);

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientDetailProvider(widget.clientId));
    final culturasAsync = ref.watch(clientCulturasProvider(widget.clientId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: clientAsync.when(
        data: (client) {
          if (client == null) {
            return const Center(child: Text('Cliente não encontrado'));
          }
          final culturas = culturasAsync.valueOrNull ?? [];

          if (_editando && _clienteEditandoSnapshot != null) {
            return ClientEditForm(
              client: _clienteEditandoSnapshot!,
              culturas: _culturasEditandoSnapshot,
              onCancel: () => setState(() => _editando = false),
              onSave: _salvarEdicao,
            );
          }
          return _buildModoLeitura(client, culturas);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(userFacingError(err, action: 'Erro'))),
      ),
    );
  }

  // ── MODO LEITURA ──────────────────────────────────────────────────

  Widget _buildModoLeitura(Client client, List<ClientCultura> culturas) {
    return Stack(
      children: [
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 96),
                    Expanded(
                      child: Text(
                        client.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            tooltip: 'Excluir cliente',
                            onPressed: _excluindo
                                ? null
                                : () => _confirmarExclusao(client),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            color: PremiumTokens.brandGreen,
                            tooltip: 'Editar',
                            onPressed: _excluindo
                                ? null
                                : () => _iniciarEdicao(client, culturas),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: ClientAvatarWidget(
                        fotoPath: client.photoPath,
                        nome: client.name,
                        radius: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        client.city.isNotEmpty
                            ? '${client.city} — ${client.state}'
                            : '',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Ações rápidas Hub do Cliente — WS-4
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ClientActionButton(
                            icon: Icons.phone,
                            label: 'Ligar',
                            onTap: () => _launchURL('tel:${client.phone}'),
                          ),
                          const SizedBox(width: 16),
                          ClientActionButton(
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            onTap: () => _launchURL(
                              'https://wa.me/55${client.phone.replaceAll(RegExp(r'[^0-9]'), '')}',
                            ),
                          ),
                          const SizedBox(width: 16),
                          ClientActionButton(
                            icon: Icons.description_outlined,
                            label: 'Relatórios',
                            onTap: () => context.go(
                              '/consultoria/relatorios?clienteId=${client.id}',
                            ),
                          ),
                          const SizedBox(width: 16),
                          ClientActionButton(
                            icon: Icons.key_outlined,
                            label: 'Convite',
                            onTap: () =>
                                _showProducerInviteDialog(context, client),
                          ),
                          const SizedBox(width: 16),
                          ClientActionButton(
                            icon: Icons.calendar_today_outlined,
                            label: 'Agenda',
                            onTap: () =>
                                context.go('/agenda?clienteId=${client.id}'),
                          ),
                          const SizedBox(width: 16),
                          ClientActionButton(
                            icon: Icons.directions_walk,
                            label: 'Visita',
                            onTap: () => context.go(
                              '/map?modo=visita&clienteId=${client.id}'
                              '&clienteNome=${Uri.encodeComponent(client.name)}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // — Painel de estatísticas (WS-4 / WS-8) —
                    ClientStatsPanel(clientId: client.id),
                    const SizedBox(height: 24),

                    // Seção Identificação
                    if (client.email != null || client.cpfCnpj != null) ...[
                      _sectionTitle('Identificação'),
                      if (client.email != null)
                        _infoRow('E-mail', client.email!),
                      if (client.cpfCnpj != null)
                        _infoRow('CPF / CNPJ', client.cpfCnpj!),
                      if (client.dataNascimento != null)
                        _infoRow(
                          'Nascimento',
                          _formatDate(client.dataNascimento!),
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Seção Propriedade
                    if (client.areaTotal != null ||
                        client.tipoPropriedade != null ||
                        client.safraAtual != null) ...[
                      _sectionTitle('Propriedade'),
                      if (client.areaTotal != null)
                        _infoRow('Área Total', '${client.areaTotal} ha'),
                      if (client.tipoPropriedade != null)
                        _infoRow('Tipo', client.tipoPropriedade!),
                      if (client.sistemaIrrigacao != null)
                        _infoRow('Irrigação', client.sistemaIrrigacao!),
                      if (client.soloTipo != null)
                        _infoRow('Solo', client.soloTipo!),
                      if (client.regiaoAgricola != null)
                        _infoRow('Região', client.regiaoAgricola!),
                      if (client.safraAtual != null)
                        _infoRow('Safra', client.safraAtual!),
                      const SizedBox(height: 24),
                    ],

                    // Seção Assistência
                    if (client.usaAssistenciaTecnica == true) ...[
                      _sectionTitle('Assistência Técnica'),
                      if (client.tecnicoResponsavel != null)
                        _infoRow('Técnico', client.tecnicoResponsavel!),
                      const SizedBox(height: 24),
                    ],

                    // Seção Culturas
                    _sectionTitle('Culturas'),
                    if (culturas.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          'Nenhuma cultura cadastrada',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      ...culturas.map(
                        (c) => CulturaItemWidget(cultura: c, onRemove: null),
                      ),
                    const SizedBox(height: 32),

                    // Seção Fazendas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fazendas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // ── INTEGRAÇÃO MAP-FIRST ───────────────────────
                        TextButton.icon(
                          icon: const Icon(
                            Icons.add,
                            color: PremiumTokens.brandGreen,
                          ),
                          label: const Text(
                            'Nova',
                            style: TextStyle(
                              color: PremiumTokens.brandGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // 🆕 SPRINT 3: Modal de escolha em vez de ir direto ao mapa
                          onPressed: () =>
                              _showNovaFazendaModal(context, client),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (client.farms.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.agriculture,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhuma fazenda cadastrada',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      ...client.farms.map(
                        (farm) =>
                            _ClientFarmWithTalhoes(client: client, farm: farm),
                      ),

                    const SizedBox(height: 20),
                    _ClientDrawingFieldsSection(client: client),

                    // Observações
                    if (client.observation != null &&
                        client.observation!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _sectionTitle('Observações'),
                      Text(client.observation!),
                    ],
                    const SizedBox(height: 32),
                    const SizedBox(height: kFabSafeArea),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _buildBotaoVoltar(context),
        ),
      ],
    );
  }

  Widget _buildBotaoVoltar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.clients),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios, size: 16),
            SizedBox(width: 4),
            Text(
              'Clientes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: Colors.black87,
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showProducerInviteDialog(BuildContext context, Client client) {
    String? token;
    DateTime? expiresAt;
    Object? error;
    var loading = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> generateInvite() async {
            setDialogState(() {
              loading = true;
              error = null;
            });
            try {
              final invite = await ref
                  .read(producerInviteWriterProvider)
                  .createInvite(client.id);
              if (!dialogContext.mounted) return;
              setDialogState(() {
                token = invite.token;
                expiresAt = invite.expiresAt.toLocal();
              });
            } catch (e) {
              if (!dialogContext.mounted) return;
              setDialogState(() => error = e);
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => loading = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Convite do produtor'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gere um token para ${client.name} vincular a conta dele a este cadastro.',
                ),
                const SizedBox(height: 16),
                if (token != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      token!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (expiresAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Válido até ${_formatDate(expiresAt!)}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Não foi possível gerar o convite agora.',
                    style: TextStyle(color: Color(0xFFFF3B30)),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fechar'),
              ),
              if (token != null)
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: token!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token copiado.')),
                    );
                  },
                  child: const Text('Copiar'),
                ),
              FilledButton(
                onPressed: loading ? null : generateInvite,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(token == null ? 'Gerar token' : 'Gerar novo'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientFarmWithTalhoes extends ConsumerWidget {
  final Client client;
  final Farm farm;

  const _ClientFarmWithTalhoes({required this.client, required this.farm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(farmLinkedFieldsProvider(farm.id));
    final linkedFields = fieldsAsync.asData?.value;
    final displayedAreaHa = linkedFields == null
        ? farm.totalAreaHa
        : totalFarmLinkedAreaHa(linkedFields);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientFarmItem(
          name: farm.name,
          area: '${_formatAreaHa(displayedAreaHa)} ha',
          onTap: () => context.go(AppRoutes.farmDetail(client.id, farm.id)),
        ),
        fieldsAsync.when(
          data: (fields) {
            if (fields.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Column(
                children: fields.map((field) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail do polígono
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            image: field.thumbnailPath != null
                                ? DecorationImage(
                                    image: FileImage(
                                      File(field.thumbnailPath!),
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: field.thumbnailPath == null
                              ? Icon(
                                  field.isDrawing
                                      ? Icons.map_outlined
                                      : Icons.terrain,
                                  color: Colors.grey.shade400,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Dados principais
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _farmFieldSubtitle(field),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sync Status
                        if (field.syncStatus != 0)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Tooltip(
                              message: 'Sincronização Pendente',
                              child: Icon(
                                Icons.cloud_off,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _farmFieldSubtitle(FarmLinkedFieldSummary field) {
    final parts = <String>['Área: ${_formatAreaHa(field.areaHa)} ha'];
    if (field.perimeter != null) {
      parts.add('Perímetro: ${field.perimeter!.toStringAsFixed(2)} km');
    }
    if (field.isDrawing) {
      parts.add('Talhão do mapa');
    }
    return parts.join(' • ');
  }

  String _formatAreaHa(double areaHa) {
    return areaHa.toStringAsFixed(areaHa >= 100 ? 1 : 2);
  }
}

class _ClientDrawingFieldsSection extends ConsumerWidget {
  final Client client;

  const _ClientDrawingFieldsSection({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingFieldsAsync = ref.watch(
      clientDrawingFieldsProvider(client.id),
    );

    return drawingFieldsAsync.when(
      data: (fields) {
        if (fields.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talhões do mapa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...fields.map((field) {
              final farmName = field.farmId == null
                  ? null
                  : _findFarmName(client, field.farmId!);

              return TalhaoMapPreviewWidget(
                vertices: field.vertices,
                nome: field.name,
                areaHa: field.areaHa,
                subtitle: farmName == null ? null : 'Fazenda: $farmName',
                onTap: () => context.go(_mapViewUri(field)),
                actions: [
                  IconButton(
                    tooltip: 'Abrir no mapa',
                    icon: const Icon(Icons.open_in_full, size: 20),
                    onPressed: () => context.go(_mapViewUri(field)),
                  ),
                  IconButton(
                    tooltip: 'Editar no mapa',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => context.go(_mapEditUri(field)),
                  ),
                  IconButton(
                    tooltip: 'Excluir talhão',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: () => _confirmDeleteDrawing(context, ref, field),
                  ),
                ],
              );
            }),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String? _findFarmName(Client client, String farmId) {
    for (final farm in client.farms) {
      if (farm.id == farmId) return farm.name;
    }
    return null;
  }

  Future<void> _confirmDeleteDrawing(
    BuildContext context,
    WidgetRef ref,
    ClientDrawingFieldSummary field,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir talhão?'),
        content: Text('O talhão "${field.name}" será removido do mapa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(iDrawingFieldWriterProvider)
        .deleteFieldAndRecalculateClientArea(
          fieldId: field.id,
          clientId: client.id,
        );

    ref.invalidate(clientDrawingFieldsProvider(client.id));
    if (field.farmId != null) {
      ref.invalidate(farmLinkedFieldsProvider(field.farmId!));
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Talhão excluído.')));
  }

  String _mapViewUri(ClientDrawingFieldSummary field) {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'desenho',
        'clienteId': client.id,
        if (field.farmId != null) 'fazendaId': field.farmId!,
        'drawingId': field.id,
      },
    ).toString();
  }

  String _mapEditUri(ClientDrawingFieldSummary field) {
    return Uri(
      path: AppRoutes.map,
      queryParameters: {
        'modo': 'editar',
        'clienteId': client.id,
        if (field.farmId != null) 'fazendaId': field.farmId!,
        'drawingId': field.id,
      },
    ).toString();
  }
}
