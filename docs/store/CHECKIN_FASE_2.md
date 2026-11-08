# Check-in — Fase 2: Páginas públicas e conta de revisão

Data de conferência: 8 de novembro de 2026 (America/Araguaina).

Escopo desta fase: URL HTTPS de política, exclusão e suporte; conta de demonstração para Apple e Google; função de exclusão no Supabase. Não inclui binário, screenshots nem envio nas lojas.

**Status: 100% concluído** para este escopo.

---

## 1. Páginas públicas (GitHub Pages)

Repositório publicado: [SoloForte-Política-de-Privacidade](https://github.com/AfonsoRaudinei/SoloForte-Pol-tica-de-Privacidade) (`main`, raiz).

| Página | URL | Verificação (8 nov 2026) |
|---|---|---|
| Política de Privacidade | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/` | HTTP 200; iOS e Android; câmera, microfone, áudio (até 30 s), telefone e localização; exclusão em **Configurações → Excluir minha conta**; contato `privacidade@soloforte.app` |
| Pedido de exclusão | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/exclusao-de-conta.html` | HTTP 200 (antes 404); atende link web da Play |
| Suporte | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/suporte.html` | HTTP 200 (antes 404); Support URL HTTPS da Apple (`suporte@soloforte.com`) |

Fonte no app (referência, já na `main`): `docs/legal/github-pages/` e `docs/legal/github-pages/PUBLICAR.md`.

---

## 2. Repositório do app (AfonsoRaudinei/dart)

| PR | Conteúdo | Estado |
|---|---|---|
| [#406](https://github.com/AfonsoRaudinei/dart/pull/406) | HTML das páginas + metadados das lojas | Merged (`2026-11-08T15:06:23Z`) |
| [#414](https://github.com/AfonsoRaudinei/dart/pull/414) | `CONTA_DEMO_REVIEW.md` — itens marcados como concluídos | Merged (`2026-11-08T15:31:25Z`) |

O app já aponta a política para a URL do GitHub Pages (`lib/core/constants/external_links.dart`).

---

## 3. Supabase (produção, `pyoejhhkjlrjijiviryq`)

| Item | Estado |
|---|---|
| Edge Function `delete-user` | Publicada, revisão **v15** (inclui limpeza de `producer_client_links`, alinhada ao repo) |
| Conta `review@soloforte.app` | Criada, e-mail confirmado |
| Dados demo | Cliente **Fazenda Demo** → fazenda (50 ha) → talhão **Talhão Demo 01** (10 ha, polígono) |

Credenciais e roteiro para o revisor: `docs/store/CONTA_DEMO_REVIEW.md` (rotacionar a senha antes do Submit nas lojas).

---

## 4. Uso nas Fases 3 e 4

Com a Fase 2 fechada, as fichas podem colar:

| Campo | URL |
|---|---|
| Privacy Policy (Apple e Play) | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/` |
| Support (Apple) | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/suporte.html` |
| Exclusão (Play Data safety) | `https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/exclusao-de-conta.html` |
| App access / notas de review | `docs/store/CONTA_DEMO_REVIEW.md` |

---

## 5. Fora da Fase 2 (próximo passo: Fases 1, 3 e 4)

- Binário release (permissões, privacy manifest, AAB/IPA assinados) — Fase 1.
- Preenchimento e envio no App Store Connect e Play Console — Fases 3 e 4.
- Screenshots, ícone 512, feature graphic 1024×500, upload IPA/AAB.
