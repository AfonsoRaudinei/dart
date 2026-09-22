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
