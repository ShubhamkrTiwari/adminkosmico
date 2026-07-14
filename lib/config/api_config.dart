class ApiConfig {
  // Configure your API base URL here
  // For development, use localhost or your server IP
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://3.7.180.215:5000',
  );
  
  static const int timeoutDuration = 30;
  
  // API Endpoints
  static const String auth = '/api/admin';
  static const String login = '$auth/login';
  static const String signup = '$auth/signup';
  static const String signupVerify = '$auth/signup-verify';
  static const String me = '$auth/me';
  
  static const String dashboard = '$auth/dashboard';
  static const String products = '$auth/products';
  static const String categories = '$auth/categories';
  static const String orders = '$auth/orders';
  static const String users = '$auth/users';
  static const String notifications = '$auth/notifications';
  static const String payments = '$auth/payments';
  static const String updates = '$auth/updates';
}
