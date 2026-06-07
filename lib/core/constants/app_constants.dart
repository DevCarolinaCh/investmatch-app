// Constantes globales de la aplicación InvestMatch

class AppConstants {
  // API
  static const String baseUrl = 'https://api.investmatch.ar/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Almacenamiento seguro - claves
  static const String kAccessToken = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId = 'user_id';
  static const String kUserRole = 'user_role';

  // Roles de usuario (RBAC)
  static const String roleInvestor = 'investor';
  static const String roleFounder = 'founder';
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';

  // Etapas del pipeline de inversión
  static const List<String> pipelineStages = [
    'Descubierto',
    'Contactado',
    'Evaluando',
    'Reunido',
    'Due Diligence',
    'Cerrado',
    'Rechazado',
  ];

  // Verticales / Industrias
  static const List<String> verticals = [
    'Fintech',
    'Agtech',
    'Edtech',
    'Healthtech',
    'Proptech',
    'E-commerce',
    'SaaS',
    'Cleantech',
    'Logística',
    'IA / Machine Learning',
    'Ciberseguridad',
    'Marketplace',
    'Otro',
  ];

  // Etapas de startup
  static const List<String> startupStages = [
    'Idea',
    'Pre-seed',
    'Seed',
    'Serie A',
    'Serie B',
    'Growth',
    'Consolidado',
  ];

  // Tickets de inversión (rangos en USD)
  static const List<String> ticketRanges = [
    'Hasta USD 10k',
    'USD 10k – 50k',
    'USD 50k – 200k',
    'USD 200k – 1M',
    'Más de USD 1M',
  ];

  // Provincias AR
  static const List<String> provinces = [
    'Buenos Aires (CABA)',
    'Buenos Aires (GBA)',
    'Buenos Aires (Interior)',
    'Córdoba',
    'Santa Fe',
    'Mendoza',
    'Tucumán',
    'Salta',
    'Entre Ríos',
    'Neuquén',
    'Chubut',
    'San Juan',
    'Corrientes',
    'Misiones',
    'Jujuy',
    'Formosa',
    'La Rioja',
    'Catamarca',
    'San Luis',
    'La Pampa',
    'Río Negro',
    'Santa Cruz',
    'Tierra del Fuego',
    'Chaco',
    'Santiago del Estero',
  ];

  // Impacto
  static const List<String> impactCategories = [
    'Sin foco de impacto',
    'Impacto social',
    'Impacto ambiental',
    'Sostenibilidad',
    'Inclusión financiera',
    'Educación',
    'Salud',
    'Empleo',
  ];

  // Planes de suscripción
  static const String planFree = 'free';
  static const String planPro = 'pro';
  static const String planEnterprise = 'enterprise';

  // KYC estados
  static const String kycPending = 'pending';
  static const String kycInProgress = 'in_progress';
  static const String kycVerified = 'verified';
  static const String kycRejected = 'rejected';

  // Paginación
  static const int pageSize = 20;

  // Límites
  static const int maxProjectImages = 5;
  static const int maxPitchFileSizeMb = 50;
  static const int maxMessageLength = 2000;

  // WebSocket events
  static const String wsEventMessage = 'message';
  static const String wsEventTyping = 'typing';
  static const String wsEventRead = 'read';
  static const String wsEventMatch = 'match';
  static const String wsEventNotification = 'notification';
}
