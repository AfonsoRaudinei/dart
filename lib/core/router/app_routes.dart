class AppRoutes {
  // Públicas
  static const String publicMap = '/public-map';
  static const String login = '/login';
  static const String signup = '/signup';

  // Privadas — Raiz
  static const String dashboard = '/dashboard';

  // Privadas — Nível 1
  static const String settings = '/settings';
  static const String agenda = '/agenda';
  static const String feedback = '/feedback';
  static const String reports = '/consultoria/relatorios';
  static const String clients = '/consultoria/clientes';

  // Privadas — Níveis Profundos
  static const String reportNew = '/consultoria/relatorios/novo';
  static String reportDetail(String id) => '/consultoria/relatorios/$id';

  static const String clientNew = '/consultoria/clientes/novo';
  static String clientDetail(String id) => '/consultoria/clientes/$id';

  static String farmDetail(String clientId, String farmId) =>
      '/consultoria/clientes/$clientId/fazendas/$farmId';

  static String fieldDetail(String clientId, String farmId, String fieldId) =>
      '/consultoria/clientes/$clientId/fazendas/$farmId/talhoes/$fieldId';
}
