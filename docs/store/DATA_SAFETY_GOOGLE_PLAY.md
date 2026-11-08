# Google Play — Data Safety

Preencher em Play Console → App content → Data safety. Visão da ficha: `docs/store/PLAY_CONSOLE.md`.

O app coleta dados. Não compartilha com terceiros: o Supabase trata os dados a pedido do SoloForte, e a Play não classifica esse processamento como sharing.

Criptografia em trânsito: sim (HTTPS). Exclusão pedida pelo usuário: sim.

---

## Tipos

Finalidade de todos: funcionalidade do app. Nenhum é usado para publicidade.

| Tipo na ficha | Coletado | Obrigatório | No SoloForte |
|---|---|---|---|
| Precise location | Sim | O usuário pode recusar | GPS com o app aberto |
| Approximate location | Sim | O usuário pode escolher a aproximada | Quando o Android concede só a aproximada |
| Name | Sim | Sim, para a conta | Nome da conta |
| Email address | Sim | Sim, para a conta | Login |
| User IDs | Sim | Sim | Identificador da conta |
| Phone number | Sim | Opcional | Número digitado em cliente ou caso |
| Photos | Sim | Opcional | Fotos de ocorrência, relatório e perfil |
| Voice or sound recordings | Sim | Opcional | Áudio de até 30 segundos na ocorrência |
| Other user-generated content | Sim | Opcional | Clientes, fazendas, talhões, visitas, ocorrências e relatórios |
| Customer support | Sim | Opcional | Mensagens de feedback |

**Compra in-app (planos):** se o formulário pedir histórico de compra / in-app purchases, marcar conforme a compra via Play Billing (o app não armazena cartão; grava plano e `payment_id` em `user_plans`).

Não marcar: vídeos, arquivos em geral, contatos, saúde, **dados de cartão ou conta bancária**, mensagens, calendário, crash logs, diagnósticos, interações do app, histórico de busca, ID de publicidade.

Os dados ficam na conta. Não marcar “processed ephemerally”.

---

## Exclusão

| Campo | Valor |
|---|---|
| O usuário pode pedir exclusão | Sim |
| No app | Configurações → Excluir minha conta |
| Link web | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/exclusao-de-conta.html` |

---

## Permissões do AAB que deve ser enviado

| Permissão | Uso |
|---|---|
| ACCESS_FINE_LOCATION | Mapa, visitas e ocorrências, com o app aberto |
| ACCESS_COARSE_LOCATION | Quando o usuário concede só a localização aproximada |
| CAMERA | Foto de campo |
| RECORD_AUDIO | Áudio da ocorrência |
| POST_NOTIFICATIONS | Lembretes da agenda |
| SCHEDULE_EXACT_ALARM | Horário do lembrete; se negado, o app usa alarme inexato |
| READ_EXTERNAL_STORAGE | Só até o Android 12 (`maxSdkVersion=32`) |

`READ_MEDIA_IMAGES`, `FOREGROUND_SERVICE` e `FOREGROUND_SERVICE_LOCATION` não são pedidas no AAB da Fase 1. Foto da galeria entra pelo seletor do sistema. Sem `ACCESS_BACKGROUND_LOCATION`.

---

## Política de privacidade

```
https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/
```
