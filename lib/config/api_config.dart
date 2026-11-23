class ApiConfig {
  // Configure your API base URL here
  // For development, use localhost or your server IP
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.kosmicowellness.com/api',
  );
  
  static const int timeoutDuration = 30;
  
  // API Endpoints
  static const String login = '/login';
  static const String signup = '/signup';
  static const String signupVerify = '/signup-verify';
  static const String me = '/me';
  
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String orders = '/orders';
  static const String users = '/users';
  static const String notifications = '/notifications';
  static const String payments = '/payments';
  static const String updates = '/updates';
  static const String leads = '/admin/leads';
  static const String subscriptions = '/subscriptions';
  static const String subscriptionsAdmin = '/admin/subscriptions';
  static const String whatsapp = '/admin/whatsapp';
  static const String whatsappSend = '$whatsapp/send';
  static const String whatsappTemplates = '$whatsapp/templates';
}
