# AUDITORIA PÓS-FREEZE V1.1 (READ-ONLY)

## Objetivo
Identificar riscos e pontos de atenção na versão V1.1 congelada, sem alterar código.

## Riscos Identificados

### 1. Configuração de Ambiente (BLOCKER)
- **Risco**: Chaves do Supabase ainda são placeholders no `main.dart`.
- **Impacto**: Sync falhará silenciosamente (ou com logs de erro) em produção se não configurado.
- **Mitigação**: Desenvolvedor deve substituir strings antes do build final.

### 2. Conflitos de Edição (MÉDIO)
- **Risco**: Edição simultânea da mesma ocorrência em dispositivos diferentes.
- **Impacto**: A versão "Local" sempre sobrescreve a remota se houver conflito de timestamp, o que é o comportamento esperado ("Local Wins"), mas pode confundir em casos de borda.
- **Mitigação**: Comportamento aceito por design.

### 3. Performance com Muitos Pins (BAIXO)
- **Risco**: Renderização de muitos pins de ocorrência no mapa.
- **Impacto**: Possível queda de FPS em dispositivos antigos com >500 ocorrências visíveis simultaneamente.
- **Mitigação**: Clustering já implementado (mas occurrence pins não usam clustering atualmente, apenas markers de publicações). Monitorar.

### 4. Tamanho do Payload (BAIXO)
- **Risco**: Sync inicial com muitas ocorrências.
- **Impacto**: Tempo de sync inicial pode ser longo em conexões 3G.
- **Mitigação**: Paginação futura (fora do escopo V1.1).

## Potenciais Regressões
- **Navegação**: O uso de `showModalBottomSheet` deve ser testado em telas pequenas para garantir que o teclado não cubra os botões de ação (embora seja `isScrollControlled: true`).
- **Permissões**: O novo fluxo depende estritamente do GPS estar `available`. Se o usuário negar permissão durante o uso, o sheet não abrirá (comportamento correto, mas restritivo).

## Conclusão
A versão V1.1 está estável arquiteturalmente. O único **BLOCKER** para deploy real é a substituição das credenciais de produção no `main.dart`.
