import 'package:flutter/material.dart';

import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';

class ClimaWhatsAppHeroResumo extends StatelessWidget {
  const ClimaWhatsAppHeroResumo({
    super.key,
    required this.payload,
    required this.accent,
    required this.titleColor,
    required this.labelColor,
    required this.cardBg,
    required this.cardRadius,
    required this.isIos,
    required this.onTap,
  });

  final ClimaSharePayload payload;
  final Color accent;
  final Color titleColor;
  final Color labelColor;
  final Color cardBg;
  final double cardRadius;
  final bool isIos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : SoloForteSheetTokens.divider;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payload.previewEmoji,
                      style: const TextStyle(fontSize: 34, height: 1.1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payload.previewTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payload.previewSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: accent, size: 22),
                  ],
                ),
                if (payload.previewChips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: payload.previewChips
                        .map(
                          (label) => ClimaWhatsAppHeroChip(
                            label: label,
                            isIos: isIos,
                            labelColor: titleColor,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (payload.previewCampoLinha != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    payload.previewCampoLinha!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Toque para ver o card completo',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClimaWhatsAppHeroChip extends StatelessWidget {
  const ClimaWhatsAppHeroChip({
    super.key,
    required this.label,
    required this.isIos,
    required this.labelColor,
  });

  final String label;
  final bool isIos;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isIos
            ? SoloForteSheetSkinIos.badgeBackground
            : SoloForteSheetTokens.categoryBackground,
        borderRadius: BorderRadius.circular(999),
        border: isIos
            ? Border.all(color: SoloForteSheetSkinIos.badgeBorder)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isIos ? SoloForteSheetSkinIos.badgeText : labelColor,
        ),
      ),
    );
  }
}

class ClimaWhatsAppCityFilter extends StatelessWidget {
  const ClimaWhatsAppCityFilter({
    super.key,
    required this.cidades,
    required this.selecionada,
    required this.accent,
    required this.labelColor,
    required this.inputBg,
    required this.onSelected,
    required this.onMarcar,
  });

  final List<String> cidades;
  final String? selecionada;
  final Color accent;
  final Color labelColor;
  final Color inputBg;
  final ValueChanged<String?> onSelected;
  final VoidCallback? onMarcar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ENVIAR PARA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: labelColor,
                ),
              ),
              const Spacer(),
              if (onMarcar != null)
                TextButton(
                  onPressed: onMarcar,
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Marcar todos',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ClimaWhatsAppCityChip(
                  label: 'Todas',
                  selected: selecionada == null,
                  accent: accent,
                  labelColor: labelColor,
                  inputBg: inputBg,
                  onTap: () => onSelected(null),
                ),
                for (final cidade in cidades) ...[
                  const SizedBox(width: 8),
                  ClimaWhatsAppCityChip(
                    label: cidade,
                    selected: climaCityMatchKey(cidade) == selecionada,
                    accent: accent,
                    labelColor: labelColor,
                    inputBg: inputBg,
                    onTap: () => onSelected(climaCityMatchKey(cidade)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClimaWhatsAppCityChip extends StatelessWidget {
  const ClimaWhatsAppCityChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.labelColor,
    required this.inputBg,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color labelColor;
  final Color inputBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : inputBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : labelColor,
            ),
          ),
        ),
      ),
    );
  }
}

class ClimaWhatsAppProducerGroup extends StatelessWidget {
  const ClimaWhatsAppProducerGroup({
    super.key,
    required this.clientes,
    required this.selecionados,
    required this.accent,
    required this.titleColor,
    required this.labelColor,
    required this.divider,
    required this.cardBg,
    required this.cardRadius,
    required this.onToggle,
  });

  final List<ClientSummary> clientes;
  final Set<String> selecionados;
  final Color accent;
  final Color titleColor;
  final Color labelColor;
  final Color divider;
  final Color cardBg;
  final double cardRadius;
  final void Function(String tel, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Column(
          children: [
            for (var i = 0; i < clientes.length; i++) ...[
              ClimaWhatsAppProducerRow(
                cliente: clientes[i],
                selected: climaPhoneIsValid(clientes[i].phone) &&
                    selecionados.contains(clientes[i].phone),
                accent: accent,
                titleColor: titleColor,
                labelColor: labelColor,
                onToggle: onToggle,
              ),
              if (i < clientes.length - 1)
                Divider(
                  color: divider,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ClimaWhatsAppProducerRow extends StatelessWidget {
  const ClimaWhatsAppProducerRow({
    super.key,
    required this.cliente,
    required this.selected,
    required this.accent,
    required this.titleColor,
    required this.labelColor,
    required this.onToggle,
  });

  final ClientSummary cliente;
  final bool selected;
  final Color accent;
  final Color titleColor;
  final Color labelColor;
  final void Function(String tel, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final tel = cliente.phone;
    final hasPhone = climaPhoneIsValid(tel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPhone && tel != null
            ? () => onToggle(tel, !selected)
            : null,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: hasPhone ? titleColor : labelColor,
                        ),
                      ),
                      Text(
                        hasPhone ? tel! : 'Sem telefone cadastrado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ClimaWhatsAppSelectionCheck(
                  selected: hasPhone && selected,
                  enabled: hasPhone,
                  accent: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClimaWhatsAppSelectionCheck extends StatelessWidget {
  const ClimaWhatsAppSelectionCheck({
    super.key,
    required this.selected,
    required this.enabled,
    required this.accent,
  });

  final bool selected;
  final bool enabled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final border = enabled
        ? (selected ? accent : const Color(0xFF8E8E93))
        : const Color(0xFF48484A);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected && enabled ? accent : Colors.transparent,
        border: Border.all(color: border, width: 2),
      ),
      child: selected && enabled
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class ClimaWhatsAppEmptyProducers extends StatelessWidget {
  const ClimaWhatsAppEmptyProducers({
    super.key,
    required this.message,
    required this.labelColor,
    this.onClearFilter,
    this.accent,
  });

  final String message;
  final Color labelColor;
  final VoidCallback? onClearFilter;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 96,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: labelColor,
              ),
            ),
            if (onClearFilter != null && accent != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: onClearFilter,
                style: TextButton.styleFrom(foregroundColor: accent),
                child: const Text(
                  'Ver todas as cidades',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
