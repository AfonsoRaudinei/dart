/// Define os níveis de navegação do SmartButton.
///
/// - [l0]: Mapa (raiz) — ícone ☰, abre SideMenu
/// - [l1]: Módulos raiz — ícone ←, pop se houver pilha; senão /map
/// - [l2Plus]: Subtelas — ícone ←, pop; senão [parentFallbackRoute]
/// - [public]: Rotas públicas — CTA "Acessar SoloForte"
enum RouteLevel { l0, l1, l2Plus, public }

class AppRoutes {
  // Públicas
  static const String publicMap = '/public-map';
  static const String login = '/login';
  static const String register = '/register';
  static const String recoverPassword = '/recover-password';
  static const String resetPassword = '/reset-password';

  // ════════════════════════════════════════════════════════════════════
  // DECISÃO ARQUITETURAL: MAP-FIRST (09/02/2026)
  // /map substitui definitivamente /dashboard como namespace central
  // ════════════════════════════════════════════════════════════════════

  // Privadas — L0 (Mapa = raiz absoluta e centro do app)
  static const String map = '/map';

  // Privadas — L1 (Módulos raiz que voltam direto para o mapa)
  static const String settings = '/settings';
  static const String settingsEditProfile = '/settings/profile/edit';
  static const String agenda = '/agenda';
  static const String feedback = '/feedback';
  static const String carteira = '/carteira';
  static const String reports = '/consultoria/relatorios';
  static const String clients = '/consultoria/clientes';
  static const String producerProperty = '/produtor/propriedade';
  static const String producerCalendar = '/produtor/calendario';

  // Módulo marketing/ — story de case (L1, retorno ao mapa)
  static const String marketingStory = '/marketing/story';

  // Módulo planos/ — ADR-012
  static const String planos = '/planos';
  static const String meuPlano = '/planos/meu-plano';

  // Privadas — L2+ (Níveis Profundos que usam pop)
  /// Deprecated: create de relatório é Map-First via `IReportWriter` (não registrar rota).
  static const String reportNew = '/consultoria/relatorios/novo';
  static String reportDetail(String id) => '/consultoria/relatorios/$id';

  static const String clientNew = '/consultoria/clientes/novo';
  static String clientDetail(String id) => '/consultoria/clientes/$id';

  static String farmDetail(String clientId, String farmId) =>
      '/consultoria/clientes/$clientId/fazendas/$farmId';

  static String fieldDetail(String clientId, String farmId, String fieldId) =>
      '/consultoria/clientes/$clientId/fazendas/$farmId/talhoes/$fieldId';

  // Planos L2+ — ADR-012
  static const String planosPagamento = '/planos/pagamento';
  static const String planosConfirmacao = '/planos/confirmacao';
  static const String planosIndicacoes = '/planos/indicacoes';
  static String carteiraCliente(String clienteId) =>
      '/carteira/cliente/$clienteId';

  static String carteiraOportunidades(String clienteId) =>
      '/carteira/oportunidades/$clienteId';

  // Agenda L2+ — navegação declarativa (Fase 7, sem context.pop)
  static String agendaDay(DateTime date) =>
      '$agenda/day?date=${date.toIso8601String()}';

  static String agendaEvent(String eventId) => '$agenda/event/$eventId';

  // ════════════════════════════════════════════════════════════════════
  // CLASSIFICAÇÃO DETERMINÍSTICA DE NÍVEL DE ROTA
  // ════════════════════════════════════════════════════════════════════

  /// Set de rotas públicas (não autenticadas)
  static const Set<String> publicRoutes = {
    publicMap,
    login,
    register,
    recoverPassword,
    resetPassword,
    '/', // Landing page redirect
  };

  /// Set de rotas L1 (módulos raiz que voltam direto para o mapa)
  /// Matching EXATO por path, sem contains() ou heurísticas
  static const Set<String> level1Routes = {
    settings,
    agenda,
    feedback,
    carteira,
    reports,
    clients,
    producerProperty,
    producerCalendar,
    marketingStory,
    planos, // ADR-012
    meuPlano, // ADR-012
  };

  /// Classifica o nível de uma rota de forma DETERMINÍSTICA.
  ///
  /// Regras de classificação (em ordem de prioridade):
  /// 1. Se está em [publicRoutes] → [RouteLevel.public]
  /// 2. Se é exatamente [map] ou inicia com '/map/' → [RouteLevel.l0]

  /// 4. Se está em [level1Routes] (match exato) → [RouteLevel.l1]
  /// 5. Qualquer outra rota autenticada → [RouteLevel.l2Plus]
  static RouteLevel getLevel(String path) {
    // 1. Rotas públicas
    if (publicRoutes.contains(path)) {
      return RouteLevel.public;
    }

    // 2. L0 = Map (mapa) - NAMESPACE CANÔNICO
    if (path == map || path.startsWith('$map/')) {
      return RouteLevel.l0;
    }

    // 4. L1 = Módulos raiz (match exato)
    if (level1Routes.contains(path)) {
      return RouteLevel.l1;
    }

    // 5. L2+ = Qualquer outra rota autenticada (subtelas)
    return RouteLevel.l2Plus;
  }

  /// Retorna true se a rota atual permite abrir o SideMenu.
  /// SideMenu SOMENTE disponível no L0 (Mapa).
  static bool canOpenSideMenu(String path) {
    return getLevel(path) == RouteLevel.l0;
  }

  /// Path sem query (SmartButton e fallback de pilha).
  static String pathOnly(String uriPathOrFull) {
    final q = uriPathOrFull.indexOf('?');
    return q < 0 ? uriPathOrFull : uriPathOrFull.substring(0, q);
  }

  /// Rota pai quando [GoRouter] não tem pilha (deep link / `go` legado).
  /// Usado só no SmartButton (REGRA-NAV-1).
  static String parentFallbackRoute(String uriPath) {
    final p = pathOnly(uriPath);

    if (p.startsWith('$carteira/cliente/') ||
        p.startsWith('$carteira/oportunidades/')) {
      return carteira;
    }

    if (p == '$agenda/day' || p.startsWith('$agenda/event/')) {
      return agenda;
    }

    if (p == clientNew) {
      return clients;
    }

    final clientDetailMatch = RegExp(r'^/consultoria/clientes/([^/]+)$');
    final clientMatch = clientDetailMatch.firstMatch(p);
    if (clientMatch != null) {
      return clients;
    }

    final farmMatch = RegExp(
      r'^/consultoria/clientes/([^/]+)/fazendas/([^/]+)$',
    ).firstMatch(p);
    if (farmMatch != null) {
      return clientDetail(farmMatch.group(1)!);
    }

    final fieldMatch = RegExp(
      r'^/consultoria/clientes/([^/]+)/fazendas/([^/]+)/talhoes/([^/]+)$',
    ).firstMatch(p);
    if (fieldMatch != null) {
      return farmDetail(fieldMatch.group(1)!, fieldMatch.group(2)!);
    }

    final reportEditMatch = RegExp(
      r'^/consultoria/relatorios/([^/]+)/edit$',
    ).firstMatch(p);
    if (reportEditMatch != null) {
      return reportDetail(reportEditMatch.group(1)!);
    }

    final reportDetailMatch = RegExp(r'^/consultoria/relatorios/([^/]+)$');
    if (reportDetailMatch.hasMatch(p)) {
      return reports;
    }

    if (p == settingsEditProfile) {
      return settings;
    }

    if (p == planosPagamento ||
        p == planosConfirmacao ||
        p == planosIndicacoes) {
      return meuPlano;
    }

    if (p == '/publicacoes/edit') {
      return map;
    }

    return map;
  }
}
