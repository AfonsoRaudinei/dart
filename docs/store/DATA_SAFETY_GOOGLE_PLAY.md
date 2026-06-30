# Google Play — Data Safety Form

Preencher no Play Console → App content → Data safety.

---

## O app coleta ou compartilha dados?

**Sim** — os tipos abaixo são coletados.

---

## Tipos de dados

| Tipo | Coletado | Compartilhado | Obrigatório | Finalidade |
|------|----------|---------------|-------------|------------|
| **E-mail** | Sim | Não | Sim (conta) | Autenticação |
| **Nome** | Sim | Não | Sim (conta) | Identificação do usuário |
| **Localização precisa** | Sim | Não | Sim (funcionalidade) | Mapa, visitas, ocorrências |
| **Fotos** | Sim | Não | Opcional | Ocorrências e perfil |
| **Outros conteúdos gerados pelo usuário** | Sim | Não | Opcional | Dados agrícolas, relatórios, feedback |
| **Identificadores do app** | Sim | Não | Sim | Sessão / sync |
| **Diagnóstico (crash logs)** | Não* | Não | — | — |

\* Nenhum SDK de crash analytics integrado na v1.0.0.

---

## Segurança dos dados

| Pergunta | Resposta |
|----------|----------|
| Dados criptografados em trânsito | **Sim** (HTTPS / TLS) |
| Usuário pode solicitar exclusão | **Sim** (Configurações → Excluir conta) |
| Compromisso Families / crianças | App não direcionado a crianças |

---

## Permissões declaradas no manifest

| Permissão | Justificativa |
|-----------|---------------|
| ACCESS_FINE_LOCATION | Posição no mapa e visitas de campo |
| ACCESS_COARSE_LOCATION | Fallback de localização |
| CAMERA | Fotos de ocorrências e perfil |
| READ_MEDIA_IMAGES | Galeria para anexos |
| POST_NOTIFICATIONS | Alertas de geofence (chegada/saída) |

**Não declarado:** ACCESS_BACKGROUND_LOCATION (removido na v1).

---

## URL da política de privacidade

Mesma URL configurada em `AppConfig.privacyPolicyUrl` / Metadados das lojas.
