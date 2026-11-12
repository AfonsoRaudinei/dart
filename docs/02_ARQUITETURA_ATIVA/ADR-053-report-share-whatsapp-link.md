# ADR-053 — Link público de relatório + WhatsApp

**Data:** 05/11/2026  
**Status:** APROVADO  
**Módulos:** `consultoria/relatorios/`, `core/html_templates/`, `core/utils/`

## Contexto

Consultores precisam enviar relatório HTML ao produtor via WhatsApp (padrão TBDC):
um toque publica o documento e abre o WhatsApp com o link. O produtor abre no
browser mobile, sem instalar o app. Export nativo (share HTML/PDF no viewer)
permanece inalterado.

## Decisão

1. **Storage** — bucket Supabase `report-shares` (flag `public: true` para GET
   anônimo em `/object/public/...`; **sem** policy SELECT anônima em
   `storage.objects`, evitando `list()` no bucket). Objetos em
   `{auth.uid()}/{token}.html`; escrita/leitura via API autenticada só na pasta
   do usuário.
2. **Metadados** — tabela `report_share_links` (token único, título, paths, kind).
   RLS: usuário autenticado CRUD apenas nas próprias linhas. Anon não lê a tabela;
   segurança do link = URL pública do objeto + token imprevisível (UUID v4).
3. **App** — `ReportShareLinkService.publishHtml` exige sessão JWT + online;
   HTML recebe viewport mobile e rodapé na página pública com botão **Gerar PDF** que
   chama `window.print()`; o utilizador gera o ficheiro no diálogo do sistema (Safari/Chrome
   → “Salvar em PDF” / “PDF”). A barra é ocultada em `@media print`.
4. **UX** — `HtmlReportViewer`: botão “Enviar link (WhatsApp)” chama publish +
   `launchWhatsAppShare`. Telefone do cliente (IClientLookup) opcional nos fluxos
   ocorrência e relatório de visita.

## Consequências

- Migration `20261105220000_report_share_links.sql` deve ser aplicada no projeto live.
- Demais entry points do viewer podem omitir telefone (`wa.me/?text=`).
- PDF server-side (render headless, fila) fica fora do MVP; o fluxo no browser cobre o caso do produtor.

## Revisão — 12/11/2026

O botão do `HtmlReportViewer` deixou de publicar o link. O ícone (antes o balão **Enviar link (WhatsApp)**) agora é **Enviar PDF**: gera o PDF no aparelho a partir do HTML do relatório e abre o compartilhamento do arquivo. Não chama `publishHtml`.

O bucket `report-shares` entrega o HTML como texto puro, então o produtor via o código-fonte. O botão **Gerar PDF** (`window.print()`) injetado na página pública não aparecia.

A tabela `report_share_links` e o bucket permanecem. Links já enviados continuam no ar. `ReportShareLinkService` não foi removido.
