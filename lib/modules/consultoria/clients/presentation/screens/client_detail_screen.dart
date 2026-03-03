import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/services/client_stats_service.dart';
import 'package:uuid/uuid.dart';

import '../providers/clients_providers.dart';
import '../../domain/client.dart';
import '../../domain/client_cultura.dart';
import '../../domain/enums/cultura_tipo.dart';
import '../widgets/client_avatar_widget.dart';
import '../widgets/cultura_item_widget.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  bool _editando = false;

  // Estado de edição local
  Client? _clienteEditado;
  List<ClientCultura> _culturasEditadas = [];

  // Controllers para modo edição
  late TextEditingController _nomeCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _cpfCnpjCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _ufCtrl;
  late TextEditingController _areaTotalCtrl;
  late TextEditingController _regiaoCtrl;
  late TextEditingController _safraCtrl;
  late TextEditingController _tecnicoCtrl;
  late TextEditingController _obsCtrl;
  DateTime? _dataNascimentoEdit;
  String? _tipoPropriedadeEdit;
  String? _sistemaIrrigacaoEdit;
  String? _soloTipoEdit;
  bool _usaAssistenciaEdit = false;
  String? _fotoPathEdit;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _telefoneCtrl = TextEditingController();
    _cpfCnpjCtrl = TextEditingController();
    _cidadeCtrl = TextEditingController();
    _ufCtrl = TextEditingController();
    _areaTotalCtrl = TextEditingController();
    _regiaoCtrl = TextEditingController();
    _safraCtrl = TextEditingController();
    _tecnicoCtrl = TextEditingController();
    _obsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _cidadeCtrl.dispose();
    _ufCtrl.dispose();
    _areaTotalCtrl.dispose();
    _regiaoCtrl.dispose();
    _safraCtrl.dispose();
    _tecnicoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _iniciarEdicao(Client client, List<ClientCultura> culturas) {
    _nomeCtrl.text = client.name;
    _emailCtrl.text = client.email ?? '';
    _telefoneCtrl.text = client.phone;
    _cpfCnpjCtrl.text = client.cpfCnpj ?? '';
    _cidadeCtrl.text = client.city;
    _ufCtrl.text = client.state;
    _areaTotalCtrl.text = client.areaTotal?.toString() ?? '';
    _regiaoCtrl.text = client.regiaoAgricola ?? '';
    _safraCtrl.text = client.safraAtual ?? '';
    _tecnicoCtrl.text = client.tecnicoResponsavel ?? '';
    _obsCtrl.text = client.observation ?? '';
    setState(() {
      _editando = true;
      _clienteEditado = client;
      _culturasEditadas = List.from(culturas);
      _dataNascimentoEdit = client.dataNascimento;
      _tipoPropriedadeEdit = client.tipoPropriedade;
      _sistemaIrrigacaoEdit = client.sistemaIrrigacao;
      _soloTipoEdit = client.soloTipo;
      _usaAssistenciaEdit = client.usaAssistenciaTecnica ?? false;
      _fotoPathEdit = client.photoPath;
    });
  }

  Future<void> _salvarEdicao() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_clienteEditado == null) return; // guard contra race condition
    HapticFeedback.mediumImpact();

    final clienteAtualizado = _clienteEditado!.copyWith(
      name: _nomeCtrl.text.trim(),
      phone: _telefoneCtrl.text.trim(),
      city: _cidadeCtrl.text.trim(),
      state: _ufCtrl.text.trim().toUpperCase(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      observation: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      photoPath: _fotoPathEdit,
      cpfCnpj: _cpfCnpjCtrl.text.isEmpty
          ? null
          : _cpfCnpjCtrl.text.replaceAll(RegExp(r'\D'), ''),
      dataNascimento: _dataNascimentoEdit,
      areaTotal: double.tryParse(_areaTotalCtrl.text),
      tipoPropriedade: _tipoPropriedadeEdit,
      sistemaIrrigacao: _sistemaIrrigacaoEdit,
      soloTipo: _soloTipoEdit,
      regiaoAgricola: _regiaoCtrl.text.trim().isEmpty
          ? null
          : _regiaoCtrl.text.trim(),
      safraAtual:
          _safraCtrl.text.trim().isEmpty ? null : _safraCtrl.text.trim(),
      usaAssistenciaTecnica: _usaAssistenciaEdit,
      tecnicoResponsavel:
          _usaAssistenciaEdit && _tecnicoCtrl.text.trim().isNotEmpty
              ? _tecnicoCtrl.text.trim()
              : null,
      updatedAt: DateTime.now(),
    );

    final culturasComId = _culturasEditadas
        .map((c) => c.copyWith(clientId: clienteAtualizado.id))
        .toList();

    await ref.read(clientsControllerProvider).updateClient(
          clienteAtualizado,
          culturas: culturasComId,
        );

    if (!mounted) return;
    setState(() => _editando = false);
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await ImagePicker()
                    .pickImage(source: ImageSource.camera);
                if (!mounted) return;
                if (picked != null) setState(() => _fotoPathEdit = picked.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await ImagePicker()
                    .pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                if (picked != null) setState(() => _fotoPathEdit = picked.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirBottomSheetCultura() async {
    final formKey = GlobalKey<FormState>();
    CulturaTipo? culturaSel;
    final areaCtrl = TextEditingController();
    final variedadeCtrl = TextEditingController();
    final safraCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Adicionar Cultura',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CulturaTipo>(
                    decoration: _deco('Cultura *'),
                    items: CulturaTipo.values
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (v) => setS(() => culturaSel = v),
                    validator: (v) =>
                        v == null ? 'Selecione uma cultura' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: areaCtrl,
                    decoration: _deco('Área (ha) *'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d <= 0) return 'Informe área > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: variedadeCtrl,
                    decoration: _deco('Variedade / Cultivar'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: safraCtrl,
                    decoration: _deco('Safra'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: obsCtrl,
                    decoration: _deco('Observação'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTokens.brandGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) return;
                        final nova = ClientCultura(
                          id: const Uuid().v4(),
                          clientId: widget.clientId,
                          cultura: culturaSel!.name,
                          areaHa: double.parse(areaCtrl.text),
                          variedade: variedadeCtrl.text.isEmpty
                              ? null
                              : variedadeCtrl.text,
                          safra: safraCtrl.text.isEmpty
                              ? null
                              : safraCtrl.text,
                          observacao:
                              obsCtrl.text.isEmpty ? null : obsCtrl.text,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        Navigator.of(ctx).pop();
                        setState(() => _culturasEditadas.add(nova));
                      },
                      child: const Text('Confirmar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

          return _editando
              ? _buildModoEdicao(client, culturas)
              : _buildModoLeitura(client, culturas);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  // ── MODO LEITURA ──────────────────────────────────────────────────

  Widget _buildModoLeitura(Client client, List<ClientCultura> culturas) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/consultoria/clientes'),
                ),
                Expanded(
                  child: Text(
                    client.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: PremiumTokens.brandGreen,
                  tooltip: 'Editar',
                  onPressed: () => _iniciarEdicao(client, culturas),
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
                  child: Text(client.city.isNotEmpty
                      ? '${client.city} — ${client.state}'
                      : ''),
                ),
                const SizedBox(height: 32),

                // Ações rápidas Hub do Cliente — WS-4
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ActionButton(
                        icon: Icons.phone,
                        label: 'Ligar',
                        onTap: () => _launchURL('tel:${client.phone}'),
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        onTap: () => _launchURL(
                          'https://wa.me/55${client.phone.replaceAll(RegExp(r'[^0-9]'), '')}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.description_outlined,
                        label: 'Relatórios',
                        onTap: () => context.go(
                          '/consultoria/relatorios?clienteId=${client.id}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.calendar_today_outlined,
                        label: 'Agenda',
                        onTap: () =>
                            context.go('/agenda?clienteId=${client.id}'),
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
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
                _ClientStatsPanel(clientId: client.id),
                const SizedBox(height: 24),

                // Seção Identificação
                if (client.email != null || client.cpfCnpj != null) ...[
                  _sectionTitle('Identificação'),
                  if (client.email != null) _infoRow('E-mail', client.email!),
                  if (client.cpfCnpj != null)
                    _infoRow('CPF / CNPJ', client.cpfCnpj!),
                  if (client.dataNascimento != null)
                    _infoRow('Nascimento', _formatDate(client.dataNascimento!)),
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
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    // ── INTEGRAÇÃO MAP-FIRST ───────────────────────
                    TextButton.icon(
                      icon: const Icon(Icons.add,
                          color: PremiumTokens.brandGreen),
                      label: const Text(
                        'Nova',
                        style: TextStyle(
                          color: PremiumTokens.brandGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => context.go(
                        '/map?modo=desenho&clienteId=${client.id}'
                        '&clienteNome=${Uri.encodeComponent(client.name)}',
                      ),
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
                        Icon(Icons.agriculture,
                            size: 48, color: Colors.grey[400]),
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
                    (farm) => _FarmItem(
                      name: farm.name,
                      area: '${farm.totalAreaHa} ha',
                      onTap: () => context
                          .go(AppRoutes.farmDetail(client.id, farm.id)),
                    ),
                  ),

                // Observações
                if (client.observation != null &&
                    client.observation!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _sectionTitle('Observações'),
                  Text(client.observation!),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── MODO EDIÇÃO ───────────────────────────────────────────────────

  Widget _buildModoEdicao(Client client, List<ClientCultura> culturas) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _editando = false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                const Spacer(),
                const Text(
                  'Editar Cliente',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _salvarEdicao,
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: PremiumTokens.brandGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: ClientAvatarWidget(
                            fotoPath: _fotoPathEdit,
                            nome: _nomeCtrl.text.isEmpty
                                ? client.name
                                : _nomeCtrl.text,
                            radius: 48,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Toque para alterar foto',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Identificação
                  _sectionTitle('Identificação'),
                  _field(_nomeCtrl, 'Nome Completo *',
                      validator: (v) {
                    if (v == null || v.trim().length < 2)
                      return 'Mínimo 2 caracteres';
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _field(_emailCtrl, 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v))
                      return 'E-mail inválido';
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _field(_telefoneCtrl, 'Telefone',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(_cpfCnpjCtrl, 'CPF / CNPJ',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _dataNascimentoEdit ?? DateTime(1990),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (p != null)
                        setState(() => _dataNascimentoEdit = p);
                    },
                    child: AbsorbPointer(
                      child: _field(
                        TextEditingController(
                            text: _dataNascimentoEdit != null
                                ? _formatDate(_dataNascimentoEdit!)
                                : ''),
                        'Data de Nascimento',
                        suffixIcon: const Icon(Icons.calendar_today,
                            size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Localização
                  _sectionTitle('Localização'),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _field(_cidadeCtrl, 'Cidade')),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _field(
                          _ufCtrl,
                          'UF',
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(2),
                            _UpperCaseFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Propriedade
                  _sectionTitle('Propriedade'),
                  _field(_areaTotalCtrl, 'Área Total (ha)',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true)),
                  const SizedBox(height: 16),
                  _chipRow(
                      'Tipo',
                      const ['propria', 'arrendada', 'mista'],
                      const ['Própria', 'Arrendada', 'Mista'],
                      _tipoPropriedadeEdit,
                      (v) => setState(() => _tipoPropriedadeEdit = v)),
                  const SizedBox(height: 16),
                  _chipRow(
                      'Irrigação',
                      const ['sequeiro', 'irrigado', 'misto'],
                      const ['Sequeiro', 'Irrigado', 'Misto'],
                      _sistemaIrrigacaoEdit,
                      (v) => setState(() => _sistemaIrrigacaoEdit = v)),
                  const SizedBox(height: 16),
                  _chipRow(
                      'Solo',
                      const ['arenoso', 'argiloso', 'misto', 'outro'],
                      const ['Arenoso', 'Argiloso', 'Misto', 'Outro'],
                      _soloTipoEdit,
                      (v) => setState(() => _soloTipoEdit = v)),
                  const SizedBox(height: 16),
                  _field(_regiaoCtrl, 'Região Agrícola'),
                  const SizedBox(height: 12),
                  _field(_safraCtrl, 'Safra Atual'),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usa Assistência Técnica'),
                    value: _usaAssistenciaEdit,
                    activeColor: PremiumTokens.brandGreen,
                    onChanged: (v) =>
                        setState(() => _usaAssistenciaEdit = v),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: Visibility(
                      visible: _usaAssistenciaEdit,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _field(
                            _tecnicoCtrl, 'Técnico Responsável'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Culturas
                  _sectionTitle('Culturas'),
                  if (_culturasEditadas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(children: [
                        Icon(Icons.eco, size: 36, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Nenhuma cultura',
                            style: TextStyle(color: Colors.grey[600])),
                      ]),
                    )
                  else
                    ...List.generate(
                      _culturasEditadas.length,
                      (i) => CulturaItemWidget(
                        cultura: _culturasEditadas[i],
                        onRemove: () =>
                            setState(() => _culturasEditadas.removeAt(i)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.add,
                        color: PremiumTokens.brandGreen),
                    label: const Text('+ Adicionar Cultura',
                        style:
                            TextStyle(color: PremiumTokens.brandGreen)),
                    onPressed: _abrirBottomSheetCultura,
                  ),
                  const SizedBox(height: 28),

                  // Observações
                  _sectionTitle('Observações'),
                  TextFormField(
                    controller: _obsCtrl,
                    decoration: _deco('Observações'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13)),
            ),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontSize: 14))),
          ],
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextFormField(
        controller: ctrl,
        decoration: _deco(label, suffixIcon: suffixIcon),
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
        maxLines: maxLines,
        validator: validator,
        inputFormatters: inputFormatters,
      );

  InputDecoration _deco(String label, {Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: suffixIcon,
      );

  Widget _chipRow(
    String title,
    List<String> options,
    List<String> labels,
    String? selected,
    ValueChanged<String?> onSelected,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: List.generate(options.length, (i) {
              final isSel = selected == options[i];
              return ChoiceChip(
                label: Text(labels[i]),
                selected: isSel,
                selectedColor: PremiumTokens.brandGreen,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : Colors.black87,
                  fontWeight:
                      isSel ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (_) =>
                    onSelected(isSel ? null : options[i]),
              );
            }),
          ),
        ],
      );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FarmItem extends StatelessWidget {
  final String name;
  final String area;
  final VoidCallback? onTap;

  const _FarmItem({required this.name, required this.area, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(area, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}

// ══════════════════════════════════════════════════════════════════════════════
// Hub: Painel de Estatísticas do Cliente — WS-4 / WS-8
// ══════════════════════════════════════════════════════════════════════════════

class _ClientStatsPanel extends ConsumerWidget {
  const _ClientStatsPanel({required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(clientStatsProvider(clientId));

    return statsAsync.when(
      loading: () => const _StatsLoadingSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contadores
          _sectionTitle(context, 'Resumo'),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(
                label: 'Visitas',
                value: '${stats.totalVisitas}',
                icon: Icons.directions_walk,
              ),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Ocorrências',
                value: '${stats.totalOcorrencias}',
                icon: Icons.bug_report_outlined,
              ),
              const SizedBox(width: 12),
              _StatTile(
                label: 'Desenhos',
                value: '${stats.totalDesenhos}',
                icon: Icons.crop_square_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Próximos eventos
          if (stats.proximosEventos.isNotEmpty) ...[
            _sectionTitle(context, 'Próximos Eventos'),
            const SizedBox(height: 8),
            ...stats.proximosEventos.map(
              (e) => _EventoItem(
                titulo: e['titulo'] as String? ?? 'Evento',
                data: _formatDate(e['data_inicio_planejada'] as String?),
                tipo: e['tipo'] as String? ?? '',
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Últimas visitas
          if (stats.ultimasVisitas.isNotEmpty) ...[
            _sectionTitle(context, 'Últimas Visitas'),
            const SizedBox(height: 8),
            ...stats.ultimasVisitas.map(
              (v) => _VisitaItem(
                data: _formatDate(v['start_at_real'] as String?),
                duracao: v['duracao_min'] as int?,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Text(
        t,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      );

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '—';
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PremiumTokens.brandGreen.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: PremiumTokens.brandGreen),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _EventoItem extends StatelessWidget {
  const _EventoItem({required this.titulo, required this.data, required this.tipo});
  final String titulo;
  final String data;
  final String tipo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PremiumTokens.brandGreen.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event, size: 14, color: PremiumTokens.brandGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('$data${tipo.isNotEmpty ? ' · $tipo' : ''}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitaItem extends StatelessWidget {
  const _VisitaItem({required this.data, this.duracao});
  final String data;
  final int? duracao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_walk, size: 14, color: Colors.blueGrey),
          ),
          const SizedBox(width: 10),
          Text(data, style: const TextStyle(fontSize: 13)),
          if (duracao != null) ...[
            const SizedBox(width: 8),
            Text('· ${duracao}min',
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ],
      ),
    );
  }
}

class _StatsLoadingSkeleton extends StatelessWidget {
  const _StatsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
