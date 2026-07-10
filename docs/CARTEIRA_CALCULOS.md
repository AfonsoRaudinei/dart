# Carteira — Regras de Cálculo Oficiais

**Módulo:** `lib/modules/carteira/`
**Status:** REFERÊNCIA — base para implementação e testes
**Data:** Jul/2026

---

## Variáveis Fundamentais

| Variável | Origem | Descrição |
|---|---|---|
| `areaHa` | `clients.area_total` via SQLite compartilhado | Área total do cliente em hectares |
| `valorGrao` | `carteira_config.valor_grao` | Preço do grão em R$ por saca (ex: R$ 112,00) |
| `valorReferencia` | `categoria.valorReferencia` | Custo/meta de referência na unidade da categoria |
| `metaQuantidade` | `carteira_metas.quantidade` | Alvo numérico total na unidade da categoria |
| `closedPercent` | `carteira_lancamentos.closed_percent` | Percentual fechado pelo agrônomo (0–100) |

---

## Regra Geral — Campo Custo/Referência

O campo `valorReferencia` é **obrigatório** para todas as unidades:

- `realPorHa` → R$/ha
- `toneladaPorHa` → ton/ha
- `bigBag` → Big Bag
- `sacas60k` → Sacas 60k

Sem ele preenchido, nenhum cálculo de oportunidade ou progresso pode ser executado.

---

## Cálculo 1 — Sentido Direto: R$ → Sacas/ha

Usado quando o agrônomo quer entender o total de compra de um cliente em sacas equivalentes.

```
custoTotalHa    = totalCompraCliente / areaHa
sacasPorHa      = custoTotalHa / valorGrao
```

**Exemplo:**
- Total comprado: R$ 300.000
- Área: 100 ha
- Preço do grão: R$ 112/saca

```
custoTotalHa = 300.000 / 100  = R$ 3.000/ha
sacasPorHa   = 3.000 / 112    = 26,78 sacas/ha
```

---

## Cálculo 2 — Sentido Inverso: Sacas → R$

Usado para converter meta ou realizado de uma categoria para valor financeiro.

```
valorHa    = sacasPorHa × valorGrao
valorTotal = valorHa × areaHa
```

**Exemplo (fertilizante):**
- Meta: 13 sacas/ha
- Preço do grão: R$ 112/saca
- Área: 100 ha

```
valorHa    = 13 × 112       = R$ 1.456/ha
valorTotal = 1.456 × 100    = R$ 145.600
```

---

## Cálculo 3 — Quantidade Realizada (derivada do percentual)

A quantidade realizada **nunca é digitada diretamente**. É sempre derivada da meta e do percentual fechado.

```
realizado   = metaQuantidade × (closedPercent / 100)
```

**Exemplos:**
- Meta = 90 sacas, fechou 100% → realizado = 90 sacas
- Meta = 90 sacas, fechou 50%  → realizado = 45 sacas
- Meta = 90 sacas, fechou 0%   → realizado = 0 sacas

---

## Cálculo 4 — Oportunidade Residual (volume)

Quanto ainda pode ser fechado em unidade física.

```
oportunidadeVolume = metaQuantidade - realizado
                   = metaQuantidade × (1 - closedPercent / 100)
```

**Exemplo:**
- Meta = 90 sacas, fechou 50%
- realizado = 45 sacas
- oportunidadeVolume = 90 - 45 = **45 sacas em aberto**

---

## Cálculo 5 — Oportunidade Residual em R$ (ADR-029)

Converte a oportunidade de volume para valor financeiro.

```
oportunidadeReais = oportunidadeVolume × valorGrao
```

Ou diretamente pela área (quando unidade é R$/ha):

```
closedValuePerHa   = valorReferencia × (closedPercent / 100)
residualValuePerHa = valorReferencia - closedValuePerHa
oportunidadeReais  = residualValuePerHa × areaHa
```

**Exemplo completo:**
- Meta: 2.678 sacas totais (26,78 sacas/ha × 100 ha)
- Fechou: 50%
- realizado = 1.339 sacas
- oportunidadeVolume = 1.339 sacas
- oportunidadeReais = 1.339 × R$ 112 = **R$ 149.968**

---

## Cálculo 6 — Progresso por Categoria (safra ativa)

```
progressoPct = clamp(closedPercent, 0, 100)
```

Quando há múltiplos lançamentos de um cliente na mesma categoria:

```
progressoPct = clamp(SUM(lancamento.closedPercent), 0, 100)
```

---

## Cálculo 7 — Progresso por Barra (tela do cliente)

```
pct = clamp((realizado / metaQuantidade) × 100, 0, 100)
```

Como `realizado` é derivado do `closedPercent`, isso equivale a:

```
pct = clamp(closedPercent, 0, 100)
```

Os dois modelos convergem quando `quantidade` é sempre calculada, nunca digitada.

---

## Cálculo 8 — Conversão R$/ha → Sacas/ha (aba Categorias)

Exibição auxiliar quando unidade da categoria é `realPorHa`.

```
custoSacasHa = valorReferencia / valorGrao
```

Válido apenas quando:
- `unidade == realPorHa`
- `valorReferencia > 0`
- `valorGrao > 0`

**Exemplo:**
- valorReferencia = R$ 1.456/ha (fertilizante)
- valorGrao = R$ 112/saca
- custoSacasHa = 1.456 / 112 = **13 sacas/ha**

---

## Resumo: Hierarquia dos Cálculos

```
valorGrao (carteira_config)
    │
    ├── Sentido direto:  totalCompra ÷ areaHa ÷ valorGrao = sacas/ha
    │
    ├── Sentido inverso: sacasPorHa × valorGrao × areaHa = R$ total
    │
    └── Oportunidade:
            metaQuantidade
                × closedPercent/100         → realizado (derivado, nunca digitado)
                × (1 - closedPercent/100)   → oportunidadeVolume
                × valorGrao                 → oportunidadeReais
```

---

## Regra de Ouro

> **`quantidade` nunca é input do usuário.**
> É sempre output calculado: `metaQuantidade × (closedPercent / 100)`
> O agrônomo informa apenas **o percentual fechado**.
> O sistema deriva o volume e o valor.

---

## Impacto na Dívida Técnica Existente

O `LancamentoFormDialog` hoje persiste `quantidade: 0.0` sempre.
Com esta regra, o correto é:

```
quantidade = metaQuantidade × (closedPercent / 100)
```

Isso unifica os dois modelos de progresso (legado % e novo volume) em uma única fonte de verdade: o `closedPercent`.
