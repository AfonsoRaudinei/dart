# Metadados das Lojas — SoloForte App v1.0.0

Documento de referência para App Store Connect e Google Play Console.

---

## Identificação

| Campo | Valor |
|-------|-------|
| **Nome do app** | SoloForte |
| **Bundle ID / Application ID** | `com.soloforte.app` |
| **Versão** | 1.0.0 (build 1) |
| **Idioma principal** | Português (Brasil) |
| **Categoria Apple** | Produtividade |
| **Categoria Google** | Negócios |
| **Classificação etária** | 4+ / Livre (sem conteúdo restrito) |

---

## Descrição curta (Google Play — 80 caracteres)

```
Consultoria agrícola de campo: mapa, visitas, ocorrências e sync offline.
```

---

## Descrição completa (pt-BR)

```
SoloForte é o aplicativo mobile para consultores agrícolas que trabalham em campo.

PRINCIPAIS RECURSOS
• Mapa técnico fullscreen com talhões e camadas de satélite
• Registro de visitas de campo com geolocalização
• Ocorrências agronômicas georreferenciadas (doenças, pragas, daninhas, nutrientes, água)
• Funcionamento 100% offline — ideal para áreas sem sinal
• Sincronização silenciosa quando a internet retorna
• Cadastro de clientes, fazendas e talhões
• Relatórios e agenda de atividades

PARA QUEM É
Consultores, técnicos agrícolas e equipes de campo que precisam registrar
informações no local e sincronizar com a nuvem depois.

PRIVACIDADE
Coletamos localização, fotos e dados de conta apenas para operar o serviço.
Política de privacidade disponível no app e em nosso site.
```

---

## Palavras-chave (Apple — 100 caracteres)

```
agrícola,campo,consultoria,mapa,visitas,ocorrências,offline,fazenda,talhão,agronomia
```

---

## URL de suporte

```
mailto:privacidade@soloforte.app
```

## URL política de privacidade

```
https://raw.githubusercontent.com/AfonsoRaudinei/dart/main/docs/legal/politica-de-privacidade.md
```

*(Substituir por domínio HTTPS próprio antes da submissão final.)*

---

## Screenshots recomendados (mín. 4 por plataforma)

| # | Tela | O que mostrar |
|---|------|---------------|
| 1 | Mapa privado | Talhões, GPS ativo, pins de ocorrência |
| 2 | Visita ativa | Sheet de visita / check-in |
| 3 | Nova ocorrência | Modo armado + dialog de categoria |
| 4 | Clientes / Agenda | Lista de clientes ou eventos |
| 5 | Configurações | Sync pendente, privacidade, conta |

**Resoluções:**
- iPhone 6.7": 1290 × 2796 px
- Android phone: 1080 × 1920 px mínimo

Capturar em dispositivo real ou emulador com dados de demonstração.

---

## Export compliance (Apple)

| Campo | Valor |
|-------|-------|
| **ITSAppUsesNonExemptEncryption** | **NO** (`false` em `ios/Runner/Info.plist`) |
| **Justificativa** | App usa apenas TLS/HTTPS padrão (Supabase, tiles de mapa). Sem criptografia proprietária. |

No App Store Connect, responder **No** à pergunta de criptografia não isenta (Export Compliance).

---

## Notas de release (v1.0.0)

```
Lançamento inicial do SoloForte para consultoria agrícola de campo.
Inclui mapa técnico, visitas, ocorrências offline, sync Supabase e autenticação segura.
```
