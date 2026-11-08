# App Store Connect — ficha da Fase 3

Respostas para colar no App Store Connect. Fonte oficial consultada em 8 de novembro de 2026: [Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/), [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), [age ratings](https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions/), [DSA](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-compliance-information/).

O binário iOS é `com.soloforte.soloforteApp`, só iPhone (`TARGETED_DEVICE_FAMILY = 1`). A ficha tem de ser desse bundle. `com.soloforte.app` é o ID do Android.

Versão no `pubspec.yaml`: **1.34.0 (311)**. No TestFlight, o build enviado precisa ser maior que o último aceito.

As URLs abaixo só valem depois de publicar `docs/legal/github-pages/` (ver `PUBLICAR.md`).

---

## 1. App Information

| Campo | Valor |
|---|---|
| Name | SoloForte |
| Subtitle | Consultoria agrícola de campo |
| Primary language | Portuguese (Brazil) |
| Bundle ID | `com.soloforte.soloforteApp` |
| SKU | `soloforte-ios` |
| Primary category | Business |
| Secondary category | Productivity |
| Content rights | Yes. O mapa exibe tiles de terceiros (OpenStreetMap e provedores configurados no app), com atribuição no mapa. |

Subtitle tem 29 caracteres (limite 30).

---

## 2. URLs da versão (Portuguese Brazil)

| Campo | Valor |
|---|---|
| Privacy Policy URL | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/` |
| Support URL | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/suporte.html` |
| Marketing URL | deixar vazio |

---

## 3. Texto da versão 1.34.0

**Keywords** (84 caracteres):

```
agrícola,campo,consultoria,mapa,visitas,ocorrências,offline,fazenda,talhão,agronomia
```

**Description:** o bloco em `docs/store/METADADOS_LOJAS.md`.

**Promotional text:** deixar vazio.

**What's New:**

```
Consultoria agrícola de campo com mapa, visitas, ocorrências, fotos, áudio e sincronização offline.
```

**Copyright:** `2026 SoloForte`

**Price:** Free

---

## 4. Classificação etária

App Information → Age Ratings → Set Up Age Ratings.

O app guarda o trabalho de campo da própria conta. Não há rede social, chat entre usuários, anúncio, navegação livre na web, jogo, aposta nem conteúdo adulto. O WebView abre relatório gerado pelo app, não um navegador.

**In-App Controls:** não marcar Parental Controls nem Age Assurance.

**Capabilities:**

| Item | Resposta |
|---|---|
| Unrestricted Web Access | Não |
| User-Generated Content | Não |
| Social Media | Não |
| Messaging and Chat | Não |
| Advertising | Não |

**Frequência de cada conteúdo** (Mature Themes, Medical or Wellness, Sexuality or Nudity, Violence, Chance-Based Activities): **None**.

**Age Categories and Override:** Not Applicable. Não marcar Made for Kids.

**Age Suitability URL:** a mesma URL da política de privacidade.

A política diz que o público é profissional, maior de 18 anos. Isso não é conteúdo 18+ na escala da Apple. A nota calculada esperada é **4+**. Não elevar a nota no override.

---

## 5. App Privacy

App Privacy → Get Started. Tracking: **No**.

Dados coletados, ligados à identidade, sem tracking, finalidade **App Functionality**:

| Tipo na ficha | O que é no SoloForte |
|---|---|
| Name | Nome da conta |
| Email Address | E-mail de login |
| Phone Number | Telefone digitado em cliente ou caso |
| User ID | Identificador da conta |
| Precise Location | GPS com o app aberto |
| Photos or Videos | Fotos de ocorrência, relatório e perfil |
| Audio Data | Áudio de até 30 segundos na ocorrência |
| Other User Content | Clientes, fazendas, talhões, visitas, ocorrências e relatórios |
| Customer Support | Mensagens de feedback |

Não marcar: Contacts, Health, Financial Info, Browsing History, Search History, Advertising Data, Crash Data, Product Interaction, Coarse Location, Sensitive Info, Purchase History.

Perguntas de cada tipo: collected, linked to the user, not used for tracking, purpose App Functionality.

---

## 6. Export compliance

Pergunta de criptografia não isenta: **No**.

O `Info.plist` já tem `ITSAppUsesNonExemptEncryption = false`. O app usa HTTPS comum.

---

## 7. Disponibilidade e DSA

Para esta primeira versão, disponibilidade **só Brasil**.

A Apple exige declarar o status de trader mesmo assim. Quem não distribui na União Europeia não atua como trader na App Store. Em Business → Agreements → Digital Services Act, marque **This is not a trader account**.

Se a disponibilidade incluir qualquer país da UE, a resposta muda para trader. Aí entram telefone, e-mail e endereço, com verificação. Esses dados não estão no repositório.

---

## 8. Screenshots

Obrigatório pelo menos um, no tamanho de iPhone com Dynamic Island, tela média:

- 1179 × 2556, ou
- 1206 × 2622

PNG ou JPG, sem transparência. iPad não entra: o alvo do app é só iPhone.

Telas, nesta ordem:

1. Mapa com talhão e posição
2. Visita de campo
3. Ocorrência com foto ou áudio
4. Clientes ou agenda
5. Configurações, com Excluir minha conta visível

Capturar no simulador iPhone 16 ou 17 (ou aparelho equivalente) já logado na conta de revisão. Não há screenshot de loja no repositório.

---

## 9. App Review Information

Sign-in required: **Yes**.

Credenciais: `docs/store/CONTA_DEMO_REVIEW.md`. A conta `review@soloforte.app` precisa existir no Supabase de produção, com e-mail confirmado, um cliente, uma fazenda e um talhão, antes do Submit.

Contact: `privacidade@soloforte.app`. O telefone é o do titular da conta Apple.

**Notes** (colar em inglês):

```
SoloForte is a field app for agricultural consultants. Sign in with the demo account.

After login the map opens. Allow location when prompted.
The round button at the bottom right opens Clientes, Agenda and Configurações.
To record a field note: arm occurrence mode on the map, tap the map, and save.
Account deletion is in Configurações → Excluir minha conta. Please do not delete this demo account.
Paid checkout is turned off. The app shows plan status only.
The app is iPhone only. Location is used while the app is open.
```

Attachment: nenhum.

---

## 10. Ordem no Connect

1. Confirmar o app com bundle `com.soloforte.soloforteApp`.
2. Preencher seções 1 a 7.
3. Publicar as páginas HTML e testar as três URLs no navegador.
4. Subir o IPA 1.34.0 com build maior que o último aceito (o `pubspec.yaml` está em 311).
5. Anexar os screenshots e selecionar o build.
6. Colar a conta de revisão e enviar para review.

Sem as páginas no ar, sem a conta de revisão e sem os screenshots, o Submit volta.
