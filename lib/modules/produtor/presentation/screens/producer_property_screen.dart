import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../data/producer_link_models.dart';
import '../../data/producer_link_repository.dart';
import '../../data/producer_property_repository.dart';

part 'producer_property_forms.dart';

class ProducerPropertyScreen extends ConsumerStatefulWidget {
  const ProducerPropertyScreen({super.key});

  @override
  ConsumerState<ProducerPropertyScreen> createState() =>
      _ProducerPropertyScreenState();
}

class _ProducerPropertyScreenState
    extends ConsumerState<ProducerPropertyScreen> {
  final _tokenController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _acceptToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(producerLinkRepositoryProvider).acceptToken(token);
      ref.invalidate(producerPropertyDashboardProvider);
      _tokenController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriedade vinculada com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token inválido, expirado ou já utilizado.'),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveFarm({ProducerOwnFarm? farm}) async {
    final result = await _showFarmFormDialog(context, farm: farm);
    if (result == null) return;

    await ref
        .read(producerPropertyRepositoryProvider)
        .saveOwnFarm(
          farmId: farm?.id,
          name: result.name,
          city: result.city,
          state: result.state,
          areaHa: result.areaHa,
        );
    // Adia o invalidate para depois do frame atual: chamá-lo em seguida ao
    // Navigator.pop() do diálogo faz o rebuild colidir com a animação de
    // transição da rota (Listenable.merge do framework tenta usar um
    // AnimationController já disposed) e derruba o app com
    // "_dependents.isEmpty: is not true".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(producerPropertyDashboardProvider);
    });
  }

  Future<void> _saveField(
    ProducerOwnFarm farm, {
    ProducerOwnField? field,
  }) async {
    final result = await _showFieldFormDialog(context, field: field);
    if (result == null) return;

    await ref
        .read(producerPropertyRepositoryProvider)
        .saveOwnField(
          fieldId: field?.id,
          farmId: farm.id,
          name: result.name,
          areaHa: result.areaHa,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(producerPropertyDashboardProvider);
    });
  }

  Future<void> _deleteFarm(ProducerOwnFarm farm) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir fazenda?',
      message: 'A fazenda "${farm.name}" será removida da sua propriedade.',
    );
    if (confirmed != true) return;

    try {
      await ref.read(producerPropertyRepositoryProvider).deleteOwnFarm(farm.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(producerPropertyDashboardProvider);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fazenda excluída.')));
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _deleteField(ProducerOwnField field) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Excluir talhão?',
      message: 'O talhão "${field.name}" será removido da sua propriedade.',
    );
    if (confirmed != true) return;

    await ref.read(producerPropertyRepositoryProvider).deleteOwnField(field.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(producerPropertyDashboardProvider);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Talhão excluído.')));
  }

  void _openDrawing(ProducerOwnProperty property, ProducerOwnFarm farm) {
    context.go(
      Uri(
        path: AppRoutes.map,
        queryParameters: {
          'modo': 'desenho',
          'clienteId': property.clientId,
          'fazendaId': farm.id,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(producerPropertyDashboardProvider);

    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go(AppRoutes.map),
                  ),
                  const Expanded(
                    child: Text(
                      'Minha propriedade',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(producerPropertyDashboardProvider);
                  await ref.read(producerPropertyDashboardProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, kFabSafeArea),
                  children: [
                    dashboardAsync.when(
                      data: (dashboard) => _DashboardContent(
                        dashboard: dashboard,
                        tokenController: _tokenController,
                        isSubmittingToken: _isSubmitting,
                        onSubmitToken: _acceptToken,
                        onAddFarm: () => _saveFarm(),
                        onEditFarm: (farm) => _saveFarm(farm: farm),
                        onDeleteFarm: _deleteFarm,
                        onAddField: (farm) => _saveField(farm),
                        onEditField: (farm, field) =>
                            _saveField(farm, field: field),
                        onDeleteField: (_, field) => _deleteField(field),
                        onOpenDrawing: _openDrawing,
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _RetryState(
                        onRetry: () =>
                            ref.invalidate(producerPropertyDashboardProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.dashboard,
    required this.tokenController,
    required this.isSubmittingToken,
    required this.onSubmitToken,
    required this.onAddFarm,
    required this.onEditFarm,
    required this.onDeleteFarm,
    required this.onAddField,
    required this.onEditField,
    required this.onDeleteField,
    required this.onOpenDrawing,
  });

  final ProducerPropertyDashboard dashboard;
  final TextEditingController tokenController;
  final bool isSubmittingToken;
  final VoidCallback onSubmitToken;
  final VoidCallback onAddFarm;
  final ValueChanged<ProducerOwnFarm> onEditFarm;
  final ValueChanged<ProducerOwnFarm> onDeleteFarm;
  final ValueChanged<ProducerOwnFarm> onAddField;
  final void Function(ProducerOwnFarm farm, ProducerOwnField field) onEditField;
  final void Function(ProducerOwnFarm farm, ProducerOwnField field)
  onDeleteField;
  final void Function(ProducerOwnProperty property, ProducerOwnFarm farm)
  onOpenDrawing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OwnPropertySection(
          property: dashboard.ownProperty,
          onAddFarm: onAddFarm,
          onEditFarm: onEditFarm,
          onDeleteFarm: onDeleteFarm,
          onAddField: onAddField,
          onEditField: onEditField,
          onDeleteField: onDeleteField,
          onOpenDrawing: onOpenDrawing,
        ),
        const SizedBox(height: 20),
        _ConsultantDataSection(
          linkedClients: dashboard.linkedClients,
          tokenController: tokenController,
          isSubmittingToken: isSubmittingToken,
          onSubmitToken: onSubmitToken,
        ),
      ],
    );
  }
}

class _OwnPropertySection extends StatelessWidget {
  const _OwnPropertySection({
    required this.property,
    required this.onAddFarm,
    required this.onEditFarm,
    required this.onDeleteFarm,
    required this.onAddField,
    required this.onEditField,
    required this.onDeleteField,
    required this.onOpenDrawing,
  });

  final ProducerOwnProperty property;
  final VoidCallback onAddFarm;
  final ValueChanged<ProducerOwnFarm> onEditFarm;
  final ValueChanged<ProducerOwnFarm> onDeleteFarm;
  final ValueChanged<ProducerOwnFarm> onAddField;
  final void Function(ProducerOwnFarm farm, ProducerOwnField field) onEditField;
  final void Function(ProducerOwnFarm farm, ProducerOwnField field)
  onDeleteField;
  final void Function(ProducerOwnProperty property, ProducerOwnFarm farm)
  onOpenDrawing;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Minha área'),
          Text(
            property.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if ((property.email ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              property.email!,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
          const SizedBox(height: 14),
          if (!property.hasFarms)
            const _MutedText('Nenhuma fazenda cadastrada ainda.')
          else
            ...property.farms.map(
              (farm) => _OwnFarmTile(
                farm: farm,
                onEditFarm: () => onEditFarm(farm),
                onDeleteFarm: () => onDeleteFarm(farm),
                onAddField: () => onAddField(farm),
                onOpenDrawing: () => onOpenDrawing(property, farm),
                onEditField: (field) => onEditField(farm, field),
                onDeleteField: (field) => onDeleteField(farm, field),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddFarm,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar fazenda'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnFarmTile extends StatelessWidget {
  const _OwnFarmTile({
    required this.farm,
    required this.onEditFarm,
    required this.onDeleteFarm,
    required this.onAddField,
    required this.onOpenDrawing,
    required this.onEditField,
    required this.onDeleteField,
  });

  final ProducerOwnFarm farm;
  final VoidCallback onEditFarm;
  final VoidCallback onDeleteFarm;
  final VoidCallback onAddField;
  final VoidCallback onOpenDrawing;
  final ValueChanged<ProducerOwnField> onEditField;
  final ValueChanged<ProducerOwnField> onDeleteField;

  @override
  Widget build(BuildContext context) {
    final location = [
      farm.city,
      farm.state,
    ].where((value) => value.trim().isNotEmpty).join(' - ');

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.premiumSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.premiumHairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.agriculture_outlined, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      farm.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar fazenda',
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    onPressed: onEditFarm,
                  ),
                  IconButton(
                    tooltip: 'Excluir fazenda',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Colors.red,
                    ),
                    onPressed: onDeleteFarm,
                  ),
                ],
              ),
              Text(
                [
                  if (location.isNotEmpty) location,
                  '${farm.areaHa.toStringAsFixed(1)} ha',
                ].join(' • '),
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(child: _SectionTitle('Talhões')),
                  TextButton.icon(
                    onPressed: onAddField,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Talhão'),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenDrawing,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Desenhar ou importar KML/KMZ'),
                ),
              ),
              if (farm.fields.isEmpty)
                const _MutedText('Nenhum talhão cadastrado.')
              else
                ...farm.fields.map(
                  (field) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      field.hasGeometry
                          ? Icons.polyline_outlined
                          : Icons.grid_view_outlined,
                    ),
                    title: Text(field.name),
                    subtitle: Text(
                      [
                        '${field.areaHa.toStringAsFixed(1)} ha',
                        if (field.hasGeometry) 'com mapa',
                      ].join(' • '),
                    ),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          tooltip: 'Editar talhão',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEditField(field),
                        ),
                        IconButton(
                          tooltip: 'Excluir talhão',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => onDeleteField(field),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsultantDataSection extends StatelessWidget {
  const _ConsultantDataSection({
    required this.linkedClients,
    required this.tokenController,
    required this.isSubmittingToken,
    required this.onSubmitToken,
  });

  final List<ProducerLinkedClient> linkedClients;
  final TextEditingController tokenController;
  final bool isSubmittingToken;
  final VoidCallback onSubmitToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TokenPanel(
          controller: tokenController,
          isSubmitting: isSubmittingToken,
          onSubmit: onSubmitToken,
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Dados do consultor'),
        if (linkedClients.isEmpty)
          const _EmptyLinkedState()
        else
          _LinkedClientsList(clients: linkedClients),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.premiumHairline),
      ),
      child: child,
    );
  }
}

class _TokenPanel extends StatelessWidget {
  const _TokenPanel({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.premiumHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vincular propriedade',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Insira o token enviado pelo consultor para visualizar fazendas, talhões e relatórios liberados.',
            style: TextStyle(color: Color(0xFF5F6B5A), height: 1.35),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\s]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Token',
              hintText: 'SF-0000-0000-0000',
              prefixIcon: Icon(Icons.key_outlined),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: const Text('Vincular'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedClientsList extends StatelessWidget {
  const _LinkedClientsList({required this.clients});

  final List<ProducerLinkedClient> clients;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: clients.map((client) => _ClientCard(client: client)).toList(),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client});

  final ProducerLinkedClient client;

  @override
  Widget build(BuildContext context) {
    final location = [
      client.city,
      client.state,
    ].where((value) => value?.trim().isNotEmpty == true).join(' - ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.premiumHairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            client.name,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(location, style: const TextStyle(color: Color(0xFF6B7280))),
          ],
          const SizedBox(height: 16),
          const _SectionTitle('Fazendas'),
          if (client.farms.isEmpty)
            const _MutedText('Nenhuma fazenda liberada.')
          else
            ...client.farms.map((farm) => _FarmTile(farm: farm)),
          const SizedBox(height: 16),
          const _SectionTitle('Relatórios'),
          if (client.reports.isEmpty)
            const _MutedText('Nenhum relatório liberado.')
          else
            ...client.reports.map((report) => _ReportTile(report: report)),
        ],
      ),
    );
  }
}

class _FarmTile extends StatelessWidget {
  const _FarmTile({required this.farm});

  final ProducerLinkedFarm farm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture_outlined, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  farm.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('${farm.areaHa.toStringAsFixed(1)} ha'),
            ],
          ),
          if (farm.fields.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...farm.fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(left: 27, bottom: 5),
                child: Text(
                  '${field.name} • ${field.areaHa.toStringAsFixed(1)} ha',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final ProducerLinkedReport report;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(report.title),
      subtitle: Text(report.farmName),
      dense: true,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: const TextStyle(color: Color(0xFF8E8E93))),
    );
  }
}

class _EmptyLinkedState extends StatelessWidget {
  const _EmptyLinkedState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.link_off_outlined, size: 44, color: Color(0xFF8E8E93)),
          SizedBox(height: 12),
          Text(
            'Nenhuma propriedade vinculada',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Você pode usar o app sem token, mas só verá dados do consultor depois de vincular uma propriedade.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Tentar novamente'),
      ),
    );
  }
}
