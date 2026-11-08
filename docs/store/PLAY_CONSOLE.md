# Play Console — ficha da Fase 4

Respostas para colar no Google Play Console. Fontes oficiais consultadas em 8 de novembro de 2026: [target API](https://developer.android.com/google/play/requirements/target-sdk), [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), [exclusão de conta](https://support.google.com/googleplay/android-developer/answer/13327111), [fotos e vídeos](https://support.google.com/googleplay/android-developer/answer/14115180), [preparar para revisão](https://support.google.com/googleplay/android-developer/answer/9859455), [teste fechado](https://support.google.com/googleplay/android-developer/answer/14151465).

Application ID: **`com.soloforte.app`**. Versão no `pubspec.yaml`: **1.34.0 (311)**.

O AAB precisa ser o build em que `READ_MEDIA_IMAGES`, `FOREGROUND_SERVICE` e `FOREGROUND_SERVICE_LOCATION` saem do merge (`tools:node="remove"` na branch `cursor/store-phase1-binario-1136`). O `targetSdk` do Flutter 3.41.6 desta máquina é **36**. Assinar com a chave de release, nunca com a de debug. No App Bundle Explorer, conferir página de **16 KB**.

As URLs só valem depois de publicar `docs/legal/github-pages/`.

---

## 1. Ficha da loja

| Campo | Valor |
|---|---|
| App name | SoloForte |
| Default language | Portuguese (Brazil) |
| App or game | App |
| Free or paid | Free |
| Category | Business |
| Email | privacidade@soloforte.app |

**Short description** (73 caracteres, limite 80):

```
Consultoria agrícola de campo: mapa, visitas, ocorrências e sync offline.
```

**Full description:** o bloco em `docs/store/METADADOS_LOJAS.md`.

**Privacy policy:**

```
https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/
```

Gráficos que a Play pede e que não estão no repositório:

| Arte | Tamanho |
|---|---|
| Ícone | 512 × 512 PNG |
| Feature graphic | 1024 × 500 PNG ou JPG |
| Screenshots de telefone | pelo menos 2, proporção 9:16; 1080 × 1920 serve |

Telas, nesta ordem: mapa com talhão, visita, ocorrência, clientes ou agenda, Configurações com Excluir minha conta.

---

## 2. App content

### Privacy policy

A URL da seção 1.

### Ads

No. O app não tem anúncio.

### App access

All or some functionality is restricted.

Instruções e a conta `review@soloforte.app`: `docs/store/CONTA_DEMO_REVIEW.md`. A conta precisa existir no Supabase, com e-mail confirmado, um cliente, uma fazenda e um talhão.

### Content rating

Questionário IARC, categoria de app de utilidade / negócios, não jogo.

| Pergunta | Resposta |
|---|---|
| Violência, sexo, linguagem, medo, humor grosseiro, substâncias | Não |
| Usuários interagem ou trocam conteúdo entre si | Não |
| O app compartilha a localização atual com outras pessoas | Não |
| Compras digitais, loot box, aposta | Não |

Nota esperada: **Livre / Everyone**. Público-alvo: **18 anos ou mais**. Não é app para crianças e não entra no programa Families.

### Target audience and content

Faixa 18+. “Appeals to children”: No.

### News, government, health, financial features

Não é app de notícias, governo nem saúde. Financial features: **My app doesn’t provide any financial features**. O checkout dentro do app está desligado.

### Data safety

Tabela completa: `docs/store/DATA_SAFETY_GOOGLE_PLAY.md`.

Resumo: coleta sim, compartilhamento com terceiros não (Supabase processa a pedido do app; isso não entra como “sharing”). Criptografia em trânsito: sim. Exclusão: sim.

Link de exclusão da conta:

```
https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/exclusao-de-conta.html
```

No app o caminho é Configurações → Excluir minha conta.

### Alarmes e lembretes

Declarar `SCHEDULE_EXACT_ALARM`. Texto em inglês para o formulário:

```
SoloForte schedules local notifications for agronomic calendar events (30-minute reminder and event start). SCHEDULE_EXACT_ALARM is required on Android 12+ to deliver time-sensitive field reminders. If the user denies exact alarms in system settings, the app falls back to inexact scheduling. Exact alarms are not used for ads, analytics, or cross-app tracking.
```

### Fotos

O AAB da Fase 1 não pede `READ_MEDIA_IMAGES`. A foto entra pelo seletor do sistema. Se a Play mostrar declaração de acesso amplo a fotos, a resposta é que o app não pede essa permissão.

### Localização

Precisa e aproximada, só com o app em uso, para mapa, visitas e ocorrências. Sem localização em segundo plano.

Se aparecer declaração de foreground service de localização: o app não chama `startForeground`. O serviço do geolocator fica só para o GPS com a tela aberta.

---

## 3. Teste fechado, se a conta for pessoal

Conta pessoal criada depois de 13 de novembro de 2023: a produção fica bloqueada até um teste fechado com **12 testadores inscritos sem interrupção por 14 dias**. Só então “Apply for production”. Conta de organização não passa por essa trava.

Fonte: [App testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465).

---

## 4. Ordem no Console

1. Criar o app `com.soloforte.app`, se ainda não existir.
2. Preencher a ficha, os gráficos e a política.
3. Completar App content com as respostas acima.
4. Enviar o AAB assinado (API 36, 16 KB, sem as permissões removidas na Fase 1) para teste interno ou fechado.
5. Pedir produção quando a conta permitir.
