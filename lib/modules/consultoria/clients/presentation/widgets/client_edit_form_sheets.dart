part of 'client_edit_form.dart';

extension _ClientEditFormSheets on _ClientEditFormState {
  Future<void> _pickImage() async {
    await showSoloForteSheet<void>(
      context: context,
      showDragHandle: false,
      useSafeArea: false,
      builder: (ctx) {
        final ios = soloForteSheetIsIos(ctx);
        final icon = ios ? SoloForteSheetSkinIos.iconStroke : null;
        final title = ios ? SoloForteSheetSkinIos.titleColor : null;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: icon),
                title: Text('Câmera', style: TextStyle(color: title)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  if (!mounted) return;
                  if (picked != null) {
                    _patch(() => _fotoPathEdit = picked.path);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: icon),
                title: Text('Galeria', style: TextStyle(color: title)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (!mounted) return;
                  if (picked != null) {
                    _patch(() => _fotoPathEdit = picked.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ThemeData _lightFormTheme(bool isIos) => ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: isIos
              ? SoloForteSheetSkinIos.ctaBackground
              : PremiumTokens.brandGreen,
        ),
      );

  ButtonStyle _sheetCtaStyle(bool isIos) => ElevatedButton.styleFrom(
        backgroundColor: isIos
            ? SoloForteSheetSkinIos.ctaBackground
            : PremiumTokens.brandGreen,
        foregroundColor:
            isIos ? SoloForteSheetSkinIos.ctaText : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isIos ? SoloForteSheetSkinIos.ctaRadius : 8,
          ),
        ),
      );

  Future<void> _abrirBottomSheetCultura() async {
    final formKey = GlobalKey<FormState>();
    CulturaTipo? culturaSel;
    final areaCtrl = TextEditingController();
    final variedadeCtrl = TextEditingController();
    final safraCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    await showSoloForteSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: false,
      builder: (ctx) {
        final ios = soloForteSheetIsIos(ctx);
        final titleColor = ios ? SoloForteSheetSkinIos.titleColor : null;
        return StatefulBuilder(
          builder: (ctx, setS) => Theme(
            data: _lightFormTheme(ios),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Adicionar Cultura',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<CulturaTipo>(
                        decoration: _deco('Cultura *'),
                        items: CulturaTipo.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.label),
                              ),
                            )
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
                          decimal: true,
                        ),
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
                          style: _sheetCtaStyle(ios),
                          onPressed: () {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            final nova = ClientCultura(
                              id: const Uuid().v4(),
                              clientId: widget.client.id,
                              cultura: culturaSel!.name,
                              areaHa: double.parse(areaCtrl.text),
                              variedade: variedadeCtrl.text.isEmpty
                                  ? null
                                  : variedadeCtrl.text,
                              safra: safraCtrl.text.isEmpty
                                  ? null
                                  : safraCtrl.text,
                              observacao: obsCtrl.text.isEmpty
                                  ? null
                                  : obsCtrl.text,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            Navigator.of(ctx).pop();
                            _patch(() => _culturasEditadas.add(nova));
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
      },
    );
  }

  Future<void> _abrirBottomSheetArea() async {
    final formKey = GlobalKey<FormState>();
    final areaCtrl = TextEditingController();
    String? tipoSelecionado;

    await showSoloForteSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: false,
      builder: (ctx) {
        final ios = soloForteSheetIsIos(ctx);
        final titleColor = ios ? SoloForteSheetSkinIos.titleColor : null;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Theme(
            data: _lightFormTheme(ios),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Adicionar Área',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: areaCtrl,
                        decoration: _deco('Tamanho da área (ha) *'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final area = _parseArea(value);
                          if (area == null || area <= 0) {
                            return 'Informe área > 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _deco('Tipo da área *'),
                        items: const [
                          DropdownMenuItem(
                            value: 'propria',
                            child: Text('Própria'),
                          ),
                          DropdownMenuItem(
                            value: 'arrendada',
                            child: Text('Arrendada'),
                          ),
                        ],
                        onChanged: (value) =>
                            setModalState(() => tipoSelecionado = value),
                        validator: (value) =>
                            value == null ? 'Selecione o tipo da área' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: _sheetCtaStyle(ios),
                          onPressed: () {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            _patch(() {
                              _areasPropriedadeEditadas.add(
                                _AreaPropriedade(
                                  areaHa: _parseArea(areaCtrl.text)!,
                                  tipo: tipoSelecionado!,
                                ),
                              );
                              _sincronizarResumoAreas();
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Adicionar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
