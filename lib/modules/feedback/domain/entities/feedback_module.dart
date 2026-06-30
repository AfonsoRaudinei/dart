enum FeedbackModule {
  agenda,
  map,
  visits,
  consulting,
  drawing,
  weather,
  wallet,
  marketing,
  plans,
  settingsLogin,
  other;

  String get label {
    switch (this) {
      case FeedbackModule.agenda:
        return 'Agenda';
      case FeedbackModule.map:
        return 'Mapa';
      case FeedbackModule.visits:
        return 'Visitas';
      case FeedbackModule.consulting:
        return 'Consultoria';
      case FeedbackModule.drawing:
        return 'Desenho/Talhões';
      case FeedbackModule.weather:
        return 'Clima';
      case FeedbackModule.wallet:
        return 'Carteira';
      case FeedbackModule.marketing:
        return 'Marketing';
      case FeedbackModule.plans:
        return 'Planos';
      case FeedbackModule.settingsLogin:
        return 'Configurações/Login';
      case FeedbackModule.other:
        return 'Outro';
    }
  }

  String get shortLabel {
    switch (this) {
      case FeedbackModule.settingsLogin:
        return 'Config.';
      case FeedbackModule.drawing:
        return 'Talhões';
      default:
        return label;
    }
  }

  String get storageValue {
    switch (this) {
      case FeedbackModule.settingsLogin:
        return 'settings_login';
      default:
        return name;
    }
  }

  static FeedbackModule fromStorageValue(String? value) {
    switch (value) {
      case 'agenda':
        return FeedbackModule.agenda;
      case 'map':
        return FeedbackModule.map;
      case 'visits':
        return FeedbackModule.visits;
      case 'consulting':
        return FeedbackModule.consulting;
      case 'drawing':
        return FeedbackModule.drawing;
      case 'weather':
        return FeedbackModule.weather;
      case 'wallet':
        return FeedbackModule.wallet;
      case 'marketing':
        return FeedbackModule.marketing;
      case 'plans':
        return FeedbackModule.plans;
      case 'settings_login':
        return FeedbackModule.settingsLogin;
      default:
        return FeedbackModule.other;
    }
  }
}
