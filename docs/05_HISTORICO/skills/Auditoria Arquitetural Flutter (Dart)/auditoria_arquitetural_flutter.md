# 🧠 Skill — Auditoria Arquitetural Flutter (Dart) — SoloForte

## 🎯 Objetivo

Garantir que qualquer alteração no projeto SoloForte:

- Respeite a arquitetura modular
- Mantenha separação correta de responsabilidades
- Preserve integridade de estado (Riverpod / Provider)
- Não viole padrões técnicos definidos
- Não degrade estrutura ao longo do tempo

Esta skill é exclusivamente analítica.
Ela NÃO implementa código.
Ela NÃO executa refatorações.
Ela apenas audita e aponta inconsistências.

---

## 🏗️ Padrão Arquitetural Oficial

O projeto SoloForte é:

- 100% Flutter (Dart)
- Mobile-first
- Modular
- Sem AppBar fixa
- Sem rotas paralelas
- Com separação clara de responsabilidades

Estrutura esperada por módulo:

module/
  ├── domain/
  ├── data/
  ├── presentation/
  └── widgets/ (se necessário, locais ao módulo)

---

## 🔎 Quando Ativar

Ativar quando o prompt envolver:

- criação de feature
- implementação de tela
- alteração estrutural
- modificação de estado
- reorganização de código
- criação de provider
- mudança de entidade/model
- ajustes arquiteturais

---

## 📋 Etapas de Auditoria

### 1️⃣ Separação de Camadas

Verificar:

- Domain contém apenas entidades e regras de negócio
- Data contém apenas models, datasources e repositórios
- Presentation contém widgets e controllers
- Nenhuma lógica de UI dentro do domain
- Nenhuma regra de negócio dentro do widget

Se misturar responsabilidades → VIOLAÇÃO ARQUITETURAL.

---

### 2️⃣ Integridade de Estado (Riverpod / Provider)

Validar:

- Providers locais permanecem locais ao módulo
- Nenhum provider global criado sem justificativa explícita
- Nenhuma mutação direta fora do fluxo correto
- Nenhum uso de estado estático global

Se houver vazamento de estado → VIOLAÇÃO DE ESTADO.

---

### 3️⃣ Contratos Técnicos

Validar:

- Entities são puras (sem dependência de Flutter)
- Models não substituem Entities
- Não há duplicação de estrutura
- Tipos são explícitos e consistentes
- Nenhuma dependência circular entre camadas

---

### 4️⃣ Regras Absolutas do SoloForte

- NÃO adicionar AppBar
- NÃO criar rota fora da lista oficial
- NÃO mover arquivos entre módulos sem autorização
- NÃO duplicar arquivos
- NÃO converter lógica mobile-first para web-first
- NÃO alterar navegação global

Se qualquer item acima for violado → MARCAR COMO CRÍTICO.

---

### 5️⃣ Análise de Efeito Colateral

Responder obrigatoriamente:

- Estado global foi alterado?
- Algum módulo externo foi impactado?
- Alguma dependência cruzada foi criada?
- Alguma responsabilidade foi misturada?

---

## 📦 Formato de Resposta Obrigatório

AUDITORIA ARQUITETURAL — SOLOFORTE

Módulo analisado:
Arquivos envolvidos:

Resultado:
✔ Arquitetura preservada
ou
🚨 Violação arquitetural detectada

Detalhamento técnico:

Categoria da violação:
- Camadas
- Estado
- Contrato
- Regra Absoluta

Checklist Final:
Estado global alterado?
Dependência cruzada criada?
Camadas misturadas?
Regra absoluta violada?

---

## 🚫 Restrições Absolutas

Esta skill:

- NÃO cria código
- NÃO sugere refatoração automática
- NÃO executa mudanças
- NÃO altera estrutura
- NÃO extrapola escopo

Se houver ambiguidade → solicitar confirmação antes de prosseguir.

---

## 🧩 Objetivo Estratégico

Esta skill existe para:

- Impedir degradação arquitetural
- Preservar padrão Flutter (Dart) profissional
- Manter o projeto auditável
- Evitar acoplamento indevido
- Sustentar crescimento sustentável do SoloForte
