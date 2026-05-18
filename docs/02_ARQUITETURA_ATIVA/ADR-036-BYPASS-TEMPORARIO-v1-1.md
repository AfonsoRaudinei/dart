# ADR-036: Manter Bypass Temporário REGRA-SHEET-1 para v1.1

**Status**: ACEITO (temporário)  
**Data**: 2026-05-18  
**Decisor**: Auditoria Arquitetural v1.1

---

## Contexto

Durante auditoria pré-release v1.1 foi identificado que:

1. `tool/arch_check.sh` possui bypass que decrementa `VIOLATIONS` após detecção de `showModalBottomSheet` direto.
2. Existem violações reais em múltiplos arquivos.
3. Remover o bypass imediatamente bloquearia o release v1.1.

Evidência:

```bash
VIOLATIONS=$((VIOLATIONS - 1))
```

## Problema

Opção A: remover bypass agora e bloquear release.  
Opção B: manter bypass e mascarar violações.

Risco da opção A: atraso de release com migração ampla de sheets.  
Risco da opção B: gate não reflete estado real se não houver comunicação explícita.

## Decisão

Manter bypass temporariamente em v1.1 com controles explícitos:

1. Documentação formal neste ADR.
2. Warning visível no output do `arch_check.sh`.
3. Roadmap de remoção do bypass em v1.2.
4. Revisão manual para evitar novos usos diretos.

## Implementação

No bloco da `REGRA-SHEET-1` em `tool/arch_check.sh`:

- manter incremento de violação quando detecta uso direto;
- manter decremento compensatório temporário (bypass);
- imprimir warning explícito referenciando ADR-036.

## Timeline

### v1.1
- bypass mantido e documentado;
- warning explícito ativo;
- release não bloqueado por dívida legada.

### v1.2
- mapear e migrar usos diretos de `showModalBottomSheet` para wrapper;
- remover bypass;
- tornar falha de sheet bloqueadora real.

### v1.3+
- enforcement rígido no CI para uso direto.

## Impacto

Curto prazo: release v1.1 preservado com dívida visível.  
Médio prazo: migração planejada e remoção do bypass.  
Longo prazo: conformidade arquitetural enforced por gate real.

## Mitigações

- checklist de PR para uso de `showSoloForteSheet`;
- issue rastreando remoção do bypass no ciclo v1.2;
- warning explícito para reduzir falso senso de conformidade.

## Aprovação

- [x] Aceitar bypass temporário para v1.1
- [x] Documentar via ADR-036
- [x] Adicionar warning no `arch_check.sh`
- [x] Planejar remoção em v1.2

## Referências

- Auditoria Arquitetural v1.1
- ADR-027
- ADR-035
- `tool/arch_check.sh`
